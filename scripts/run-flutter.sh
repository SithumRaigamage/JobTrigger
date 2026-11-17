#!/usr/bin/env bash
# Run Flutter against the local development services on any supported target.
#
# Examples:
#   ./scripts/run-flutter.sh --target=ios-simulator
#   ./scripts/run-flutter.sh --target=android-emulator
#   ./scripts/run-flutter.sh --target=iphone
#   DEVICE_NETWORK=tailscale ./scripts/run-flutter.sh --target=android-device
#   JOBTRIGGER_ENV=prod ./scripts/run-flutter.sh --target=iphone --mode=release
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
APP="$REPO/JobTrigger-Frontend"
ROOT_CONFIG="$REPO/environment.conf"
CONFIG="$APP/config/device.json"

shell_environment="${JOBTRIGGER_ENV:-}"
shell_network="${DEVICE_NETWORK:-}"
if [ -f "$ROOT_CONFIG" ]; then
  # shellcheck disable=SC1090
  source "$ROOT_CONFIG"
fi

environment="${shell_environment:-${JOBTRIGGER_ENV:-dev}}"
network="${shell_network:-${DEVICE_NETWORK:-lan}}"
target="auto"
mode="${MODE:-debug}"
device="${DEVICE:-}"
backend_port="${BACKEND_PORT:-5001}"
website_port="${WEBSITE_PORT:-3000}"
backend_host="${BACKEND_HOST:-}"

for argument in "$@"; do
  case "$argument" in
    --target=*) target="${argument#*=}" ;;
    --mode=*) mode="${argument#*=}" ;;
    --device=*) device="${argument#*=}" ;;
    *) echo "Unknown argument: $argument" >&2; exit 2 ;;
  esac
done

fail() { echo "✗ $1" >&2; exit 1; }

case "$environment" in
  dev|prod) ;;
  *) fail "JOBTRIGGER_ENV must be dev or prod." ;;
esac
case "$network" in
  lan|tailscale) ;;
  *) fail "DEVICE_NETWORK must be lan or tailscale." ;;
esac
case "$mode" in
  debug|profile|release) ;;
  *) fail "MODE must be debug, profile, or release." ;;
esac

if [ "$environment" = "prod" ]; then
  [ "$mode" = "release" ] || fail "Production runs must use --mode=release."
  config_file="$APP/config/prod.json"
else
  config_file="$CONFIG"

  if [ -z "$backend_host" ]; then
    case "$target" in
      ios-simulator) backend_host="127.0.0.1" ;;
      android-emulator) backend_host="10.0.2.2" ;;
      iphone|android-device|auto)
        if [ "$network" = "tailscale" ]; then
          backend_host="$(tailscale ip -4 2>/dev/null || true)"
        else
          default_interface="$(route -n get default 2>/dev/null | awk '/interface:/ {print $2}' || true)"
          backend_host="$(ipconfig getifaddr "$default_interface" 2>/dev/null || true)"
          if [ -z "$backend_host" ]; then
            backend_host="$(ipconfig getifaddr en0 2>/dev/null || true)"
          fi
        fi
        [ -n "$backend_host" ] || fail "Could not detect the Mac address. Set BACKEND_HOST=<LAN or Tailscale address>."
        ;;
      *) fail "Unknown target: $target" ;;
    esac
  fi

  # P24-04: dev-only billing preview — static offers, no RevenueCat key
  # needed. Opt out with BILLING_PREVIEW=0. Never set in staging/prod.
  billing_preview_line=$',\n  "BILLING_PREVIEW": "true"'
  [ "${BILLING_PREVIEW:-1}" = "0" ] && billing_preview_line=""
  cat >"$config_file" <<EOF
{
  "ENVIRONMENT": "dev",
  "BACKEND_BASE_URL": "http://$backend_host:$backend_port",
  "WEBSITE_BASE_URL": "http://$backend_host:$website_port"$billing_preview_line
}
EOF
fi

if [ -z "$device" ] && [ "$target" != "auto" ]; then
  case "$target" in
    ios-simulator) device="$(cd "$APP" && flutter devices --machine | python3 -c 'import json,sys; print(next((d["id"] for d in json.load(sys.stdin) if d.get("targetPlatform") == "ios" and d.get("emulator")), ""))')" ;;
    android-emulator) device="$(cd "$APP" && flutter devices --machine | python3 -c 'import json,sys; print(next((d["id"] for d in json.load(sys.stdin) if d.get("targetPlatform") == "android" and d.get("emulator")), ""))')" ;;
    iphone) device="$(cd "$APP" && flutter devices --machine | python3 -c 'import json,sys; print(next((d["id"] for d in json.load(sys.stdin) if d.get("targetPlatform") == "ios" and not d.get("emulator")), ""))')" ;;
    android-device) device="$(cd "$APP" && flutter devices --machine | python3 -c 'import json,sys; print(next((d["id"] for d in json.load(sys.stdin) if d.get("targetPlatform") == "android" and not d.get("emulator")), ""))')" ;;
  esac
  [ -n "$device" ] || fail "No device found for target '$target'. Run 'flutter devices' and pass --device=<id>."
fi

if [ "$environment" = "dev" ]; then
  backend_url="http://$backend_host:$backend_port"
  curl -fsS --max-time 3 "$backend_url/healthz" >/dev/null \
    || fail "Backend is not reachable at $backend_url. Start it with ./setup-dev.sh."
  echo "✓ Development backend: $backend_url"
fi

echo "▶ flutter run --$mode ($environment${device:+, device $device})"
cd "$APP"
if [ -n "$device" ]; then
  exec flutter run "--$mode" --dart-define-from-file="$config_file" -d "$device"
else
  exec flutter run "--$mode" --dart-define-from-file="$config_file"
fi
