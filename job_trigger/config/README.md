# Build-time config

Per-environment values consumed by `--dart-define-from-file` and read into a
typed config object by `core/config/app_config.dart` (Phase 1).

| File | Environment | Notes |
|---|---|---|
| `dev.json` | Local development | `BACKEND_BASE_URL` matches the old SwiftUI app's `Config.plist` (`http://127.0.0.1:5001`) — a locally-run `lab-trigger-backend`. |
| `staging.json` | Staging | `BACKEND_BASE_URL` is a placeholder (`https://api-staging.jobtrigger.app`) — no staging deployment exists yet. Update when one does. |
| `prod.json` | Production | `BACKEND_BASE_URL` is a placeholder (`https://api.jobtrigger.app`, matching the example in `docs/api-reference.md`) — update when the backend is actually deployed. |

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
