#!/usr/bin/env bash
# Build a release with its crash-reporting and purchase keys injected at
# build time, without committing them.
#
# A release build needs three values that must never live in git:
#   SENTRY_DSN              where crash reports go (GlitchTip)
#   REVENUECAT_IOS_KEY      the App Store public SDK key
#   REVENUECAT_ANDROID_KEY  the Play public SDK key
#
# Supply them as environment variables or in the git-ignored files
# `JobTrigger-Frontend/config/sentry.json` and `config/billing.json`. This
# script merges `config/<env>.json`, those files and the environment (the
# environment wins) into one 0600 file in the system temp directory, passes
# it as a single `--dart-define-from-file`, and deletes it on exit.
#
# Usage: scripts/build-release.sh <ipa|appbundle|apk|all> [options]
#
# Tests: `node --test scripts/build-release.test.mjs`. They point
# JOBTRIGGER_APP_DIR at a fixture and FLUTTER at a fake binary so no real
# build runs.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="${JOBTRIGGER_APP_DIR:-$ROOT/JobTrigger-Frontend}"
FLUTTER_BIN="${FLUTTER:-flutter}"

usage() {
  cat <<'EOF'
Usage: scripts/build-release.sh <ipa|appbundle|apk|all> [options]

Builds from config/<env>.json plus the git-ignored secret files
config/sentry.json and config/billing.json (environment variables win over
the files), merged into one temporary --dart-define-from-file.

Options:
  --env=prod|staging   Config to merge (default: prod)
  --allow-missing      Build even if the DSN or a store key is missing.
                       For unsigned verification builds only; a store
                       build should never use this.
  --check              Validate the merged config, print which keys are
                       present, and exit without building.
  --dry-run            Print the build command without running it.
  --no-codesign        iOS only: build ipa without signing, for CI
                       verification.

Required for a store build:
  SENTRY_DSN, plus REVENUECAT_IOS_KEY for ipa / REVENUECAT_ANDROID_KEY for
  appbundle and apk. Provide them as environment variables, or as:
    config/sentry.json   {"SENTRY_DSN": "https://…"}
    config/billing.json  {"REVENUECAT_IOS_KEY": "appl_…",
                          "REVENUECAT_ANDROID_KEY": "goog_…"}
  Both files are git-ignored (JobTrigger-Frontend/.gitignore).
EOF
}

fail() {
  echo "✗ $*" >&2
  exit 1
}

target=""
env_name="prod"
allow_missing=0
check_only=0
dry_run=0
no_codesign=0

for arg in "$@"; do
  case "$arg" in
    ipa | appbundle | apk | all) target="$arg" ;;
    --env=*) env_name="${arg#--env=}" ;;
    --allow-missing) allow_missing=1 ;;
    --check) check_only=1 ;;
    --dry-run) dry_run=1 ;;
    --no-codesign) no_codesign=1 ;;
    -h | --help) usage; exit 0 ;;
    *) usage >&2; fail "Unknown argument: $arg" ;;
  esac
done

[ -n "$target" ] || { usage >&2; fail "Pick a target: ipa, appbundle, apk or all."; }
case "$env_name" in
  prod | staging) ;;
  *) fail "Environment must be prod or staging (release builds refuse dev)." ;;
esac
if [ "$no_codesign" = "1" ] && { [ "$target" = "apk" ] || [ "$target" = "appbundle" ]; }; then
  fail "--no-codesign is only for ipa (or all, for its iOS half)."
fi

base="$APP/config/$env_name.json"
[ -f "$base" ] || fail "Missing $base."

# Only these two optional files, never a .env file.
secret_files=()
[ -f "$APP/config/sentry.json" ] && secret_files+=("$APP/config/sentry.json")
[ -f "$APP/config/billing.json" ] && secret_files+=("$APP/config/billing.json")

umask 077
merged="$(mktemp "${TMPDIR:-/tmp}/jobtrigger-release-XXXXXX")"
trap 'rm -f "$merged"' EXIT

# Merge base <- secret files <- environment. Values stay out of argv, so
# they never show in `ps`; the output is 0600 and outside the repository.
python3 - "$base" ${secret_files[@]+"${secret_files[@]}"} >"$merged" <<'PY'
import json
import os
import sys

merged = {}
for path in sys.argv[1:]:
    with open(path, encoding="utf-8") as handle:
        merged.update(json.load(handle))

# SENTRY_DSN_APP is the name the iPhone launch script uses; accept it here
# too so one shell export works for both.
for name, alias in (
    ("SENTRY_DSN", "SENTRY_DSN_APP"),
    ("REVENUECAT_IOS_KEY", None),
    ("REVENUECAT_ANDROID_KEY", None),
):
    value = os.environ.get(name, "").strip()
    if not value and alias:
        value = os.environ.get(alias, "").strip()
    if value:
        merged[name] = value

