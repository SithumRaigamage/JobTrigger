# Phase 2 — Auth & Tool Selection

Goal: a user can sign up, log in, stay logged in across restarts, and reach
the (static) tool-selection grid.

- [x] P2-01 `data/models/auth/user_dto.dart`, `domain/auth/user.dart`
      (per `docs/data-models.md`). Deviated from the doc's literal
      `UserDto` snippet: added `@JsonKey(name: '_id')` on `id` — confirmed
      against `JobTrigger-Backend/controllers/authController.js`, which
      actually responds `{ token, user: { _id, email } }`. `UserDto`
      doesn't carry `token` (the docs' sample did) since the real response
      envelope nests it as a sibling of `user`, not inside it — added
      `AuthResponseDto { token, user }` for that envelope, used only inside
      `AuthRepositoryImpl`.
- [x] P2-02 `AuthRepository` interface + `AuthRepositoryImpl` — signup,
      login, calling `/api/auth/signup` and `/api/auth/login`. Returns
      `Result<AuthSession, AppFailure>` where `AuthSession` is a
      `({User user, String token})` record.
- [x] P2-03 `authNotifierProvider` (`AsyncNotifier<AuthState>`) — holds
      `unauthenticated | authenticated(User)`; on login/signup success,
      stores JWT via `secure_storage_service`, stores cached user.
      Followed `docs/state-management.md` literally: `AuthNotifier` itself
      doesn't call the repository — `setSession(user, token)` is called by
      `LoginNotifier`/`SignupNotifier` after a successful repository call.
      Cached user stored as JSON in `shared_preferences` (not secure
      storage — it's not sensitive; only the JWT needs secure storage per
      CLAUDE.md §7).
- [x] P2-04 On app start, `authNotifierProvider` attempts to rehydrate
      session from secure storage (no network call needed unless validating
      token freshness is desired — decide and document the choice here).
      **Decision, documented in `auth_notifier.dart`**: no network call.
      Matches the old app's `AuthenticationManager.init()` exactly — a
      stored token's presence is treated as "logged in"; an actually-expired
      token surfaces naturally on the first authenticated request as a 401,
      which Phase 1's `buildBackendDio` interceptor already clears.
- [x] P2-05 `LoginScreen` + `LoginNotifier` — email/password form, validation
      matching the original regex/length rules, loading + error states.
      Validation ported 1:1 from `LoginViewModel.swift` (non-empty fields,
      email contains `@` and `.`). Errors surface as a toast, matching the
      original's `NotificationManager` usage, not inline field text.
- [x] P2-06 `SignupScreen` + `SignupNotifier` — same shape as login.
      Validation ported from `SignupViewModel.swift` (email format, 6-char
      password minimum — matches the backend's own server-side check in
      `authController.js` — and confirm-password match). Simplified from
      the original: submit-time validation + toast only, not the original's
      live per-keystroke inline field underlining (that's an enhancement,
      not core functionality — flagged here rather than silently dropped).
- [x] P2-07 Wire `app_router.dart` redirect: unauthenticated → `/login`,
      authenticated hitting `/login` → tool selection / home. Implemented
      with a `refreshListenable` (`ChangeNotifier` driven by
      `ref.listen(authNotifierProvider, ...)`) so `redirect` re-runs on auth
      changes without recreating the `GoRouter` instance. While rehydration
      (P2-04) is still loading, `redirect` returns `null` (no redirect)
      rather than bouncing to `/login` and back once resolved.
- [x] P2-08 `ToolSelectionScreen` — static grid of `CiToolCard`s (Jenkins
      enabled, GitHub Actions/GitLab/SonarQube/CircleCI shown but disabled —
      do not build real integrations for these, see `tasks/backlog.md`).
      Ported from `ToolSelectionView.swift`/`CITool.swift`. The old app's
      logo image assets never existed (confirmed in Phase 0 P0-08), so this
      only ports the fallback-icon + accent-color rendering path, which is
      what actually rendered in the original.
