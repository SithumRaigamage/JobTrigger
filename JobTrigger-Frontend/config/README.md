# Build-time config

Per-environment values consumed by `--dart-define-from-file` and read into a
typed config object by `core/config/app_config.dart` (Phase 1).

| File | Environment | Notes |
|---|---|---|
| `dev.json` | Local development fallback | Used when running Flutter directly; prefer the root `scripts/run-flutter.sh`, which generates a target-specific dev URL. |
| `staging.json` | Staging | `BACKEND_BASE_URL` is a placeholder (`https://api-staging.jobtrigger.app`) — no staging deployment exists yet. Update when one does. |
| `prod.json` | Production | `BACKEND_BASE_URL` is a placeholder (`https://api.jobtrigger.app`, matching the example in `docs/api-reference.md`) — update when the backend is actually deployed. |
| `device.json` | Generated local device config | **Git-ignored, not committed.** Written by `scripts/run-flutter.sh` or the iPhone-specific `scripts/run-on-iphone.sh` with a reachable Mac LAN/Tailscale address. |
| `sentry.json` | Release secret | **Git-ignored, not committed.** `SENTRY_DSN` for crash reports; merged by `scripts/build-release.sh`. |
| `billing.json` | Release secret | **Git-ignored, not committed.** `REVENUECAT_IOS_KEY` / `REVENUECAT_ANDROID_KEY`; merged by `scripts/build-release.sh`. |
| `sentry.example.json` | Template | Committed. Copy to `sentry.json` and replace every `REPLACE_WITH_…`. |
| `billing.example.json` | Template | Committed. Copy to `billing.json` and replace every `REPLACE_WITH_…`. |

Before a release build, check the real files from the repository root:
`scripts/build-release.sh --check all`. It prints key names only, never a
value, and fails when a key is missing, still the template, in the wrong
shape (`SENTRY_DSN` is `https://<key>@<host>/<project id>`;
`REVENUECAT_IOS_KEY` starts `appl_`, `REVENUECAT_ANDROID_KEY` `goog_`), or
pointing at a development address.

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
Leave it out and reporting is off (tests, CI, a plain `flutter run`). For a
release build, put it in the git-ignored `config/sentry.json`
(`{"SENTRY_DSN": "…"}`) and build with `scripts/build-release.sh`, which
merges it in; a `SENTRY_DSN` environment variable works too. For the iPhone
run, `SENTRY_DSN_APP=… scripts/run-on-iphone.sh`. See
`docs/error-reporting.md`.

## `REVENUECAT_IOS_KEY` / `REVENUECAT_ANDROID_KEY`

RevenueCat's public SDK keys (Phase 20), one per store. **Not committed** in
any `config/*.json`. Leave them out and the app has no billing: it never
starts the purchase SDK and offers nothing to buy, which is also how a build
behaves while `BILLING_ENABLED` is off on the backend. For a release build,
put them in the git-ignored `config/billing.json`
(`{"REVENUECAT_IOS_KEY": "…", "REVENUECAT_ANDROID_KEY": "…"}`) and build
with `scripts/build-release.sh`, which merges it in and fails if the key for
the target platform is missing; the same names work as environment
variables. The backend's secret REST key is never in the app.

## `BILLING_PREVIEW`

Dev-only (P24-04): set to `true` and the app shows the subscription UI with
static offers (the website's two plans) instead of needing RevenueCat keys —
the Profile "Subscription" row, the Subscription screen and the paywall
render, while Subscribe always fails ("Preview build: no store is
connected") and Restore finds nothing. The launchers write it into
`device.json` for every dev run; opt out with `BILLING_PREVIEW=0
scripts/run-on-iphone.sh`. `AppConfig` ignores the flag in release builds,
so store submissions can never preview billing, and `staging.json`/
`prod.json` never set it.

## `SANDBOX_BILLING`

Development only: a local store simulator, so the paywall and Subscription
screen can buy, cancel, expire and resubscribe with **no payment** and no
Apple, Google or RevenueCat account. The launchers write it when you pass
`SANDBOX_BILLING=1`:

```bash
SANDBOX_BILLING=1 scripts/run-flutter.sh --target=android-device
```

The committed root `environment.conf` sets `SANDBOX_BILLING=1`, so local
launchers enable this by default; override with `SANDBOX_BILLING=0`. The
backend must also run with `BILLING_ENABLED=true SANDBOX_BILLING=true`
(`setup-dev.sh` exports both).
`AppConfig` ignores the flag in release builds, and the backend answers 404
for the sandbox routes in production, so it can never ship.

## Testing real sandbox purchases (Apple / Google)

Preview mode cannot buy anything. To actually subscribe, cancel and
resubscribe in the Apple/Google **sandbox**, you must supply the RevenueCat
**public** SDK key — see `docs/subscription/sandbox-testing.md` for the full
external setup (App Store Connect, Google Play Console, RevenueCat, sandbox
testers). On the iPhone:

```bash
REVENUECAT_IOS_KEY=app_... scripts/run-on-iphone.sh
```

Passing the key automatically turns preview mode off, so the paywall calls
the real store. The backend also needs `BILLING_ENABLED=true` plus the real
RevenueCat **secret** key/webhook auth in its `.env` for entitlements to
sync.

## Usage

```bash
./scripts/run-flutter.sh --target=ios-simulator

# Release builds: merge the environment config with the git-ignored secrets
# (config/sentry.json, config/billing.json, or the environment variables).
./scripts/build-release.sh appbundle
./scripts/build-release.sh ipa
./scripts/build-release.sh --check ipa   # validate keys, build nothing

# Unsigned verification build with no secrets (never for a store upload):
./scripts/build-release.sh --allow-missing apk
```

Never hardcode these values elsewhere — `AppConfig` (Phase 1) is the only
place that reads `String.fromEnvironment`/`bool.fromEnvironment` for these
keys.

Native Android/iOS product flavors were deliberately not added in Phase 0:
the only thing that varies per environment right now is the backend URL, and
`--dart-define-from-file` covers that without the extra maintenance of
per-flavor Gradle blocks, Xcode schemes, and app-icon variants. Revisit if a
future task needs environments installed side-by-side on the same device.
