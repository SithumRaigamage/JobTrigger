# Phase 0 — Project Setup & CI

Goal: an empty-but-runnable Flutter app with the right scaffolding, before
any feature code.

- [x] P0-01 `flutter create` with iOS bundle id and Android application id
      matching the existing SwiftUI app (so store listings can be reused).
      Created `job_trigger/`. iOS bundle id `Sraig.Lab-Trigger-frontend`
      (matches old app exactly); Android `applicationId`
      `com.sraig.jobtrigger` (no prior Android app existed — confirmed with
      user, based on product name "JobTrigger" per README/CLAUDE.md branding
      rather than the old internal "Lab-Trigger" folder name).
- [x] P0-02 Add locked dependencies from `CLAUDE.md §3` to `pubspec.yaml`:
      `flutter_riverpod`, `riverpod_generator`, `riverpod_annotation`, `dio`,
      `go_router`, `freezed`, `freezed_annotation`, `json_serializable`,
      `json_annotation`, `flutter_secure_storage`, `shared_preferences`,
      `build_runner`. Confirmed with user: bumped `flutter_riverpod` to v3
      (v2 predates this Flutter/Dart SDK) — `CLAUDE.md §3` updated. The
      codegen quintet (`flutter_riverpod`/`riverpod_annotation`/
      `riverpod_generator`/`freezed`/`json_serializable`) is pinned to exact
      mutually-compatible versions rather than `^` ranges because their
      latest releases require conflicting `analyzer` majors — see the
      comment in `pubspec.yaml`. Verified with a throwaway `@freezed`/
      `@riverpod` smoke file run through
      `dart run build_runner build --delete-conflicting-outputs` before
      deleting it.
- [x] P0-03 Set up `analysis_options.yaml` (extend `flutter_lints`, enable
      stricter rules — no implicit dynamic, prefer const, etc.). Added
      `strict-casts`/`strict-inference`/`strict-raw-types` (closes the
      implicit-dynamic hole), const-correctness rules, `unawaited_futures`/
      `close_sinks` (matches the polling-lifecycle rule in
      `docs/architecture.md §7`), and excluded `*.g.dart`/`*.freezed.dart`
      from analysis since they're never hand-edited.
- [x] P0-04 Create `lib/` skeleton matching `docs/architecture.md`'s folder
      structure (empty placeholder files/dirs with `.gitkeep` where needed).
      Directories only, each with `.gitkeep` — no source files, since the
      concrete files (`app_config.dart`, `secure_storage_service.dart`, etc.)
      are Phase 1's job per `tasks/phase-1-core-infrastructure.md`. Domain
      layer split into `domain/{auth,credentials,jenkins}/` (credentials
      kept separate from jenkins entities/repository, mirroring
      `docs/api-reference.md`'s split between the backend API and the
      Jenkins API).
- [ ] P0-05 Set up build flavors / `--dart-define` config for dev/staging/prod
      backend URLs (feeds `core/config/app_config.dart` in Phase 1).
- [ ] P0-06 CI pipeline: `flutter analyze` + `flutter test` on every PR.
- [ ] P0-07 Confirm iOS min target (iOS 17+, matching current app) and set
      Android `minSdkVersion` deliberately (don't leave it at the template
      default without checking against the team's supported device range).
- [ ] P0-08 App icon, splash screen, and bundle metadata carried over from
      the SwiftUI app's assets.
