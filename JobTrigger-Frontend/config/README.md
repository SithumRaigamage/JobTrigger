# Build-time config

Per-environment values consumed by `--dart-define-from-file` and read into a
typed config object by `core/config/app_config.dart` (Phase 1).

| File | Environment | Notes |
|---|---|---|
| `dev.json` | Local development | `BACKEND_BASE_URL` matches the old SwiftUI app's `Config.plist` (`http://127.0.0.1:5001`) — a locally-run `JobTrigger-Backend`. |
| `staging.json` | Staging | `BACKEND_BASE_URL` is a placeholder (`https://api-staging.jobtrigger.app`) — no staging deployment exists yet. Update when one does. |
| `prod.json` | Production | `BACKEND_BASE_URL` is a placeholder (`https://api.jobtrigger.app`, matching the example in `docs/api-reference.md`) — update when the backend is actually deployed. |
| `device.json` | A physical iPhone (machine-local) | **Git-ignored, not committed.** Written by `scripts/run-on-iphone.sh` with this Mac's Wi-Fi IP (`http://<IP>:5001`), since `127.0.0.1` on a phone is the phone. See [`IPHONE.md`](../../IPHONE.md). |

## Optional analytics keys (P20-76)

Add these to a config file to send anonymous usage events to the DevOps
lab's Umami (`custom-devops-stack/analytics/`). Leave them out and analytics
is off (a no-op). Not secrets, but environment-specific, so not committed in
`dev.json`.

| Key | Example | Meaning |
|---|---|---|
| `UMAMI_URL` | `http://127.0.0.1:3004` (simulator) | The Umami server |
| `UMAMI_WEBSITE_ID` | from Umami → Settings → Websites | The "JobTrigger app" website |

On a physical iPhone, `scripts/run-on-iphone.sh` adds both when run with
`UMAMI_WEBSITE_ID=<id>`, using this Mac's Wi-Fi address; set
`UMAMI_BIND=0.0.0.0` in the lab's `analytics/.env` so the phone can reach it.
Users can turn sharing off in Profile → Privacy.

## Usage

```bash
flutter run   --dart-define-from-file=config/dev.json
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
