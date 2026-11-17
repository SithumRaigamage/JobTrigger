#!/usr/bin/env bash
# Scans this repo with your local SonarQube so the project shows up at
# http://localhost:9000 when the scan finishes.
#
#   scripts/sonar-scan.sh
#
# with SONAR_TOKEN (a SonarQube user token) either exported in your shell or
# as a `SONAR_TOKEN=...` line in the git-ignored .env at the repo root (or in
# JobTrigger-Backend/.env). Only that one line is read from the file; it is
# never sourced. Create the token once in SonarQube: avatar (top right) → My
# Account → Security → Generate Tokens → type "User Token". The script never
# stores or prints the token.
#
# What it does:
#   1. checks sonar-scanner is installed and SonarQube is up (starting the
#      stopped `sonarqube` / `sonarqube-db` containers if they exist);
#   2. checks the token works;
#   3. runs the scan with the repo's sonar-project.properties (sources,
#      exclusions, tests) but as the local project `JobTrigger`, leaving the
#      SonarCloud key/organization in that file alone;
#   4. waits until SonarQube has finished processing the report, then prints
#      the dashboard link and the quality gate result.
#
# Optional environment variables:
#   SONAR_HOST_URL=http://localhost:9000   the SonarQube to scan into
#   SONAR_PROJECT_KEY=JobTrigger           the project key it appears under
#                                          (case matters; a project-scoped
#                                          analysis token only works for its
#                                          own key)
#   SONAR_PROJECT_NAME=JobTrigger          the name shown in the list
#   WITH_COVERAGE=1                        run the backend tests with
#                                          coverage first, so the backend's
#                                          coverage shows up (needs the
#                                          backend's test setup to work)
#   WAIT_SECONDS=300                       how long to wait for processing
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
HOST="${SONAR_HOST_URL:-http://localhost:9000}"
HOST="${HOST%/}"
KEY="${SONAR_PROJECT_KEY:-JobTrigger}"
NAME="${SONAR_PROJECT_NAME:-JobTrigger}"
WAIT_SECONDS="${WAIT_SECONDS:-300}"

fail() {
  echo "✗ $1" >&2
  exit 1
}

step() { echo "→ $1"; }

# --- 1. Tools and server ----------------------------------------------------
command -v sonar-scanner >/dev/null 2>&1 ||
  fail "sonar-scanner is not installed. Install it with: brew install sonar-scanner"
command -v python3 >/dev/null 2>&1 || fail "python3 is needed to read SonarQube's replies."

status_of() {
  curl -fsS -m 5 "$HOST/api/system/status" 2>/dev/null |
    python3 -I -c 'import json,sys; print(json.load(sys.stdin).get("status",""))' 2>/dev/null ||
    true
}

if [ "$(status_of)" != "UP" ]; then
  # The server is down. If it is the local one and its containers exist
  # (just stopped), start them.
  case "$HOST" in
    http://localhost:* | http://127.0.0.1:*) local_server=1 ;;
    *) local_server=0 ;;
  esac
  if [ "$local_server" = 1 ] && command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    existing="$(docker ps -a --format '{{.Names}}' | grep -E '^(sonarqube-db|sonarqube)$' || true)"
    if [ -n "$existing" ]; then
      step "SonarQube is not answering at $HOST; starting its containers…"
      # Database first, then the server.
      for name in sonarqube-db sonarqube; do
        echo "$existing" | grep -qx "$name" && docker start "$name" >/dev/null
      done
    fi
  fi
  step "Waiting for SonarQube at $HOST (first start can take a minute or two)…"
  waited=0
  until [ "$(status_of)" = "UP" ]; do
    [ "$waited" -ge 180 ] &&
      fail "SonarQube is not up at $HOST. Start it, or set SONAR_HOST_URL to where it runs."
    sleep 5
    waited=$((waited + 5))
  done
fi
echo "✓ SonarQube is up at $HOST"

# --- 2. Token ---------------------------------------------------------------
# Prefer the environment. Otherwise take ONLY the SONAR_TOKEN line from a
# git-ignored .env (repo root first, then the backend's). The file is never
# sourced, so none of its other values (JWT secret, database URI…) reach the
# scanner or this script.
if [ -z "${SONAR_TOKEN:-}" ]; then
  for env_file in "$REPO/.env" "$REPO/JobTrigger-Backend/.env"; do
    [ -f "$env_file" ] || continue
    candidate="$(sed -n 's/^[[:space:]]*\(export[[:space:]]\{1,\}\)\{0,1\}SONAR_TOKEN=//p' "$env_file" | tail -n 1)"
    # Drop surrounding quotes and a trailing carriage return.
    candidate="${candidate%$'\r'}"
    candidate="${candidate#\"}"
    candidate="${candidate%\"}"
    candidate="${candidate#\'}"
    candidate="${candidate%\'}"
    if [ -n "$candidate" ]; then
      SONAR_TOKEN="$candidate"
      echo "✓ Using SONAR_TOKEN from ${env_file#"$REPO"/}"
      break
    fi
  done
