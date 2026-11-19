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
# Works on your home Wi-Fi and on the iPhone's Personal Hotspot (over
# Wi-Fi or the USB cable): the address comes from the network the Mac is
# using right now. Development only; release builds are unaffected.
#
#   BACKEND_HOST=192.168.1.50   the Mac's address (default: its Bonjour
#                               name, e.g. Sithums-MacBook-Pro.local)
#   USE_IP=1                    use the IP on the current network instead
#                               of the name
#   BACKEND_PORT=5001           the backend's port
#   DEVICE="Sithum's iPhone"    the iPhone's name or id (`flutter devices`)
#   MODE=debug                  debug instead of profile (profile keeps
#                               working after you unplug the cable)
#   MODE=install                build profile, install and launch without
#                               attaching Flutter tooling (most reliable;
#                               no "Lost connection to device")
#   DEVICE_NETWORK=tailscale    use the Mac's Tailscale IPv4 address
#   SKIP_BACKEND_CHECK=1        don't check the backend first
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
APP="$REPO/JobTrigger-Frontend"
CONFIG="$APP/config/device.json"

shell_environment="${JOBTRIGGER_ENV:-}"
shell_network="${DEVICE_NETWORK:-}"
if [ -f "$REPO/environment.conf" ]; then
  # shellcheck disable=SC1090
  source "$REPO/environment.conf"
fi
environment="${shell_environment:-${JOBTRIGGER_ENV:-dev}}"
device_network="${shell_network:-${DEVICE_NETWORK:-lan}}"

fail() {
  echo "✗ $1" >&2
  exit 1
}

[ "$environment" = "dev" ] || fail "run-on-iphone.sh is for development. Use run-flutter.sh for production builds."
case "$device_network" in
  lan|tailscale) ;;
  *) fail "DEVICE_NETWORK must be lan or tailscale." ;;
esac

# 1. This Mac's address on the network the iPhone uses: the interface that
# carries the default route (Wi-Fi, hotspot over Wi-Fi, or hotspot over
# USB, which isn't en0), then the Wi-Fi interfaces as a fallback.
host="${BACKEND_HOST:-}"
if [ -z "$host" ] && [ "$device_network" = "tailscale" ]; then
  host="$(tailscale ip -4 2>/dev/null || true)"
  [ -n "$host" ] || fail "Tailscale IPv4 was not found. Start Tailscale or set BACKEND_HOST=<Tailscale IPv4>."
fi
if [ -z "$host" ]; then
  candidates=""
  default_if="$(route -n get default 2>/dev/null | awk '/interface:/ {print $2}' || true)"
  # A VPN (utun/ipsec/ppp) owns the default route but isn't reachable from
  # the phone, so skip it.
  case "$default_if" in
    "" | utun* | ipsec* | ppp*) ;;
    *) candidates="$default_if" ;;
  esac
  for interface in $candidates en0 en1; do
    host="$(ipconfig getifaddr "$interface" 2>/dev/null || true)"
    [ -n "$host" ] && break
  done
fi
[ -n "$host" ] || fail "No network address found. Join your Wi-Fi or the iPhone's Personal Hotspot, or set BACKEND_HOST=<this Mac's IP>."

# The iPhone's Personal Hotspot always hands out 172.20.10.x.
case "$host" in
  172.20.10.*) network="iPhone Personal Hotspot"; on_hotspot=1 ;;
  100.*) network="Tailscale"; on_hotspot=0 ;;
  *) network="Wi-Fi / local network"; on_hotspot=0 ;;
esac
echo "✓ Network: $network ($host)"

# One name for both networks: the Mac's Bonjour name (System Settings →
# General → Sharing → Local hostname), e.g. Sithums-MacBook-Pro.local. The
# iPhone resolves it on your Wi-Fi and on its own hotspot, so one install and
# one saved Jenkins server work on both. USE_IP=1 (or BACKEND_HOST) uses the
# raw address instead.
by_name=0
if [ "$device_network" = "lan" ] && [ -z "${BACKEND_HOST:-}" ] && [ "${USE_IP:-0}" != "1" ]; then
  local_name="$(scutil --get LocalHostName 2>/dev/null || true)"
  if [ -n "$local_name" ]; then
    host="$local_name.local"
    by_name=1
    echo "✓ Using the Mac's name $host (works on Wi-Fi and the hotspot)"
  fi
fi
port="${BACKEND_PORT:-5001}"
backend="http://$host:$port"

