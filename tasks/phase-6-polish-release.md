# Phase 6 — Polish & Release

Goal: parity-checklist complete, both platforms feel native, store-ready.
Some items can start as soon as their underlying feature lands in an
earlier phase — don't wait for Phase 5 to fully close to begin these.

Dev-complete as of this phase. P6-07 (iOS screenshots) and P6-08 (crash
reporting) are done and verified (2026-11-17, below); the store accounts,
dogfood window and public release are owner steps, each listed with its
steps in `tasks/MANUAL.md`.

- [x] P6-01 Profile screen — user info, logout, app version footer. Ported
      from `ProfileView.swift`. Only `id`/`email` exist anywhere in the
      domain/DTO layer (`User`, `UserDto`) — no username/avatar/roles — so
      the header shows email only, matching what data actually exists.
      Skips the old app's "Change Password"/"Security Settings" rows: both
      were unimplemented "coming soon" placeholders in the Swift app with
      no backend route to back them (confirmed no password-change endpoint
      in `JobTrigger-Backend`), so there's no real feature to preserve.
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
      (`JobTrigger-Backend` + local `mongod`, temp test file, deleted
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
- [x] P6-07 App icons, splash screens, store screenshots for both platforms.
      **Icons and splash: done** in Phase 16 (real brand artwork, exported by
      `scripts/export-icons.sh`; the old note that only Flutter's default icon
      existed is stale). **iOS screenshots: done 2026-11-17**, taken from the
      iOS simulator (iPhone 18 Pro Max, 1320×2868) in demo mode by
      `integration_test/store_screenshots_test.dart`: seven shots for the
      three tools in release 1.0 — five Jenkins (jobs, folder, job, failing
      job, build log) plus GitHub Actions repositories and SonarQube projects
      — in `release/store-screenshots/ios-6.9/`, JPEG without alpha, with
      captions and the retake command in `docs/store-submission.md`. **Android
      screenshots: done 2026-11-17**, seven matching shots from the
      `Medium_Phone_API_37.0` emulator in demo mode, resized to 1080×2160
      (Google Play's 2:1 limit) and saved as JPEG without alpha in
      `release/store-screenshots/android-2by1/`; the iPhone image is too tall
      to reuse. The emulator needed the missing Android NDK (r28c) installed;
      the screenshot test is now cross-platform (one surface conversion at
      the start on Android, a no-op on iOS).
- [x] P6-08 Crash reporting. **Decided and built** (not skipped: the
      2026-11 note that it was moved to the backlog is stale): the app uses
      `sentry_flutter` against a self-hosted GlitchTip, errors only, every event
      scrubbed first (`docs/error-reporting.md`, `phase-emergency.md` E3).
      **Host and test crash verified 2026-11-17:** the lab's GlitchTip
      (`make up S="postgres mailpit glitchtip"`, port 3005, project
      `jobtrigger-app`) received the app's own "Send test crash report", sent
      from the iOS simulator by `integration_test/test_crash_test.dart`; the
      event reads `StateError: Bad state: Test crash report. token=[redacted]
      url=https://jenkins.example.com/job/x`. **Bug found and fixed on the way:**
      the scrubber's token rule redacted Sentry's 32-hex `event_id`, so the host
      rejected every event; ids are now preserved after the residue check (test
      added). Still MANUAL (owner): the iPhone path through the Mac's LAN
      address and putting the DSNs in the apps' `.env` files (M-07).
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
- [ ] P6-11 **MANUAL (owner):** Internal TestFlight + Play internal testing
      release. Prepared 2026-11-17: `docs/store-submission.md` (archive and
      upload commands, screenshots, captions, privacy answers, review notes);
      `flutter build ios --release --no-codesign --dart-define-from-file=
      config/prod.json` builds. Only the signed archive and the upload need the
      owner's Apple Developer and Play Console accounts: `tasks/MANUAL.md`
      (M-08, M-09).
- [ ] P6-12 **MANUAL (owner):** Dogfood window. Needs real users on real
      devices over a real time period. Crash reporting now exists (P6-08), so
      the crash-free rate can be read in GlitchTip: `tasks/MANUAL.md` (M-10).
- [ ] P6-13 **MANUAL (owner):** Public release; keep the SwiftUI app archived
      (not delisted) for a rollback window per `docs/migration-strategy.md §5`.
      A store submission is a hard-to-reverse public action: `tasks/MANUAL.md`
      (M-11), after P6-11 and P6-12.
- [x] P6-14 Persistent bottom tab bar — promoted from `tasks/backlog.md`'s
      long-deferred "Bottom tab bar shell" item. Home/History/Settings/
      Profile were reachable only via `IconButton`s duplicated across three
      different AppBars (`context.push`, so screens stacked instead of
      switching). Replaced with `go_router`'s `StatefulShellRoute
      .indexedStack` + a new `presentation/navigation/main_scaffold.dart`
      (`MainScaffold`, Material 3 `NavigationBar`) — matches
      `docs/architecture.md`'s mapping row from the old `NavBarView.swift`,
      never built until now. Deliberate structural upgrade beyond the
      SwiftUI original's 3-tab `TabView` (which didn't have Profile as a
      tab, only a push-based "person.circle" icon repeated per tab) —
      confirmed with the user rather than assumed. `jobDetail`/`buildLog`/
      `jobHistory`/`appInfo` stay flat top-level routes pinned to the root
      navigator (`parentNavigatorKey`), not nested under a branch — nesting
      under one branch would silently flip the active tab when pushed from
      a different one (e.g. `buildLog` is reachable from both Home and
      History). `HomeScreen`'s P6-06 breadcrumb `PopScope` verified to
      still work correctly nested inside the shell's Home branch navigator
      (new `test/presentation/navigation/app_router_test.dart`, against
      the real `appRouterProvider`), composing with `MainScaffold`'s own
      outer `PopScope` (non-Home tab → back returns to Home first). New
      `test/presentation/navigation/main_scaffold_test.dart` covers branch
      switching, `.indexedStack` state preservation across tab switches,
      and the active-tab-reset (`initialLocation: true`) behavior in
      isolation. Along the way, the full test-suite run surfaced a real bug
      in the earlier theme/login-screen pass: `LoginScreen`'s version
      footer fell back to the literal string `"JobTrigger"` while
      `packageInfoProvider` was loading/erroring (no platform channel in
      tests), duplicating the headline text and breaking
      `test/widget_test.dart` — changed to a blank fallback.
