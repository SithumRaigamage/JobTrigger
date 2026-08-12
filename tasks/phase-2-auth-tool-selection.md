# Phase 2 — Auth & Tool Selection

Goal: a user can sign up, log in, stay logged in across restarts, and reach
the (static) tool-selection grid.

- [ ] P2-01 `data/models/auth/user_dto.dart`, `domain/auth/user.dart`
      (per `docs/data-models.md`).
- [ ] P2-02 `AuthRepository` interface + `AuthRepositoryImpl` — signup,
      login, calling `/api/auth/signup` and `/api/auth/login`.
- [ ] P2-03 `authNotifierProvider` (`AsyncNotifier<AuthState>`) — holds
      `unauthenticated | authenticated(User)`; on login/signup success,
      stores JWT via `secure_storage_service`, stores cached user.
- [ ] P2-04 On app start, `authNotifierProvider` attempts to rehydrate
      session from secure storage (no network call needed unless validating
      token freshness is desired — decide and document the choice here).
- [ ] P2-05 `LoginScreen` + `LoginNotifier` — email/password form, validation
      matching the original regex/length rules, loading + error states.
- [ ] P2-06 `SignupScreen` + `SignupNotifier` — same shape as login.
- [ ] P2-07 Wire `app_router.dart` redirect: unauthenticated → `/login`,
      authenticated hitting `/login` → tool selection / home.
- [ ] P2-08 `ToolSelectionScreen` — static grid of `CiToolCard`s (Jenkins
      enabled, GitHub Actions/GitLab/SonarQube/CircleCI shown but disabled —
      do not build real integrations for these, see `tasks/backlog.md`).
- [ ] P2-09 Logout action (clear secure storage + reset `authNotifierProvider`
      to `unauthenticated`, router redirect follows automatically).
- [ ] P2-10 Unit tests: `AuthRepositoryImpl` against mocked Dio responses
      (success, invalid credentials, network error); `AuthNotifier` state
      transitions.
- [ ] P2-11 Manual test: kill and relaunch app while logged in → lands on
      home, not login.
