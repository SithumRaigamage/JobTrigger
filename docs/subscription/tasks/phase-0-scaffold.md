# Phase 0 – Scaffold the Flutter Project

## Tasks

- [ ] **Create a new Flutter project** (or use existing) with the command `flutter create .` inside the `JobTrigger-Frontend` directory.
- [ ] **Set up project flavors** (`dev`, `staging`, `prod`) via `flutter flavors` or by adding `flutter configure` scripts.
- [ ] **Add CI configuration** – GitHub Actions workflow that runs `flutter analyze`, `flutter test`, and builds the app for iOS and Android.
- [ ] **Create baseline `analysis_options.yaml`** with the team’s strict warnings enabled (e.g., prefer_const_literals_to_create_immutables, omit_local_variable_types, etc.).
- [ ] **Initialize core directories** – `core/network`, `core/storage`, `core/config`, `core/error`, `presentation/features`, `data/models`, `data/repositories`, `presentation/common_widgets`.
- [ ] **Add required dependencies** to `pubspec.yaml`:
  - `flutter_riverpod` (v3)
  - `dio` (for HTTP)
  - `flutter_secure_storage` (for JWT/credentials)
  - `package_info_plus` (for version display)
  - `go_router` (routing)
  - `freezed` + `json_serializable` (codegen)
  - `build_runner` & `riverpod_generator` (code generation)
  - `shared_preferences` (light preferences)
  - `workmanager` (background polls)
  - `flutter_local_notifications` (build watches)
  - `local_auth` (app lock)
  - `home_widget` (widgets)
  - `share_plus` (share logs)
  - `revenuecat` (subscription billing)
- [ ] **Set up `app_config.dart`** to hold the backend base URL per flavor, and read it via `env` variables or `flutter_dotenv`.
- [ ] **Create empty `core/error/result.dart`** and `core/error/guard.dart` as placeholders for the result/guard pattern.
- [ ] **Run `flutter pub get`** and verify `flutter analyze` is clean (no new warnings).

### Acceptance Criteria
- A fresh `flutter create .` project exists with the required dependencies installed.
- `flutter analyze` reports no errors or warnings (baseline clean).
- Project structure directories exist as listed.
- A minimal `flutter run -d chrome` launch works.

*End of Phase 0 – Scaffold the Flutter Project.*