- [x] P2-09 Logout action (clear secure storage + reset `authNotifierProvider`
      to `unauthenticated`, router redirect follows automatically).
      `AuthNotifier.logout()`; router redirect confirmed to follow via the
      same `refreshListenable` wiring as P2-07. No dedicated logout button
      wired into UI yet — that's Profile (P6-01), which doesn't exist until
      Phase 6.
- [x] P2-10 Unit tests: `AuthRepositoryImpl` against mocked Dio responses
      (success, invalid credentials, network error); `AuthNotifier` state
      transitions. 8 new tests (4 repository, 4 notifier — including a
      cross-container rehydration test), all passing alongside the existing
      Phase 1 suite (23 total). `flutter analyze` and `dart format
      --set-exit-if-changed` both clean.
- [x] P2-11 Manual test: kill and relaunch app while logged in → lands on
      home, not login. **Could not run on a real simulator/device** — tried
      creating and booting an iOS simulator, but `xcodebuild
      -showdestinations` reports no eligible destinations for the `Runner`
      scheme in this environment (references an uninstalled iOS 26.5
      platform), which looks like a local Xcode/toolchain configuration
      issue unrelated to the app code. Substituted the strongest available
      alternative: a `flutter test` widget test
      (`test/widget_test.dart`) that pumps the real `MyApp` through
      `ProviderScope` → `MaterialApp.router` → the actual redirect logic →
      `LoginScreen`, with secure storage/shared_preferences mocked empty,
      and asserts the login UI renders. This exercises the real
      rehydration → redirect → render path end-to-end, but is not a
      substitute for an actual device relaunch test — flagging this
      explicitly rather than claiming it's done. Someone with a working
      local iOS toolchain should run the real manual test before this box
      is fully trusted.

      **Retried during Phase 6 wrap-up, made real progress, still
      blocked**: real iOS 26.2/26.4 simulator runtimes are now installed
      (they weren't before), so created and booted a real "JobTrigger Test"
      simulator (`xcrun simctl create`/`boot`) and wrote a two-step
      `integration_test/` pair — step 1 signs up a fresh user through the
      real `SignupScreen` UI against the real local backend and confirms
      landing on `ToolSelectionScreen`; step 2 pumps a brand-new `MyApp`
      process on the same device (a fresh process reusing whatever the
      simulator's real Keychain/shared_preferences already persisted is
      the closest available equivalent to "kill and relaunch," since a
      single Dart test process can't literally kill and restart itself as
      a new OS process). Both were `flutter analyze`-clean. Still couldn't
      run either: `xcodebuild -showdestinations` for the `Runner` scheme
      still only ever reports the "Any iOS Device" physical placeholder
      (needing iOS 26.5) and never lists the booted simulator as a
      destination at all, eligible or not — confirmed this isn't a stale
      cache (restarted `CoreSimulatorService`, re-booted, retried) and
      isn't a project misconfiguration (`IPHONEOS_DEPLOYMENT_TARGET` is
      17.0, unrelated to this). Root cause: Xcode itself is version 26.5
      and only ships/has the iOS 26.5 SDK (`xcodebuild -showsdks`
      confirms), but only 26.2/26.4 *simulator runtimes* are installed —
      a genuine Xcode-version-vs-installed-platform gap, fixable only by
      downloading the iOS 26.5 platform via Xcode's Settings > Components
      (a multi-GB download requiring interactive/Apple ID setup, not
      something to trigger unilaterally from an agent session) or by
      someone running it through Xcode's GUI directly. Deleted the temp
      integration_test files and the `integration_test` dev dependency
      afterward (per the manual-test convention — nothing left half-used
      in the tree) rather than leave an unexercised harness around; the
      two test files' content is preserved here in case someone wants to
      recreate them once a matching platform is installed. A real physical
      iPhone was also detected (wirelessly, "Sithum's iPhone") but refused
      the connection — needs a cable or same-network + Developer Mode
      enabled on the device, neither of which could be arranged from this
      session.
