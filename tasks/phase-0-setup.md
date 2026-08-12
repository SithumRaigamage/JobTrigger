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
- [x] P0-05 Set up build flavors / `--dart-define` config for dev/staging/prod
      backend URLs (feeds `core/config/app_config.dart` in Phase 1). Used
      `--dart-define-from-file` with `config/{dev,staging,prod}.json`
      instead of native Android/iOS product flavors — see
      `config/README.md` for rationale and usage. `dev.json` mirrors the old
      SwiftUI app's `Config.plist` backend URL; `staging.json`/`prod.json`
      use placeholder URLs (no deployments exist yet) that must be updated
      before those environments are real.
- [x] P0-06 CI pipeline: `flutter analyze` + `flutter test` on every PR.
      Added `.github/workflows/flutter-ci.yml`, mirroring the existing
      `nodejs-test.yml` workflow's trigger branches/style. Also added a
      `dart format --set-exit-if-changed` step (not just analyze/test) so
      formatting drift fails CI too. Verified all three steps pass locally
      against the current skeleton.
- [x] P0-07 Confirm iOS min target (iOS 17+, matching current app) and set
      Android `minSdkVersion` deliberately (don't leave it at the template
      default without checking against the team's supported device range).
      Confirmed with user: iOS 17.0 (the Xcode project's literal 26.2 was
      Xcode defaulting to the latest SDK, not a deliberate setting — task
      file and README both said 17+). Set `IPHONEOS_DEPLOYMENT_TARGET =
      17.0` in `project.pbxproj`. Android `minSdk` hardcoded to 24 — not
      arbitrary: `flutter_secure_storage` (a locked dependency) declares
      `minSdk 24` in its own Android module, which is also the current
      Flutter template floor.
- [x] P0-08 App icon, splash screen, and bundle metadata carried over from
      the SwiftUI app's assets. Bundle display name set to "JobTrigger" on
      both platforms (`CFBundleDisplayName` / `android:label`) — version
      1.0.0+1 already matches the old app's `MARKETING_VERSION 1.0` /
      `CURRENT_PROJECT_VERSION 1`. Confirmed with user: no icon/splash
      artwork exists to carry over (old app's asset catalogs are empty
      manifests, no PNGs were ever added), so Flutter's default
      icon/splash stays as a placeholder; tracked as a blocker note on
      `tasks/phase-6-polish-release.md` P6-07 for when real artwork is
      supplied.