json.dump(merged, sys.stdout, indent=2)
PY

required=(SENTRY_DSN)
case "$target" in
  ipa) required+=(REVENUECAT_IOS_KEY) ;;
  appbundle | apk) required+=(REVENUECAT_ANDROID_KEY) ;;
  all) required+=(REVENUECAT_IOS_KEY REVENUECAT_ANDROID_KEY) ;;
esac

# One read of the merged file: which keys are present, and which required
# ones are missing. Names only; values are never printed.
report="$(python3 - "$merged" "${required[@]}" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    merged = json.load(handle)

known = ("SENTRY_DSN", "REVENUECAT_IOS_KEY", "REVENUECAT_ANDROID_KEY")
present = [k for k in known if isinstance(merged.get(k), str) and merged[k].strip()]
missing = [k for k in sys.argv[2:] if k not in present]

# A store build must never point at the development lab: the same
# git-ignored sentry.json holds the lab GlitchTip DSN for iPhone runs, and a
# Bonjour (.local) or LAN address only works on the owner network.
import ipaddress
from urllib.parse import urlsplit

def dev_host(host):
    host = (host or "").lower().rstrip(".")
    if not host or host == "localhost" or host == "host.docker.internal":
        return True
    if host.endswith((".local", ".lan", ".home", ".internal", ".localhost")):
        return True
    try:
        ip = ipaddress.ip_address(host.strip("[]"))
    except ValueError:
        return "." not in host  # a bare machine name
    return ip.is_private or ip.is_loopback or ip.is_link_local

unsafe = []
for name in ("BACKEND_BASE_URL", "WEBSITE_BASE_URL", "SENTRY_DSN"):
    value = merged.get(name)
    if not isinstance(value, str) or not value.strip():
        continue
    parts = urlsplit(value.strip())
    if parts.scheme != "https" or dev_host(parts.hostname):
        unsafe.append(name)

# The shape of each secret that is present (names only, never values), so a
# template value or a key for the wrong store fails here, not in review.
import re

def malformed_value(name, value):
    if "replace" in value.lower():
        return True  # still the config/*.example.json placeholder
    if name == "SENTRY_DSN":
        parts = urlsplit(value)
        return not parts.username or not re.fullmatch(r"/\d+", parts.path or "")
    if name == "REVENUECAT_IOS_KEY":
        return not re.fullmatch(r"appl_[A-Za-z0-9_]{6,}", value)
    if name == "REVENUECAT_ANDROID_KEY":
        return not re.fullmatch(r"goog_[A-Za-z0-9_]{6,}", value)
    return False

malformed = [k for k in present if malformed_value(k, merged[k].strip())]

print(" ".join(present) or "-")
print(" ".join(missing) or "-")
print(" ".join(unsafe) or "-")
print(" ".join(malformed) or "-")
PY
)"
present="$(sed -n 1p <<<"$report")"
missing="$(sed -n 2p <<<"$report")"
unsafe="$(sed -n 3p <<<"$report")"
malformed="$(sed -n 4p <<<"$report")"

if [ "$unsafe" != "-" ]; then
  fail "Not a release address (must be https:// on a public host, not localhost, .local or a LAN IP): $unsafe. Check config/$env_name.json and config/sentry.json."
fi

if [ "$malformed" != "-" ]; then
  fail "Not a usable value: $malformed. SENTRY_DSN is https://<key>@<host>/<project id>; REVENUECAT_IOS_KEY starts appl_, REVENUECAT_ANDROID_KEY goog_; a value still containing REPLACE is the template (config/*.example.json)."
fi

echo "✓ config: $env_name ($(basename "$base"))"
if [ "$present" = "-" ]; then
  echo "  injected: nothing"
else
  echo "  injected: $present"
fi

if [ "$missing" != "-" ]; then
  message="Missing for release target '$target': $missing. Put them in config/sentry.json / config/billing.json or export them."
  if [ "$allow_missing" = "1" ]; then
    echo "! $message" >&2
    echo "  Continuing because --allow-missing was passed; this build reports no crashes and/or sells nothing." >&2
  else
    fail "$message"
  fi
fi

[ "$check_only" = "1" ] && exit 0

build_one() {
  local flutter_target="$1"
  local args=(build "$flutter_target" --release)
  if [ "$flutter_target" = "ipa" ] && [ "$no_codesign" = "1" ]; then
    args+=(--no-codesign)
  fi
  if [ "$dry_run" = "1" ]; then
    echo "▶ (dry run) $FLUTTER_BIN ${args[*]} --dart-define-from-file=<merged temp file>"
    return
  fi
  echo "▶ $FLUTTER_BIN ${args[*]}"
  (cd "$APP" && "$FLUTTER_BIN" "${args[@]}" \
    --dart-define-from-file="$merged")
}

case "$target" in
  all)
    build_one ipa
    build_one appbundle
    ;;
  *) build_one "$target" ;;
esac
