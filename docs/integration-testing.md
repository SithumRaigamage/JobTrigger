# Integration Testing (End-to-End)

Real end-to-end tests that drive the actual app on a connected
simulator/device — real navigation, real taps, real network calls against a
running backend. Complements (doesn't replace) the unit/widget suite in
`JobTrigger-Frontend/test/` (`flutter_test`, `mocktail`, `riverpod_test`).

Uses Flutter's own `integration_test` package — not Playwright/a browser
tool. Playwright automates web browsers and has no way to drive a native
iOS/Android app; `integration_test` is the Flutter-native equivalent and
runs on the exact same simulator you test on manually.

## Prerequisites

1. Backend running with the dev account seeded:
   ```bash
   ./setup-dev.sh
   ```
   (or `USE_DOCKER=true ./setup-dev.sh` for local MongoDB — see
   [Dev Setup](./dev-setup.md))
2. A connected simulator/device (`flutter devices` to check)

## Running

```bash
cd JobTrigger-Frontend
flutter test integration_test/app_test.dart --dart-define-from-file=config/dev.json -d "iPhone Air"
```

Takes ~50s — it's a real app build + real network round-trips, not mocked.

## What's covered today (`integration_test/app_test.dart`)

| Scenario | Asserts |
|---|---|
| Login screen renders pre-selection | `primary` color is `AppColors.brandSeed` (blue), not a tool accent |
| Full flow: login → tool selection → select Jenkins → Home | Login succeeds against the real backend; ToolSelectionScreen still shows blue; tapping Jenkins navigates to Home ("Jobs" AppBar) with `primary` now `AppColors.ciToolJenkins` (red) |

This set exists specifically as regression coverage for the per-tool-theming
feature (see `main.dart`, `ActiveToolNotifier`, `AppTheme`) — it was written
right after a real bug where the theme stayed tool-tinted across app
restarts due to stale persisted state.

## Test-only widget keys

A few widgets carry stable `Key`s purely so integration tests can find them
without brittle text/type finders:

- `login_email_field`, `login_password_field`, `login_submit_button` — `LoginScreen`
- `tool_card_<CiTool.name>` (e.g. `tool_card_jenkins`) — `ToolSelectionScreen`

Add a `Key` the same way for any new screen a future scenario needs to
target.

## Adding more scenarios

Add new `testWidgets(...)` blocks to `integration_test/app_test.dart` (or a
new file in `integration_test/` for a distinct flow — e.g.
`job_trigger_test.dart` for trigger-a-build once that becomes a priority).
Each `testWidgets` calls `app.main()` itself; they run sequentially against
the same live backend, so use data that's safe to create repeatedly (or
clean up in the test) rather than assuming a pristine database per test.

## Known limitations

- **Not run in CI** — these need a live backend + a booted simulator,
  neither of which `.github/workflows/flutter-ci.yml` currently provisions.
  Today this is a local, manual regression check; wiring it into CI (e.g.
  spinning up MongoDB + backend + an iOS simulator runner) is future work,
  not done as part of this initial setup.
- **Shared app state across `testWidgets` in one file** — since `app.main()`
  doesn't reset previous tests' provider state, keep scenarios in one file
  roughly sequential/dependent (as the two here are) rather than assuming
  full isolation.
