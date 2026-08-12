# CLAUDE.md — JobTrigger (Flutter Rewrite)

This file orients Claude (or any AI coding agent) working in this repository.
Read this before touching code. It defines what the project is, how it's
structured, and the rules for making changes.

## 1. What this project is

JobTrigger is a mobile app for DevOps engineers to trigger, monitor, and
inspect Jenkins CI/CD builds from a phone. It is being **rewritten from
SwiftUI (iOS-only) to Flutter (iOS + Android)**, and the client architecture
is being changed from an MVVM/ObservableObject style to a **layered,
feature-first Clean Architecture with Riverpod**.

The Node.js/Express + MongoDB backend is **kept, not rewritten** — it only
stores user accounts and Jenkins server credentials. Flutter talks to:
1. `lab-trigger-backend` for auth + credential storage (JWT bearer).
2. Jenkins servers directly over REST + HTTP Basic Auth (no backend proxy).

Do not conflate these two APIs — they have different auth schemes and error
shapes. See `docs/api-reference.md`.

## 2. Source of truth documents

Read these before starting any task, in this order:
- `docs/architecture.md` — layers, folder structure, data flow, why Riverpod
- `docs/data-models.md` — every model, old (Swift/JS) → new (Dart/freezed)
- `docs/api-reference.md` — every endpoint this app calls, backend + Jenkins
- `docs/state-management.md` — provider structure per feature
- `docs/migration-strategy.md` — phased rollout, parity checklist, QA gates
- `tasks/README.md` — how tasks are organized, then the relevant `tasks/phase-N-*.md`

Tasks are the unit of work. Don't start coding a feature without finding (or
creating) its task entry first, and update the task's status when done.

## 3. Tech stack (locked decisions — don't substitute without discussion)

| Concern | Choice | Notes |
|---|---|---|
| Language / SDK | Dart 3.x / Flutter (stable channel) | |
| State management | `flutter_riverpod` (v3, code-gen via `riverpod_generator`) | No `flutter_bloc`, no `Provider` package, no raw `setState` for anything beyond trivial local widget state. Bumped from the originally-planned v2 in Phase 0 — v2 predates the Flutter/Dart SDK this project targets; v3 is the actively maintained line and the `@riverpod`/`AsyncNotifier` patterns in `docs/architecture.md` and `docs/state-management.md` apply unchanged. |
| Networking | `dio` | Interceptors for JWT + Basic Auth, logging in debug only |
| Routing | `go_router` | Typed routes, deep-link ready |
| Models / JSON | `freezed` + `json_serializable` | All API models are immutable, code-generated |
| Secure storage | `flutter_secure_storage` | JWT + Jenkins passwords/tokens |
| Non-secure prefs | `shared_preferences` | Theme, last active server id, feature flags |
| Testing | `flutter_test`, `mocktail`, `riverpod_test` | Unit tests for repositories/notifiers are mandatory for Phase 2+ |
| Share sheet | `share_plus` | Added in Phase 5 (P5-12) — the build-log copy/share action, explicitly named by that task's own text. Not a substitution of anything on this list, narrowly scoped to one feature. |
| App version info | `package_info_plus` | Added in Phase 6 (P6-01) — the profile screen's app version footer needs the real installed version/build number, not a hardcoded string. |
| External links | `url_launcher` | Added in Phase 6 (P6-02) — the app info screen opens privacy policy/terms/licenses URLs and a `mailto:` support link, matching `AppInfoView.swift`'s `openURL` usage exactly. |

Do not introduce a second state-management library, a second HTTP client, or
a second routing package. If a task seems to require it, flag it instead of
silently adding a dependency.

## 4. Architecture in one paragraph

Three layers per feature: **presentation** (widgets + Riverpod notifiers) →
**domain** (plain Dart entities + repository interfaces, no Flutter imports)
→ **data** (DTOs, remote data sources, repository implementations). Widgets
never call `dio` directly and never parse JSON. Notifiers never construct
`Dio` instances. See `docs/architecture.md` for the full diagram and the
folder-by-folder mapping from the old SwiftUI project.

## 5. Conventions

- **Feature-first**: everything for "job detail" lives under
  `lib/presentation/features/job_detail/`, `lib/domain/job/` (shared across
  features that touch jobs), etc. Don't create a giant flat `screens/` folder.
- **Naming**: `SomeScreen` (top-level route widget), `SomeView` (non-route
  composed widget), `SomeNotifier` (Riverpod `AsyncNotifier`/`Notifier`),
  `SomeRepository` (domain interface), `SomeRepositoryImpl` (data layer).
- **Errors**: repositories return `Result<T, AppFailure>`-style outcomes (see
  `docs/architecture.md#error-handling`), never throw raw `DioException` past
  the data layer. UI maps `AppFailure` to copy, never inspects HTTP status
  codes directly in a widget.
- **No business logic in widgets.** If a `build()` method has an `if` that
  decides *what* to do (not just *how to render*), it belongs in a notifier.
- **Generated code**: run `dart run build_runner build --delete-conflicting-outputs`
  after editing any `@freezed`/`@riverpod`/`@JsonSerializable` class. Never
  hand-edit `*.g.dart` or `*.freezed.dart`.
- **Commits/PRs**: reference the task id, e.g. `[P3-04] Add credential switch endpoint`.

## 6. Commands

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # after model/provider changes
flutter analyze                                            # must be clean before PR
flutter test
flutter run -d <device>
```

## 7. What NOT to do

- Don't port SwiftUI `ObservableObject` patterns 1:1 — translate to the
  Riverpod notifier structure in `docs/state-management.md`, not a literal
  transliteration.
- Don't rewrite the Node backend as part of this migration unless a task in
  `tasks/` explicitly says so. Backend changes are a separate track.
- Don't hardcode Jenkins or backend base URLs — use `core/config/`.
- Don't store JWTs, Jenkins passwords, or API tokens in `shared_preferences`
  — secure storage only.
- Don't add screens/features not in the original feature matrix without
  flagging it — scope creep during a rewrite is how migrations stall.

## 8. Current status

Tracked in `tasks/README.md`. Update the phase status table there whenever a
task moves state — this file doesn't duplicate that tracker.
