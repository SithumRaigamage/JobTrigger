# Build-time config

Per-environment values consumed by `--dart-define-from-file` and read into a
typed config object by `core/config/app_config.dart` (Phase 1).

| File | Environment | Notes |
|---|---|---|
| `dev.json` | Local development fallback | Used when running Flutter directly; prefer the root `scripts/run-flutter.sh`, which generates a target-specific dev URL. |
| `staging.json` | Staging | `BACKEND_BASE_URL` is a placeholder (`https://api-staging.jobtrigger.app`) — no staging deployment exists yet. Update when one does. |
| `prod.json` | Production | `BACKEND_BASE_URL` is a placeholder (`https://api.jobtrigger.app`, matching the example in `docs/api-reference.md`) — update when the backend is actually deployed. |
| `device.json` | Generated local device config | **Git-ignored, not committed.** Written by `scripts/run-flutter.sh` or the iPhone-specific `scripts/run-on-iphone.sh` with a reachable Mac LAN/Tailscale address. |

## `WEBSITE_BASE_URL`

The JobTrigger website. The login screen's "Forgot password? Reset it on
the web" opens `<WEBSITE_BASE_URL>/forgot-password` in the browser: a
password is reset on the website only, never in the app (US-AUTH-08).
`dev.json` uses `http://localhost:3000` (`npm run dev` in `JobTrigger-Web/`);
The launchers write a reachable Mac LAN/Tailscale address instead. A
non-dev build without it hides the link.

## `SENTRY_DSN`

Where crash reports go (E3): a GlitchTip DSN for the `jobtrigger-app`
project. **Not committed** in `dev.json`, `staging.json` or `prod.json`.
Leave it out and reporting is off (tests, CI, a plain `flutter run`). Give it
with a second define file, e.g. a git-ignored `config/sentry.json`
(`{"SENTRY_DSN": "…"}`) added as
`--dart-define-from-file=config/sentry.json`, or for the iPhone run
`SENTRY_DSN_APP=… scripts/run-on-iphone.sh`. See `docs/error-reporting.md`.

## `REVENUECAT_IOS_KEY` / `REVENUECAT_ANDROID_KEY`

RevenueCat's public SDK keys (Phase 20), one per store. **Not committed** in
any `config/*.json`. Leave them out and the app has no billing: it never
starts the purchase SDK and offers nothing to buy, which is also how a build
behaves while `BILLING_ENABLED` is off on the backend. Give them with a
second, git-ignored define file such as `config/billing.json`
(`{"REVENUECAT_IOS_KEY": "…", "REVENUECAT_ANDROID_KEY": "…"}`) added as
`--dart-define-from-file=config/billing.json`. The backend's secret REST key
is never in the app.

## Usage

```bash
./scripts/run-flutter.sh --target=ios-simulator
flutter build --dart-define-from-file=config/staging.json
flutter build --dart-define-from-file=config/prod.json
```

Never hardcode these values elsewhere — `AppConfig` (Phase 1) is the only
place that reads `String.fromEnvironment`/`bool.fromEnvironment` for these
keys.

Native Android/iOS product flavors were deliberately not added in Phase 0:
the only thing that varies per environment right now is the backend URL, and
`--dart-define-from-file` covers that without the extra maintenance of
per-flavor Gradle blocks, Xcode schemes, and app-icon variants. Revisit if a
future task needs environments installed side-by-side on the same device.
