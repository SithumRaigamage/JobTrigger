#!/usr/bin/env bash
# Runs the app on a physical iPhone against the backend on this Mac
# (Phase 18; full guide: IPHONE.md).
#
#   scripts/run-on-iphone.sh                 # detect everything, then run
#   scripts/run-on-iphone.sh --config-only   # only write config/device.json
#
# On the phone, 127.0.0.1 is the phone itself, so the app needs this Mac's
# Wi-Fi address. The script finds it, writes the git-ignored
# JobTrigger-Frontend/config/device.json, checks the backend answers on
# that address, picks the connected iPhone and runs `flutter run`.
#
# Override any guess with an environment variable:
#   BACKEND_HOST=192.168.1.50   the Mac's address (default: Wi-Fi IP)
#   BACKEND_PORT=5001           the backend's port
#   DEVICE="Sithum's iPhone"    the iPhone's name or id (`flutter devices`)
#   MODE=debug                  debug instead of profile (profile keeps
#                               working after you unplug the cable)
#   SKIP_BACKEND_CHECK=1        don't check the backend first
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
APP="$REPO/JobTrigger-Frontend"
CONFIG="$APP/config/device.json"

fail() {
  echo "✗ $1" >&2
  exit 1
}

# 1. This Mac's address on the network the iPhone uses.
host="${BACKEND_HOST:-}"
if [ -z "$host" ]; then
  for interface in en0 en1; do
    host="$(ipconfig getifaddr "$interface" 2>/dev/null || true)"
    [ -n "$host" ] && break
  done
fi
[ -n "$host" ] || fail "No Wi-Fi address found. Join the iPhone's Wi-Fi, or set BACKEND_HOST=<this Mac's IP>."
port="${BACKEND_PORT:-5001}"
backend="http://$host:$port"

# 2. The build config. `release` builds refuse http (AUD-43), so this is
# only for debug and profile.
cat >"$CONFIG" <<EOF
{
  "ENVIRONMENT": "dev",
  "BACKEND_BASE_URL": "$backend"
}
EOF
echo "✓ config/device.json → $backend"
echo "  In the app, a Jenkins server on this Mac is http://$host:<its port>, never localhost."

[ "${1:-}" = "--config-only" ] && exit 0

# 3. The backend must answer on the network address, not just on localhost.
if [ "${SKIP_BACKEND_CHECK:-0}" != "1" ]; then
  if curl -fsS --max-time 3 "$backend/healthz" >/dev/null 2>&1; then
    echo "✓ Backend answers at $backend/healthz"
  else
    fail "The backend doesn't answer at $backend/healthz. Start it with ./setup-dev.sh in another terminal (or set SKIP_BACKEND_CHECK=1)."
  fi
fi

# 4. The iPhone: DEVICE, or the one physical iOS device that's connected.
device="${DEVICE:-}"
if [ -z "$device" ]; then
  phones="$(cd "$APP" && flutter devices --machine 2>/dev/null | python3 -c '
import json, sys
try:
    devices = json.load(sys.stdin)
except ValueError:
    devices = []
for d in devices:
    if d.get("targetPlatform") == "ios" and not d.get("emulator"):
        print(d["id"] + "\t" + d["name"])
')"
  count="$(printf '%s' "$phones" | grep -c . || true)"
  if [ "$count" = "1" ]; then
    device="$(printf '%s' "$phones" | cut -f1)"
    echo "✓ iPhone: $(printf '%s' "$phones" | cut -f2)"
  elif [ "$count" = "0" ]; then
    fail "No iPhone found. Connect it by cable, unlock it and tap Trust (see IPHONE.md, step 1)."
  else
    printf '%s\n' "$phones" | sed 's/^/    /'
    fail "More than one iPhone is connected. Pick one: DEVICE=<id or name> scripts/run-on-iphone.sh"
  fi
fi

mode="${MODE:-profile}"
case "$mode" in
  debug | profile) ;;
  *) fail "MODE must be debug or profile (release refuses an http backend, AUD-43)." ;;
esac

echo "▶ flutter run --$mode on the iPhone"
cd "$APP"
exec flutter run "--$mode" --dart-define-from-file=config/device.json -d "$device"
