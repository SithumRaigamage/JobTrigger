#!/usr/bin/env bash
# P2-11: kill-and-relaunch on an iOS simulator. Signs in with "Remember my
# email" ticked (flutter drive --keep-app-running leaves the app installed),
# ends the app process, launches it again like a user would, and saves a
# screenshot: it must show tool selection or Home, never the login screen.
# (flutter test uninstalls the app between runs, which wipes the session.)
# Needs a backend with the account; see docs/integration-testing.md.
#   integration_test/relaunch.sh <simulator-udid> <email> <password>
set -euo pipefail
device="$1"; email="$2"; password="$3"
bundle=Sraig.Lab-Trigger-frontend
cd "$(dirname "$0")/.."
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/relaunch_login_test.dart -d "$device" \
  --keep-app-running --dart-define-from-file=config/dev.json \
  --dart-define=RELAUNCH_EMAIL="$email" --dart-define=RELAUNCH_PASSWORD="$password"
xcrun simctl terminate "$device" "$bundle"
sleep 2
xcrun simctl launch "$device" "$bundle"
sleep 8
xcrun simctl io "$device" screenshot relaunch.png
echo "Look at relaunch.png: signed-in screen = pass, login screen = fail."