# 2. The build config. `release` builds refuse http (AUD-43), so this is
# only for debug and profile.
# US-AUTH-08: "Forgot password?" opens the website (JobTrigger-Web,
# `npm run dev`) on this Mac. The phone reaches it at this Mac's address.
website="http://$host:${WEBSITE_PORT:-3000}"
# E3: crash reports go to GlitchTip only when you give this run a DSN, e.g.
#   SENTRY_DSN_APP=http://<key>@localhost:3005/<project> scripts/run-on-iphone.sh
# (never commit a DSN; device.json is git-ignored). Without it, reporting is off.
# The DSN's host is swapped for this run's address, so one DSN works on
# Wi-Fi and on the hotspot (GlitchTip runs on this Mac, port 3005).
sentry_line=""
if [ -n "${SENTRY_DSN_APP:-}" ]; then
  dsn="$(printf '%s' "$SENTRY_DSN_APP" | sed -E 's#^(https?://[^@/]+@)[^:/]+#\1'"$host"'#')"
  sentry_line=$',\n  "SENTRY_DSN": "'"$dsn"'"'
fi
# P20-20: real sandbox purchases. Supply the RevenueCat *public* iOS SDK key
# to use the real App Store sandbox instead of the static preview:
#   REVENUECAT_IOS_KEY=app_... scripts/run-on-iphone.sh
# A key turns preview mode off automatically (preview offers cannot be
# bought). Without a key the dev run shows the static preview UI.
revenuecat_ios_key="${REVENUECAT_IOS_KEY:-}"
revenuecat_line=""
if [ -n "$revenuecat_ios_key" ]; then
  revenuecat_line=$',\n  "REVENUECAT_IOS_KEY": "'"$revenuecat_ios_key"'"'
fi
# P24-04: dev-only billing preview — static offers, no RevenueCat key needed,
# so the Subscription screen and paywall render on this dev run. Opt out
# with BILLING_PREVIEW=0. A real key also opts out (see above). Never set in
# staging/prod.
billing_preview_line=$',\n  "BILLING_PREVIEW": "true"'
[ "${BILLING_PREVIEW:-1}" = "0" ] && billing_preview_line=""
[ -n "$revenuecat_ios_key" ] && billing_preview_line=""
# Development-only sandbox store: buy, cancel and resubscribe against the
# local backend without Apple, Google, RevenueCat or any payment. The
# backend also needs SANDBOX_BILLING=true and BILLING_ENABLED=true.
#   SANDBOX_BILLING=1 scripts/run-on-iphone.sh
sandbox_line=""
if [ "${SANDBOX_BILLING:-0}" = "1" ]; then
  sandbox_line=$',\n  "SANDBOX_BILLING": "true"'
  billing_preview_line=""
fi
# A real store key means real App Store sandbox purchases. The local
# simulator would bypass RevenueCat, so the key wins over SANDBOX_BILLING.
if [ -n "$revenuecat_ios_key" ]; then
  sandbox_line=""
fi
cat >"$CONFIG" <<EOF
{
  "ENVIRONMENT": "dev",
  "BACKEND_BASE_URL": "$backend",
  "WEBSITE_BASE_URL": "$website"$sentry_line$billing_preview_line$revenuecat_line$sandbox_line
}
EOF
echo "✓ config/device.json → $backend"
echo "✓ website (password reset) → $website"
echo "  In the app, a Jenkins server on this Mac is http://$host:<its port>, never localhost."
[ -n "$sentry_line" ] && echo "✓ crash reports → GlitchTip at $host:3005"
if [ -n "$sandbox_line" ]; then
  echo "✓ billing → local sandbox store (no payment, no RevenueCat)"
  echo "  the backend must run with BILLING_ENABLED=true SANDBOX_BILLING=true"
elif [ -n "$revenuecat_ios_key" ]; then
  echo "✓ billing → real App Store sandbox via RevenueCat (preview off)"
else
  echo "  billing → static preview (no purchases). For sandbox: REVENUECAT_IOS_KEY=<public key> scripts/run-on-iphone.sh"
fi
if [ "$by_name" = "0" ] && [ "$on_hotspot" = "1" ]; then
  echo "  Using a raw address: on the hotspot, switch the app to your \"(hotspot)\" Jenkins server (IPHONE.md, section 6.1)."
fi

[ "${1:-}" = "--config-only" ] && exit 0

