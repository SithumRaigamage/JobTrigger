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
- [x] P19-03 History screen stayed on its loading spinner. Riverpod's
      default retry made a failed Jenkins fetch read as "loading" for
      minutes. The job tree and the three history providers now opt out
      (`@Riverpod(retry: noRetry)`), so the error and its Retry button show
      at once. Other screens may be masked the same way (see P19-05).
- [x] P19-04 Profile → Change password: verified, no code change. The
      current password is already required by the dialog, by
      `AuthNotifier.changePassword` (empty is rejected) and by the backend
      (`reauthenticate`). The real question raised was "what if I forget
      it?", which is US-AUTH-08 (reset by email). That stays in
      `backlog.md`: it needs an email provider and backend work, both
      owner decisions.
- [x] P19-05 Home → Build queue / Nodes spun forever while Jenkins was
      offline. Their refresh timer (5s / 10s) started before the fetch, so
      it restarted any request slower than that (an unreachable server
      takes the 15s connect timeout) before it could fail; Riverpod's
      retry hid the error too. Now the timer starts after a successful
      fetch and both providers use `noRetry`. Follow-up, not done: 
      `stage_steps_notifiers.dart` (`_refreshWhileLive`, 2s) has the same
      timer-before-fetch shape.
- [x] P19-06 The three-dots "Open Jenkins link" asked for a pasted URL.
      It now opens the active server's page (or the folder being browsed)
      in the browser at once. The paste dialog is gone; the `jobtrigger://`
      deep link and `OpenLinkScreen` stay.
- [x] P19-07 The server chip on Home jumped to Settings. It now drops down
      the saved servers: pick one to switch in place (a check marks the
      active one, a note flags a server whose secret needs re-entering),
      or "Manage servers…" to reach Settings.
