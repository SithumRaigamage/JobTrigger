# Phase 1 — Core Infrastructure

Goal: the plumbing every feature depends on exists and is unit-tested,
before any screen is built.

- [x] P1-01 `core/config/app_config.dart` — reads flavor/`--dart-define`
      values into a typed config object (backend base URL, environment name).
      Reads `ENVIRONMENT`/`BACKEND_BASE_URL` from `config/*.json` (Phase 0);
      exposes `appConfigProvider`.
- [x] P1-02 `core/storage/secure_storage_service.dart` — thin typed wrapper
      over `flutter_secure_storage` (`saveToken`, `readToken`, `clear`, etc.).
      Unit test with the package's in-memory test implementation. Tested in
      `test/core/storage/secure_storage_service_test.dart` via
      `FlutterSecureStorage.setMockInitialValues`.
- [x] P1-03 `core/network/backend_api_client.dart` — `Dio` instance +
      interceptor that attaches `Authorization: Bearer` from secure storage,
      and a response interceptor that clears session + signals logout on 401.
      Interceptor logic factored into a standalone `buildBackendDio()` (not
      just inlined in the provider) so it's unit-testable without a
      `ProviderContainer` — see `test/core/network/backend_api_client_test.dart`.
      The 401 handler clears the stored session; the actual redirect-on-logout
      *signal* is Phase 2's `authNotifierProvider` reacting to that, once it
      exists.
- [x] P1-04 `core/network/jenkins_client_factory.dart` — builds a `Dio`
      instance with Basic Auth for a given `Credential`; exposes
      `jenkinsClientProvider` that rebuilds when the active server changes
      (per `docs/state-management.md`). **Split in place**: only the
      reusable `buildJenkinsDio({baseUrl, username, password})` builder is
      done now. The reactive `jenkinsClientProvider` needs the `Credential`
      domain entity and `activeServerNotifierProvider`
      (`presentation/features/settings/`), both Phase 3 work per
      `tasks/phase-3-credentials-management.md` — inventing them here would
      preempt Phase 3's actual design of that entity/repository. Follow-up
      added to `tasks/phase-3-credentials-management.md`.
- [x] P1-05 Shared `AppFailure` sealed class + `Either`/`Result` choice
      (decide once, document the choice at the top of
      `core/error/app_failure.dart`, use everywhere after). Confirmed with
      user: hand-rolled `Result<T, E>` (`core/error/result.dart`), not
      `fpdart`'s `Either` — avoids a new dependency for a shape this small.
      `AppFailure.fromDioException()` maps per
      `docs/api-reference.md`'s error-shapes table; unit tested in
      `test/core/error/app_failure_test.dart`.
- [x] P1-06 `core/theme/` — `AppColors`, `AppTypography`, light/dark
      `ThemeData`, ported from the SwiftUI `AppTheme` palette. Turned out
      there wasn't a custom palette to port — `AppTheme.swift` was just the
      mode enum and `AccentColor.colorset` was never filled in; the app
      leaned on iOS system colors throughout. Ported what *was* consistently
      color-coded instead: build-result colors (`AppColors.forBuildResult`,
      from `JobDetailView.statusColor`) and the CI-tool accent colors (from
      `CITool.swift`). `AppTheme` seeds Material 3's `ColorScheme.fromSeed`
      with the Jenkins brand red. `AppTypography` stays thin (Material
      defaults cover Dynamic-Type-equivalent usage); the one named style is
      `buildLog`'s monospace, ported from `BuildLogView.swift`.
- [x] P1-07 `themeNotifierProvider` (system/light/dark, persisted via
      `shared_preferences`). `core/theme/theme_notifier.dart`.
- [x] P1-08 `presentation/common_widgets/` — `LoadingOverlay`,
      `ConnectionErrorView`, `ToastView`/`toastControllerProvider`
      (global banners with auto-dismiss, matching the original 3.5s timing).
      `ConnectionErrorView` and the toast pieces ported from
      `Shared/Components/ConnectionErrorView.swift` /
      `ToastView.swift`+`NotificationManager.swift` (confirmed 3.5s
      auto-dismiss, single-toast-replaces-previous behavior). `LoadingOverlay`
      is new — the old app had no shared abstraction, just scattered inline
      `ProgressView()`s.
- [x] P1-09 `app_router.dart` (go_router) with placeholder routes for every
      screen in the feature matrix, and a redirect stub that will later read
      `authNotifierProvider` (wired for real in Phase 2). Flat top-level
      routes for now (no `StatefulShellRoute`/tab chrome yet — that's
      `main_scaffold.dart`, not part of this task).
- [x] P1-10 Unit tests: secure storage wrapper, backend client's 401 →
      logout signal, `AppFailure` mapping from a few representative
      `DioException` shapes. 15 tests total, all passing; `flutter analyze`
      clean; `dart format --set-exit-if-changed` clean.
