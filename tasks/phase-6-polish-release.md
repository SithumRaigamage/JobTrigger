# Phase 6 — Polish & Release

Goal: parity-checklist complete, both platforms feel native, store-ready.
Some items can start as soon as their underlying feature lands in an
earlier phase — don't wait for Phase 5 to fully close to begin these.

- [x] P6-01 Profile screen — user info, logout, app version footer. Ported
      from `ProfileView.swift`. Only `id`/`email` exist anywhere in the
      domain/DTO layer (`User`, `UserDto`) — no username/avatar/roles — so
      the header shows email only, matching what data actually exists.
      Skips the old app's "Change Password"/"Security Settings" rows: both
      were unimplemented "coming soon" placeholders in the Swift app with
      no backend route to back them (confirmed no password-change endpoint
      in `lab-trigger-backend`), so there's no real feature to preserve.
      Added `package_info_plus` (new dependency, documented in
      `CLAUDE.md §3`) for the real installed version/build number in the
      footer. Added a Profile `IconButton` entry point on Home/Settings/
      Global History AppBars (small glue, matching the Phase 5 precedent
      for History/Settings icons — no bottom tab bar exists yet to place it
      in permanently; see the `main_scaffold.dart` gap flagged in
      `tasks/backlog.md`).
- [x] P6-02 App info screen — version/build number, links to privacy
      policy/terms/licenses, support email, wired to `AppInfoNotifier` /
      `GET /api/appinfo`. Ported from `AppInfoView.swift`, including its
      `openURL` link-opening behavior (added `url_launcher`, documented in
      `CLAUDE.md §3`). Full data layer built (`AppInfoDto`, domain
      `AppInfo`, `AppInfoRepository`/`Impl`, `AppInfoNotifier`) — none of it
      existed before. Verified live against the real local backend
      (`lab-trigger-backend` + local `mongod`, temp test file, deleted
      after use): confirmed the real 404 shape when no `AppInfo` doc exists
      (`{message: 'App information not found'}`, correctly surfaced as
      `NotFoundFailure`), then ran the backend's own `scripts/seedAppInfo.js`
      and confirmed the real 200 JSON shape parses into `AppInfo` correctly
      end-to-end, with no `Authorization` header sent (confirms `/appinfo`'s
      already-existing public-path exemption in `backend_api_client.dart`
      actually works, not just declared). Left the seeded doc in place —
      it's the backend's own intended dev fixture, not throwaway test data.
      Both live-verified shapes also captured as permanent mocked-adapter
      tests in `app_info_repository_impl_test.dart`.
- [x] P6-03 Theme parity pass — confirm light/dark palettes match the
      original `AppTheme` values closely enough that returning users don't
      feel a regression. Checked the old app's actual theme code
      (`Shared/Navigation/AppTheme.swift` + `Assets.xcassets`): there is no
      bespoke brand color palette to match — it only ever used plain
      SwiftUI system colors (`.blue`, `.primary`, system backgrounds) with
      an empty/unset `AccentColor`. `app_theme.dart`'s Material 3
      light/dark themes already satisfy "no regression" by construction —
      nothing to port. The real gap was the missing System/Light/Dark
      picker UI: `ThemeNotifier` (built in Phase 1) had no consumer
      anywhere. Added an "Appearance" section to `SettingsScreen` with a
      `SegmentedButton<ThemeMode>`, matching the old `SettingsView.swift`'s
      segmented picker exactly. Added `theme_notifier_test.dart` (3 tests —
      default/persist/rehydrate), which didn't exist before despite the
      notifier being built in Phase 1. Flagged the old app's separate
      "Backend Server Status" section (a live connectivity health-check) to
      `tasks/backlog.md` instead of building it — no phase task names it.
- [x] P6-04 Haptic feedback on build trigger/cancel (`HapticFeedback`),
      matching original tactile cues. The old app used
      `UINotificationFeedbackGenerator().notificationOccurred(.success/.error)`
      at 4 sites (`HomeViewModel.swift:97/107`,
      `JobDetailViewModel.swift:147/203/242/252` — trigger and cancel, both
      success and failure). Flutter has no direct equivalent of iOS's
      notification-style success/error haptic pair, so `mediumImpact()`/
      `heavyImpact()` stand in as a distinguishable pair. Added to both
      `TriggerBuildNotifier` and `CancelBuildNotifier` (both already fire
      on every real trigger/cancel path, so this covers all 4 original
      sites without a separate "home quick-trigger" haptic — that swipe
      action itself was never ported, flagged in `home_screen.dart`'s
      existing doc comment, not new scope here).
