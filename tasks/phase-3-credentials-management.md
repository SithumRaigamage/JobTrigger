# Phase 3 — Credentials Management

Goal: a user can add, edit, delete, and switch between Jenkins servers, and
verify a server is reachable before saving it.

- [ ] P3-01 `data/models/credential/credential_dto.dart`,
      `domain/credential/jenkins_server.dart` (per `docs/data-models.md`;
      remember the `password` → `secret` rename and redacted `toString()`).
- [ ] P3-02 `CredentialsRepository` interface + impl — GET/POST/PUT/DELETE
      `/api/credentials`, POST `/api/credentials/switch/:id`.
- [ ] P3-03 `credentialsNotifierProvider` (`AsyncNotifier<List<Credential>>`).
- [ ] P3-04 `activeServerNotifierProvider` — tracks active server id,
      persists it in `shared_preferences`, rehydrates on app start, falls
      back to the backend's `isDefault` server if local prefs are stale/missing.
- [ ] P3-05 `jenkinsClientProvider` rebuild wiring — confirm switching
      active server actually produces a fresh `Dio` instance with the new
      Basic Auth header (write a test for this specifically, it's an easy
      place for stale-closure bugs).
- [ ] P3-06 `SettingsScreen` — list of saved servers, swipe-to-delete or
      explicit delete action, tap to switch active, "add server" entry point.
- [ ] P3-07 `ServerEditBottomSheet` + `ServerFormNotifier` — add/edit form
      (serverName, jenkinsURL, username, password, paramToken, isDefault).
- [ ] P3-08 "Test connection" action on the form: calls `GET {url}/api/json`
      with Basic Auth using a throwaway Dio instance (not the active one),
      shows job count on success or the raw status/error on failure — before
      the user commits to saving.
- [ ] P3-09 Deleting the currently-active server: fall back to another
      `isDefault`/first remaining server, or to an empty state if none left
      (route to "add server" rather than a broken active-server state).
- [ ] P3-10 Unit tests: repository CRUD against mocked responses; active
      server fallback logic when the active credential is deleted.
- [ ] P3-11 Manual test against a real Jenkins instance: correct/incorrect
      credentials, unreachable host, self-signed cert if applicable.
