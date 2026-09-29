#!/usr/bin/env bash
# Fixture Jenkins for JobTrigger's real-server verification (P11-01).
#
#   ./fixture.sh up      build + start, wait until ready, seed builds
#   ./fixture.sh seed    (re)queue the seed builds and multibranch scan
#   ./fixture.sh creds   print URL, users and API tokens
#   ./fixture.sh test    run the Flutter `fixture`-tagged tests against it
#   ./fixture.sh down    stop (keeps data)
#   ./fixture.sh reset   stop and delete all data and generated credentials
set -euo pipefail

cd "$(dirname "$0")"
CREDS_FILE=".fixture-credentials" # git-ignored
URL="http://localhost:8090"

load_creds() {
  if [[ ! -f "$CREDS_FILE" ]]; then
    umask 077
    {
      echo "FIXTURE_URL=$URL"
      echo "FIXTURE_ADMIN_PASSWORD=$(openssl rand -hex 16)"
      echo "FIXTURE_VIEWER_PASSWORD=$(openssl rand -hex 16)"
    } > "$CREDS_FILE"
  fi
  set -a
  # shellcheck disable=SC1090
  source "$CREDS_FILE"
  set +a
}

wait_ready() {
  echo -n "Waiting for Jenkins"
  for _ in $(seq 1 90); do
    # "fully up" in the log, not just /login answering: Jenkins serves the
    # login page while still initializing, and anything queued before init
    # completes is discarded.
    if docker logs jobtrigger-jenkins-fixture 2>&1 | grep -q 'Jenkins is fully up and running' &&
      [[ "$(curl -s -o /dev/null -w '%{http_code}' "$URL/login")" == "200" ]] &&
      docker exec jobtrigger-jenkins-fixture test -f /var/jenkins_home/fixture-tokens.properties; then
      echo " ready."
      return 0
    fi
    echo -n "."
    sleep 3
  done
  echo " timed out. Logs: docker logs jobtrigger-jenkins-fixture" >&2
  exit 1
}

store_tokens() {
  local tokens
  tokens="$(docker exec jobtrigger-jenkins-fixture cat /var/jenkins_home/fixture-tokens.properties)"
  grep -v '^FIXTURE_.*_TOKEN=' "$CREDS_FILE" > "$CREDS_FILE.tmp" || true
  {
    echo "FIXTURE_ADMIN_TOKEN=$(grep '^admin=' <<< "$tokens" | cut -d= -f2-)"
    echo "FIXTURE_VIEWER_TOKEN=$(grep '^viewer=' <<< "$tokens" | cut -d= -f2-)"
  } >> "$CREDS_FILE.tmp"
  mv "$CREDS_FILE.tmp" "$CREDS_FILE"
  chmod 600 "$CREDS_FILE"
  load_creds
}

post() { curl -sf -o /dev/null -u "admin:$FIXTURE_ADMIN_TOKEN" -X POST "$URL/$1"; }

seed_builds() {
  echo "Scanning multibranch project and seeding builds..."
  post "job/sample-multibranch/build?delay=0"
  for job in freestyle-simple pipeline-stages junit-report artifacts upstream-freestyle upstream-pipeline; do
    post "job/$job/build"
  done
  post "job/params-all/buildWithParameters?BRANCH=seeded"
}

case "${1:-}" in
  up)
    load_creds
    docker compose up --build -d
    wait_ready
    store_tokens
    seed_builds
    "$0" creds
    ;;
  seed)
    load_creds
    seed_builds
    ;;
  creds)
    load_creds
    echo "URL:    $FIXTURE_URL  (Jenkins' own configured URL is http://jenkins.internal:8080/ on purpose)"
    echo "admin:  token ${FIXTURE_ADMIN_TOKEN:-<not generated yet>}"
    echo "viewer: token ${FIXTURE_VIEWER_TOKEN:-<not generated yet>}  (read-only)"
    echo "Passwords are in tools/jenkins-fixture/$CREDS_FILE (git-ignored)."
    ;;
  test)
    load_creds
    cd ../../JobTrigger-Frontend
    flutter test --tags fixture --run-skipped "${@:2}"
    ;;
  down)
    load_creds
    docker compose down
    ;;
  reset)
    load_creds
    docker compose down -v
    rm -f "$CREDS_FILE"
    ;;
  *)
    sed -n '2,10p' "$0"
    exit 1
    ;;
esac
