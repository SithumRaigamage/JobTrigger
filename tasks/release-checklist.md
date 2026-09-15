# Release checklist (dev-complete, blocked on external/ops action)

These are **not** scope-cuts — unlike `backlog.md` (deliberately excluded
product surface), everything here is fully specified and, where code is
involved, already implemented. Each item is blocked on something outside
what development in this environment can resolve: a real device, real
artwork, store accounts, real users, or a real production action. Phase 2
and Phase 6 are marked `done` in `tasks/README.md` despite these being open,
because "done" there means dev-complete, not "in production." Full
investigation detail for each item lives at its source task id — this file
only tracks what's left and why.

- [ ] Real device kill-and-relaunch verification (source: `phase-2-auth-tool-selection.md`
      P2-11). Widget-test substitute exists and passes; no working iOS
      simulator destination or connected physical device was available in
      this environment to run the real manual test. Needs someone with a
      working local iOS toolchain (or the iOS 26.5 simulator platform
      installed via Xcode) to confirm.
- [ ] Android on-device build-log jank/performance test (source:
      `phase-5-build-execution-logs-history.md` P5-13). A 5,000-line log
      fixture confirms `ListView.builder` actually virtualizes (well under
      200 live widgets, not 5,000) and doesn't throw/hang — evidence the
      mechanism is sound, not a substitute for real on-device scroll
      measurement. No Android device/emulator was available in this
      environment.
- [ ] App icons, splash screens, store screenshots for both platforms
      (source: `phase-6-polish-release.md` P6-07). The original SwiftUI app
      never shipped real artwork to port from. Needs real source artwork
      supplied by the team — not agent-generated — before store submission
      can proceed.
- [ ] Internal TestFlight + Play internal testing track release (source:
      `phase-6-polish-release.md` P6-11). Needs an Apple Developer account
      + App Store Connect access + code-signing certificates, and a Google
      Play Console account + signing key. Also blocked on the icon/splash
      item above, and on revisiting the crash-reporting decision
      (`backlog.md`) before real users are involved.
- [ ] Dogfood window — track crash-free rate and Jenkins-server edge cases
      from real usage (source: `phase-6-polish-release.md` P6-12). Needs
      real users on real devices over a real time window; currently no
      crash-free-rate signal exists since crash reporting was deliberately
      skipped (see `backlog.md`) — worth revisiting before this starts.
- [ ] Public release; keep the SwiftUI app archived (not delisted) for a
      rollback window per `docs/migration-strategy.md §5` (source:
      `phase-6-polish-release.md` P6-13). App Store / Play Store
      submission — a real-world, hard-to-reverse action on a shared/public
      system. Requires your explicit action and store-account access.
      Blocked on the items above.
