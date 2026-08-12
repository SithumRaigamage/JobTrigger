# Phase 3 — Credentials Management

Goal: a user can add, edit, delete, and switch between Jenkins servers, and
verify a server is reachable before saving it.

- [x] P3-01 `data/models/credential/credential_dto.dart`,
      `domain/credential/jenkins_server.dart` (per `docs/data-models.md`;
      remember the `password` → `secret` rename and redacted `toString()`).
      Verified `CredentialDto`'s shape against the real backend model
      (`lab-trigger-backend/models/JenkinsCredential.js`) — matches the
      docs exactly. Renamed the Phase 0 skeleton dirs from plural
      `domain/credentials/`/`data/models/credentials/` to singular
      `credential/` to match this task's explicit paths.
- [x] P3-02 `CredentialsRepository` interface + impl — GET/POST/PUT/DELETE
      `/api/credentials`, POST `/api/credentials/switch/:id`. Verified
      request/response shapes against the real backend controller
      (`credentialsController.js`) — note its DELETE response is actually
      `{ message: 'Credential removed' }`, not `{ success }` as
      `docs/api-reference.md` states, so `delete()` just checks for a
      non-throwing 2xx rather than parsing a `success` field that doesn't
      exist. `add`/`update` take named fields, not a `JenkinsServer`, since
      a new server has no `id` yet.
- [x] P3-03 `credentialsNotifierProvider` (`AsyncNotifier<List<Credential>>`).
      Found and fixed a real compile error in `docs/architecture.md §4`'s
      own sample pattern while implementing this: `Future<void> refresh() =>
      ref.invalidateSelf();` doesn't type-check because `invalidateSelf()`
      returns `void`, not `Future<void>`, in this Riverpod version — needs
      `async =>`. Will apply the same fix to every future notifier that
      follows this pattern rather than hitting it repeatedly.
- [x] P3-04 `activeServerNotifierProvider` — tracks active server id,
      persists it in `shared_preferences`, rehydrates on app start, falls
      back to the backend's `isDefault` server if local prefs are stale/missing.
      Reuses `credentialsNotifierProvider`'s already-fetched list (per
      `docs/state-management.md`'s "don't duplicate the fetch" rule) rather
      than calling the repository a second time.
- [x] P3-05 `jenkinsClientProvider` rebuild wiring — confirm switching
      active server actually produces a fresh `Dio` instance with the new
      Basic Auth header (write a test for this specifically, it's an easy
      place for stale-closure bugs). The Basic-Auth `Dio` builder itself
      (`buildJenkinsDio({baseUrl, username, password})`) already exists from
      Phase 1 (`core/network/jenkins_client_factory.dart`) — this task is
      just the reactive `@riverpod` provider that calls it with
      `ref.watch(activeServerNotifierProvider)`'s current credential.
      Throws if no active server is set (matches the docs' non-nullable
      `Provider<Dio>` typing). Test confirms both the header changes and the
      `Dio` instance itself is not `identical()` across a server switch.
- [x] P3-06 `SettingsScreen` — list of saved servers, swipe-to-delete or
      explicit delete action, tap to switch active, "add server" entry point.
      Built together with P3-07/P3-08/P3-09 since none of them are
      independently functional. Skipped porting the old app's
      "Appearance"/"Backend Server Status" sections and its redundant
      inline (non-sheet) edit form — not in this phase's task list; noted
      in `tasks/phase-6-polish-release.md` instead. Added a swipe-delete
      confirmation dialog (the old app deleted immediately on swipe, no
      confirmation) since deletion is irreversible — a deliberate small
      deviation, not a silent one.
- [x] P3-07 `ServerEditBottomSheet` + `ServerFormNotifier` — add/edit form
      (serverName, jenkinsURL, username, password, paramToken, isDefault).
- [x] P3-08 "Test connection" action on the form: calls `GET {url}/api/json`
      with Basic Auth using a throwaway Dio instance (not the active one),
      shows job count on success or the raw status/error on failure — before
      the user commits to saving. Implemented as a standalone
      `testJenkinsConnection()` function in
      `core/network/jenkins_client_factory.dart` rather than through
      `jenkinsRepositoryProvider` (which doesn't exist until Phase 4) —
      `docs/state-management.md`'s mention of that provider describes the
      eventual full picture, not what's buildable now. Own
      `TestConnectionNotifier` (not folded into `ServerFormNotifier`) since
      a user can test a candidate connection independently of, and
      repeatedly before, saving.
- [x] P3-09 Deleting the currently-active server: fall back to another
      `isDefault`/first remaining server, or to an empty state if none left
      (route to "add server" rather than a broken active-server state).
      Implemented in `SettingsScreen._deleteServer`. "Route to add server"
      simplified to "empty state with the always-visible add-server FAB
      already in view" rather than auto-navigating — the FAB is right
      there, so forcing navigation would be an unnecessary extra step.
- [x] P3-10 Unit tests: repository CRUD against mocked responses; active
      server fallback logic when the active credential is deleted.
      Refactored the delete+fallback logic out of the `SettingsScreen`
      widget into `ActiveServerNotifier.deleteServer()` first — it had
      landed in a widget's private method while building P3-06/P3-09
      together, which both violates CLAUDE.md §5's "no business logic in
      widgets" rule and would've been unnecessarily hard to unit test.
      9 new tests (5 repository CRUD, 4 fallback scenarios — isDefault
      fallback, first-remaining fallback, empty-state clear, non-active
      delete is a no-op), all passing (33 total).
- [x] P3-11 Manual test against a real Jenkins instance: correct/incorrect
      credentials, unreachable host, self-signed cert if applicable.
      Ran against a real local Jenkins (`custom-devops-stack/jenkins`,
      user-provided, started via its `script.sh start`) — verified by
      calling the actual `testJenkinsConnection()` function directly (not
      curl, not a mock) in a throwaway `flutter test` script, deleted
      after use. Results: correct credentials → `Ok(2)` (2 real top-level
      job folders, matching a direct curl check); incorrect credentials →
      `AuthFailure`; unreachable host (closed port) → `NetworkFailure`.
      Self-signed cert: N/A — the available instance is plain HTTP, no TLS.
      Jenkins/SonarQube/Mongo stack left running locally (`docker ps`) in
      case later phases (4/5) want it too; stop with `./script.sh stop` in
      `custom-devops-stack/`.