- [x] P6-05 Accessibility pass: font scaling, screen-reader labels on icon
      buttons and status indicators, sufficient contrast on status colors.
      Font scaling: confirmed no `textScaler`/`MediaQuery` override anywhere
      in `lib/` — the system text scale factor already propagates
      unmodified, nothing to fix. Icon buttons: audited every `IconButton(`
      call site in `lib/` for a `tooltip` (Flutter's `IconButton` surfaces
      `tooltip` as its accessible name via the wrapping `Tooltip`'s
      semantics) — found and fixed the two missing ones:
      `toast_view.dart`'s dismiss "×" and `signup_screen.dart`'s back
      chevron. All others already had one. Status indicators: `AppColors`
      had no notion of a screen-reader-facing description for the Jenkins
      "ball color" — added `describeJobColor()` (mirrors `forJobColor()`'s
      mapping: Success/Failed/Unstable/Disabled/Not built/Aborted/Unknown
      status, plus a ", building" suffix for `_anime` colors) and wired it
      into `StatusIndicator` via a `Semantics(label:)` wrapper. 3 new tests
      in `status_indicator_test.dart` (didn't exist before). Contrast:
      status colors are Material's standard red/green/orange/grey
      (`AppColors.buildSuccess/Failure/Unstable/Aborted`), reviewed by eye
      against both light/dark surface colors — no automated WCAG
      contrast-ratio audit tool is set up in this project, so this is a
      visual review, not a certified pass; flagging that distinction
      rather than overclaiming.
- [x] P6-06 Android-specific review: back-gesture behavior matches
      breadcrumb/folder navigation expectations; platform-appropriate
      widgets where Material vs Cupertino defaults would feel foreign.
      Widgets: confirmed zero Cupertino imports anywhere in `lib/` — Material
      3 throughout (`app_theme.dart`), so nothing would look foreign on
      Android; nothing to change. Back gesture: found a real gap. Folder
      drill-down (`FolderBreadcrumbNotifier`) is in-place widget state on
      `HomeScreen`, not a `go_router` push per folder — same approach the
      old app used (`HomeViewModel.navigateInto` on one `NavigationStack`
      entry), so no regression *there*. But unlike iOS's edge-swipe,
      Android's system back button/gesture is a harder OS-level expectation
      that Flutter's `Navigator` handles automatically — without
      intervention it would've popped `HomeScreen`'s whole route while
      browsing a nested folder, instead of walking up one level first
      (standard Android UX, e.g. file browsers). Wrapped `HomeScreen` in a
      `PopScope` (`canPop: breadcrumb.isEmpty`) that calls
      `navigateBack()` and blocks the pop while inside a folder, letting
      it through normally at the root. 2 new widget tests in
      `home_screen_test.dart` exercise the real `Navigator`/`PopScope`
      interaction (not just calling the notifier directly) — verified
      `NavigatorState.maybePop()` is actually intercepted mid-folder and
      passes through at the root. No Android SDK, `adb`, or emulator is
      installed in this environment at all (confirmed directly, not just
      assumed — same limitation as P5-13/P6-05's contrast note), so this
      is a code-level + widget-test verification of the interception
      logic, not an on-device gesture test.
- [ ] P6-07 App icons, splash screens, store screenshots for both platforms.
      Note from P0-08 (Phase 0): the old SwiftUI app never shipped real
      icon/logo artwork — `Assets.xcassets/AppIcon.appiconset` and
      `jenkins-logo.imageset` are both empty `Contents.json` slots with no
      PNGs ever added, so there was nothing to port. `job_trigger/`
      currently ships Flutter's default template icon/splash. This task
      needs real source artwork supplied (not generated by an agent) before
      it can close. Re-checked while working through the rest of Phase 6:
      still nothing in `Lab-Trigger-frontend/` or `job_trigger/`, and
      neither `flutter_launcher_icons` nor `flutter_native_splash` is a
      dependency yet. Still blocked on the same thing — real artwork.
- [ ] P6-08 Crash reporting / analytics hook (decide tool, out of original
      scope but reasonable to add before public release — confirm with the
      team before implementing, don't assume). Asked the user directly
      (per the task's own "confirm with the team" instruction, treated as
      a genuine blocker rather than something to guess) — chose to skip
      for now rather than pick Firebase Crashlytics or Sentry. Left
      unchecked and moved to `tasks/backlog.md`; no SDK added, no new
      dependency.
- [x] P6-09 Full regression pass against `docs/migration-strategy.md`'s
      feature parity checklist, both platforms. Audited all 13 parity
      checklist rows against actual code (not assumed from task-file
      checkmarks) — every feature exists, is wired to real repositories,
      and has passing tests; checked them off in
      `docs/migration-strategy.md §3`. **Honestly scoped, not fully
      closed**: this is a code-completeness pass, not the dual-platform
      on-device regression pass §4/§5 of that doc actually specify — no
      physical iOS/Android device is available in this environment (same
      gap as P5-13, P6-05, P6-06). Also flagged: every phase's live-Jenkins
      verification used one local Jenkins instance, not the "two
      differently-configured servers" §4 calls for. Both left as explicit,
      named gaps in `docs/migration-strategy.md` rather than silently
      treated as done — real device + a second Jenkins server needed before
      P6-11 (TestFlight/Play internal testing).
- [x] P6-10 Cold-start, backgrounding, and token-expiry (401 mid-session)
      flows explicitly tested.
      **Cold-start**: already covered by `auth_notifier_test.dart`'s "a
      fresh container rehydrates Authenticated state from a prior session"
      test (a fresh `ProviderContainer` is exactly cold-start) plus its "no
      session stored" case — both re-confirmed passing.
      **Token-expiry (401 mid-session) — found and fixed a real bug**:
      writing the test exposed that nothing ever caused
      `authNotifierProvider` to notice a 401 had cleared its session out
      from under it — `backend_api_client.dart`'s own doc comment even
      claimed the notifier "picks up on its next rebuild," but nothing
      ever triggered that rebuild. In the real app this would leave the UI
      stuck showing the authenticated screen (stale `Authenticated` state)
      until a full app restart, since `authNotifierProvider` is a
      keepAlive-listened provider (via `app_router.dart`'s
      `_AuthRefreshListenable`) that, once built, never rebuilds on its
      own. Fixed with a small dependency-respecting bridge: added
      `core/network/session_signal.dart` (`SessionSignal`, no import of
      anything in `presentation/` — keeps `core` from reaching upward
      through the architecture per `docs/architecture.md`), wired
      `buildBackendDio`'s 401 branch to call it via a new
      `onUnauthorized` callback param, and `AuthNotifier.build()` now
      `ref.listen`s it to call `logout()`. New
      `test/presentation/features/auth/session_expiry_test.dart` (2
      tests) wires the *real* `dioBackendProvider` + `authNotifierProvider`
      together through one container and fires a real 401 through it —
      deliberately not just testing each half in isolation (which is
      exactly how the gap went unnoticed: both existing unit tests already
      passed on their own). Full suite: 83 tests passing.
      **Backgrounding**: no `WidgetsBindingObserver`/`AppLifecycleState`
      handling exists anywhere in the app, and none was added — nothing
      currently depends on foreground/background transitions (polling
      `Timer`s simply stop ticking while the OS suspends the isolate and
      resume on their own once foregrounded; no crash or stale-data bug was
      found or demonstrated). Real OS-level suspension behavior (memory
      pressure, timer coalescing, actual backgrounding duration limits)
      still needs a physical device to observe — flagged, not invented a
      fix for a bug that hasn't been shown to exist.
- [ ] P6-11 Internal TestFlight + Play internal testing track release.
      **Cannot be done by an agent** — requires an Apple Developer account
      + App Store Connect access + code-signing certificates, and a Google
      Play Console account + signing key, none of which exist in this
      environment or can be created on the user's behalf. Also blocked on
      P6-07 (real app icon/splash artwork — stores reject default Flutter
      template icons) and P6-08's now-skipped crash reporting decision
      being revisited. Left unchecked for the user to action.
- [ ] P6-12 Dogfood window, track crash-free rate and any Jenkins-server
      edge cases surfaced by real usage. **Cannot be done by an agent** —
      needs real users on real devices over a real time window (this task
      list explicitly deferred crash reporting via P6-08, so there's
      currently no crash-free-rate signal to track even once dogfooding
      starts — worth revisiting that decision before this begins). Left
      unchecked.
- [ ] P6-13 Public release; keep SwiftUI app archived (not delisted) for a
      rollback window per `docs/migration-strategy.md §5`. **Cannot be
      done by an agent** — App Store / Play Store submission is a
      real-world, hard-to-reverse action affecting a shared/public system;
      requires the user's explicit action and store-account access. Left
      unchecked, blocked on P6-11/P6-12 above.