fi
if [ -z "${SONAR_TOKEN:-}" ]; then
  cat >&2 <<MSG
✗ SONAR_TOKEN is not set.

Create a token in SonarQube (avatar → My Account → Security → Generate
Tokens, type "User Token"), then either add this line to .env in the repo
root (git-ignored):

  SONAR_TOKEN=<your token>

or export it for this shell:

  export SONAR_TOKEN=<your token>
  scripts/sonar-scan.sh
MSG
  exit 1
fi
export SONAR_TOKEN

valid="$(curl -fsS -m 10 -u "$SONAR_TOKEN:" "$HOST/api/authentication/validate" 2>/dev/null |
  python3 -I -c 'import json,sys; print(json.load(sys.stdin).get("valid"))' 2>/dev/null || true)"
[ "$valid" = "True" ] ||
  fail "SonarQube did not accept SONAR_TOKEN. Check it is a current user token for $HOST."
echo "✓ Token accepted"

# --- 3. Optional coverage ---------------------------------------------------
if [ "${WITH_COVERAGE:-}" = "1" ]; then
  step "Running backend tests with coverage…"
  (cd "$REPO/JobTrigger-Backend" && npm run test:coverage) ||
    fail "Backend tests failed, so there is no coverage report. Fix them, or run without WITH_COVERAGE."
fi

# --- 4. Scan ----------------------------------------------------------------
# Reuse sonar-project.properties for sources, exclusions and tests, minus its
# SonarCloud key and organization, so the two setups share one definition.
settings="$(mktemp -t jobtrigger-sonar)"
trap 'rm -f "$settings"' EXIT
grep -vE '^[[:space:]]*sonar\.(projectKey|organization)[[:space:]]*=' \
  "$REPO/sonar-project.properties" >"$settings"

rm -rf "$REPO/.scannerwork"
step "Scanning (project key: $KEY)…"
(
  cd "$REPO"
  sonar-scanner \
    -Dproject.settings="$settings" \
    -Dsonar.projectBaseDir="$REPO" \
    -Dsonar.host.url="$HOST" \
    -Dsonar.projectKey="$KEY" \
    -Dsonar.projectName="$NAME"
) || fail "The scan failed. If it says you are 'not authorized to analyze this project', the token's user cannot analyse or create the project '$KEY': a Project Analysis Token only works for its own project key, and a normal user needs the Create Projects / Execute Analysis permission. Try SONAR_PROJECT_KEY=<the key the token was made for>, or a User Token from an admin."

# --- 5. Wait for SonarQube to finish processing -----------------------------
task_file="$REPO/.scannerwork/report-task.txt"
[ -f "$task_file" ] || fail "The scan finished but left no report-task.txt, so I can't tell when processing ends."
task_id="$(sed -n 's/^ceTaskId=//p' "$task_file")"
[ -n "$task_id" ] || fail "report-task.txt has no ceTaskId."

step "Waiting for SonarQube to process the report…"
waited=0
while :; do
  task_status="$(curl -fsS -m 10 -u "$SONAR_TOKEN:" "$HOST/api/ce/task?id=$task_id" 2>/dev/null |
    python3 -I -c 'import json,sys; print(json.load(sys.stdin)["task"]["status"])' 2>/dev/null || true)"
  case "$task_status" in
    SUCCESS) break ;;
    FAILED | CANCELED) fail "SonarQube could not process the report (task $task_status). See $HOST/project/background_tasks?id=$KEY" ;;
  esac
  [ "$waited" -ge "$WAIT_SECONDS" ] &&
    fail "Still processing after ${WAIT_SECONDS}s. It may finish on its own: $HOST/dashboard?id=$KEY"
  sleep 3
  waited=$((waited + 3))
done

gate="$(curl -fsS -m 10 -u "$SONAR_TOKEN:" "$HOST/api/qualitygates/project_status?projectKey=$KEY" 2>/dev/null |
  python3 -I -c 'import json,sys; print(json.load(sys.stdin)["projectStatus"]["status"])' 2>/dev/null || true)"

echo
echo "✓ Done. The project is now in SonarQube:"
echo "  $HOST/dashboard?id=$KEY"
[ -n "$gate" ] && echo "  Quality gate: $gate"
