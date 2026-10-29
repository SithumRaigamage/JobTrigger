# Phase 19 — Bug fixes and improvements (epic FIX)

Bugs and improvements found while testing on a real iPhone (2026-10-29).
Each is planned, approved and committed one at a time.

- [x] P19-01 **"Remember me" ignored on restart.** The session was kept
      after every login, ticked or not. Now ticked keeps it across an app
      restart and unticked ends it with the app (login screen, empty form).
- [x] P19-02 Home screen showed "no Jenkins server" on first open, until a
      tab switch. Home now shows a spinner while the saved servers load, an
      error with Retry if they fail, and "no server" only when there are
      none. (The "offline" banner is the US-JX-20 cache, not a bug: Jenkins
      was unreachable from the phone.)
- [ ] P19-03 History screen stays on its loading spinner.
- [ ] P19-04 Profile → Change password: confirm the current password is
      required (the notifier already requires it; check the screen).
- [ ] P19-05 Home screen: the two buttons show a loading spinner while
      Jenkins is offline.
- [ ] P19-06 The "three dots" menu should open the selected server's URL,
      but it asks to paste one.
- [ ] P19-07 The server drop-down at the top of Home navigates to Settings
      instead of switching the active server.
