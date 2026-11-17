# M-01 — Kill-and-relaunch on the physical iPhone

> Draft task file split from `tasks/MANUAL.md`. Back to the [index](README.md). Each M-XX has one file here so it can be worked, ticked and archived independently.


**Source:** P2-11 (`tasks/phase-2-auth-tool-selection.md`).
**Done already:** the same check on the iOS simulator (2026-11-17,
`integration_test/relaunch.sh`): signed in, process ended, relaunched, landed
on the signed-in tool-selection screen, never login.
**Why only you:** the gate is a real iPhone — your device, on your Wi-Fi,
signed in to your account. The agent's environment only had simulators, and
CLAUDE.md §10 names you as the iPhone tester. Tried on the connected iPhone
2026-11-17: a throwaway backend was started and the build installed, but the
`flutter drive` session could not reach the Dart VM over wireless debugging —
macOS blocked mDNS on port 5353 with "Flutter could not access the local
network". Granting that permission is a macOS privacy setting only you can
approve.

1. Mac: allow the terminal/IDE under **System Settings → Privacy & Security →
   Local Network** (or connect the iPhone by USB for the drive test), then
   start the backend (`./setup-dev.sh`) and install the app with
   `scripts/run-on-iphone.sh` (a profile build; `IPHONE.md`).
2. Phone: sign in with **Remember my email** ticked — that switch is what keeps
   the session (P19-01).
3. Phone: force-quit the app (swipe it away in the app switcher), wait ~2 s,
   then reopen it from the Home screen.
4. Phone: confirm you land on the tool-selection screen or Home, **not** the
   login screen, and take a screenshot.

**Evidence to bring back:** that screenshot + "landed signed in".