# 3. The backend must answer on the network address, not just on localhost.
if [ "${SKIP_BACKEND_CHECK:-0}" != "1" ]; then
  if curl -fsS --max-time 3 "$backend/healthz" >/dev/null 2>&1; then
    echo "✓ Backend answers at $backend/healthz"
  else
    hint="Start it with ./setup-dev.sh in another terminal (or set SKIP_BACKEND_CHECK=1)."
    if [ "$on_hotspot" = "1" ]; then
      hint="$hint On the hotspot, the backend also needs MongoDB Atlas to accept mobile data's address (Network Access; IPHONE.md, section 6.1)."
    fi
    fail "The backend doesn't answer at $backend/healthz. $hint"
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

# iOS kills an app launch (SIGKILL) while the phone is locked. The build and
# wireless install take long enough to auto-lock, which then looks like a
# failure. Wait for the owner to unlock rather than failing the run.
wait_for_unlock() {
  command -v xcrun >/dev/null 2>&1 || return 0
  phone_locked() {
    xcrun devicectl device info lockState --device "$device" 2>/dev/null |
      grep -q 'passcodeRequired: true'
  }
  phone_locked || return 0
  echo "⏳ The iPhone is locked. Unlock it now and keep it awake"
  echo "   (Settings → Display & Brightness → Auto-Lock → Never)."
  echo "   Waiting up to 2 minutes for the unlock…"
  waited=0
  while phone_locked && [ "$waited" -lt 120 ]; do
    sleep 2
    waited=$((waited + 2))
  done
  if phone_locked; then
    fail "The iPhone is still locked. Unlock it, set Auto-Lock to Never, then run again. A locked phone makes iOS kill the launch."
  fi
  echo "✓ iPhone unlocked"
}

wait_for_unlock

# A second build sharing Xcode's build database is the usual cause of
# "accessing build database … disk I/O error".
if pgrep -f 'flutter_tools.snapshot run' >/dev/null 2>&1; then
  fail "Another 'flutter run' is still active. Press q there, then run again — two builds share Xcode's build.db."
fi

# SQLite's build database occasionally gets left in a state Xcode reports as
# a disk I/O error. Only its own cache is removed; a source error is left alone.
clear_xcode_build_db() {
  local dir db
  for dir in "$HOME"/Library/Developer/Xcode/DerivedData/Runner-*; do
    [ -d "$dir" ] || continue
    db="$dir/Build/Intermediates.noindex/XCBuildData/build.db"
    if [ -f "$db" ]; then rm -f "$db" "$db-wal" "$db-shm"; fi
  done
}

if command -v sqlite3 >/dev/null 2>&1; then
  for dir in "$HOME"/Library/Developer/Xcode/DerivedData/Runner-*; do
    [ -d "$dir" ] || continue
    db="$dir/Build/Intermediates.noindex/XCBuildData/build.db"
    [ -f "$db" ] || continue
    if ! sqlite3 "$db" 'PRAGMA quick_check;' 2>/dev/null | grep -qx 'ok'; then
      echo "✓ Repairing a corrupt Xcode build database"
      rm -f "$db" "$db-wal" "$db-shm"
    fi
  done
fi

mode="${MODE:-profile}"
case "$mode" in
  debug | profile | install) ;;
  *) fail "MODE must be debug, profile or install (release refuses an http backend, AUD-43)." ;;
esac

if [ "$mode" = "install" ]; then
  echo "▶ Building profile and installing on the iPhone (no debugger attached)"
  cd "$APP"
  build_log="$(mktemp)"
  if ! flutter build ios --profile \
      --dart-define-from-file=config/device.json 2>&1 | tee "$build_log"; then
    if grep -q 'accessing build database' "$build_log"; then
      echo "✓ Clearing Xcode's build database and retrying once"
      clear_xcode_build_db
      flutter build ios --profile \
        --dart-define-from-file=config/device.json ||
        fail "The profile build failed twice. See the output above."
    else
      rm -f "$build_log"
      fail "The profile build failed. See the output above."
    fi
  fi
  rm -f "$build_log"
  app_path="$APP/build/ios/iphoneos/Runner.app"
  [ -d "$app_path" ] || fail "The build produced no Runner.app at $app_path."
  wait_for_unlock   # The 1–2 minute build can let the phone auto-lock.
  xcrun devicectl device install app --device "$device" "$app_path" ||
    fail "Installing on the iPhone failed. Unlock it and try again."
  xcrun devicectl device process launch \
    --device "$device" Sraig.Lab-Trigger-frontend ||
    fail "The app installed but could not be launched. Unlock the iPhone and try again."
  echo "✓ JobTrigger launched. It keeps running without Flutter tooling."
  exit 0
fi

wait_for_unlock

echo "▶ flutter run --$mode on the iPhone"
cd "$APP"
exec flutter run "--$mode" --dart-define-from-file=config/device.json -d "$device"
