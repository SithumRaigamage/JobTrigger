# Phase 1 — Core Infrastructure

Goal: the plumbing every feature depends on exists and is unit-tested,
before any screen is built.

- [ ] P1-01 `core/config/app_config.dart` — reads flavor/`--dart-define`
      values into a typed config object (backend base URL, environment name).
- [ ] P1-02 `core/storage/secure_storage_service.dart` — thin typed wrapper
      over `flutter_secure_storage` (`saveToken`, `readToken`, `clear`, etc.).
      Unit test with the package's in-memory test implementation.
- [ ] P1-03 `core/network/backend_api_client.dart` — `Dio` instance +
      interceptor that attaches `Authorization: Bearer` from secure storage,
      and a response interceptor that clears session + signals logout on 401.
- [ ] P1-04 `core/network/jenkins_client_factory.dart` — builds a `Dio`
      instance with Basic Auth for a given `Credential`; exposes
      `jenkinsClientProvider` that rebuilds when the active server changes
      (per `docs/state-management.md`).
- [ ] P1-05 Shared `AppFailure` sealed class + `Either`/`Result` choice
      (decide once, document the choice at the top of
      `core/error/app_failure.dart`, use everywhere after).
- [ ] P1-06 `core/theme/` — `AppColors`, `AppTypography`, light/dark
      `ThemeData`, ported from the SwiftUI `AppTheme` palette.
- [ ] P1-07 `themeNotifierProvider` (system/light/dark, persisted via
      `shared_preferences`).
- [ ] P1-08 `presentation/common_widgets/` — `LoadingOverlay`,
      `ConnectionErrorView`, `ToastView`/`toastControllerProvider`
      (global banners with auto-dismiss, matching the original 3.5s timing).
- [ ] P1-09 `app_router.dart` (go_router) with placeholder routes for every
      screen in the feature matrix, and a redirect stub that will later read
      `authNotifierProvider` (wired for real in Phase 2).
- [ ] P1-10 Unit tests: secure storage wrapper, backend client's 401 →
      logout signal, `AppFailure` mapping from a few representative
      `DioException` shapes.
