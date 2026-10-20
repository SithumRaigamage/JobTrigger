# Phase 9 — Testing completion, CI/CD hardening, dev tooling (epic HARDEN)

Goal: close the test-coverage gaps identified by a full audit of both apps
(25 of 31 frontend notifiers and several backend endpoints had zero
coverage), fix the two GitHub Actions workflows (both were actually
failing, not flaky — root causes verified against real CI run logs), add a
dormant build-only CD workflow, and wire up Codecov/Dependabot/SonarCloud.
Promoted from a direct user request on 2026-09-15 (not from
`tasks/backlog.md`). See the approved plan for full context and the
Explore-agent audit findings behind each task below.

This is dev/QA/tooling hardening, not new product surface — no screens, no
`CiTool` changes. The separate GitLab CI / SonarQube / CircleCI user-story
epics from the same request are docs-only deliverables and don't need task
ids here (same reason `12-github-actions.md` predated `phase-8-github-actions.md`).

Working order: CI hygiene first (unblocks a green baseline), then backend
testing, then frontend testing, then CD, then tooling. Each task needs a
plan/design checkpoint before its code lands, per `CLAUDE.md` §9.

## CI hygiene

- [x] P9-00 Fix both failing GitHub Actions workflows. `flutter-ci.yml`:
      run `dart format .` for real (44 files currently fail
      `--set-exit-if-changed`, verified locally against the CI-pinned
      Flutter 3.44.9/Dart 3.12.2) — formatting only, no logic changes.
      `nodejs-test.yml`: bump `mongodb-memory-server` off `^8.12.0` (its
      downloaded `mongod` needs `libssl1.1`, forcing `runs-on:
      ubuntu-20.04` — a **hosted runner image GitHub has since retired**,
      which is why the job sits `queued` forever instead of failing fast)
      to a current major that ships a `libssl3`-linked binary, and change
      `runs-on` to `ubuntu-latest`. Verify `npm test` passes locally with
      the new version before touching the workflow file.

## Backend testing

- [x] P9-01 Fix two real bugs surfaced by the coverage audit before testing
      around them: `middleware/auth.js` never checks the JWT's user still
      exists (a deleted user's unexpired token authenticates forever) →
      add a 401 on missing user; `credentialsController.js` +
      `githubCredentialsController.js`'s `update`/`delete`/`switch` don't
      guard `mongoose.Types.ObjectId.isValid(id)`, so a malformed id falls
      through to a generic 500 via `CastError` instead of 400, and a
      valid-but-missing id also 500s instead of 404. `authController.js`
      signup 500s on a missing `password`/`email` (calls `.length` on
      `undefined`) instead of a clean 400.
- [x] P9-02 New backend tests for the highest-risk gaps found (see audit):
      switch-endpoint ownership violation (Jenkins + GitHub — only
      update/delete ownership was tested), Jenkins credential update/delete
      happy path (asymmetric vs. GitHub's existing coverage), malformed-id
      and not-found cases for update/delete/switch on both credential
      types, signup missing-field cases, expired-JWT and deleted-user-JWT
      cases, add-credential missing-required-field → 400.
- [x] P9-03 Backend coverage tooling: add `c8` devDependency, add
      `npm run test:coverage` (`c8 --reporter=lcov --reporter=text npm
      test`) without touching the existing plain `npm test` script CI
      already calls.

Backend: 20 → 43 tests, 93.79% statement coverage, `middleware/auth.js` at
100%. Also fixed, while fixing update/delete/switch's ownership check: an
ordering bug where `isDefault: true` on a malicious update request unset the
real owner's other credentials *before* the 401 was returned.

## Frontend testing

- [x] P9-04 Auth: tests for `auth_validation.dart` (no test file exists
      today), `signup_notifier.dart`, `login_notifier.dart`.
- [x] P9-05 Credential/settings notifiers with zero coverage today:
      `credentials_notifier`, `github_credentials_notifier`,
      `server_form_notifier`, `github_credential_form_notifier`,
      `test_connection_notifier`, `test_github_connection_notifier`.

      Found and fixed a real bug while testing: `GitHubCredentialFormNotifier
      .save()` never set a new `isDefault: true` credential as active,
      unlike `ServerFormNotifier`'s existing fix for the same gap on the
      Jenkins side.
- [x] P9-06 `jenkins_repository_impl.dart` methods with no isolated
      repository-level test (only exercised indirectly via notifier
      tests today): `fetchJobTree`, `fetchJobDetail`, `streamBuildLog`,
      `fetchJobHistory`, `fetchQueueItem` — success + failure cases against
      a fake `HttpClientAdapter`, matching the existing sibling test files'
      pattern.

      Found and fixed two real bugs while testing: `jenkins_url_rewriter`'s
      `Uri.replace(port: null)` doesn't clear a port (Dart treats `null` as
      "unchanged"), so a rewritten URL could keep a stale internal port when
      the active server URL had none; and `fetchQueueItem` never rewrote
      `executable.url` through the rewriter at all, unlike every other
      job/build URL (dormant today — nothing reads that field yet — but
      inconsistent with the rest of the codebase).
- [x] P9-07 DTOs with no test file: `credential_dto`, `github_credential_dto`,
      `user_dto`, `app_info_dto`, `jenkins_server_info_dto`,
      `health_report_dto`, `parameter_definition_dto`, `job_property_dto` —
      field-mapping + default-value tests matching `github_repo_dto_test.dart`'s
      style.
- [x] P9-08 Remaining untested notifiers: `job_search`,
      `folder_breadcrumb`, `job_tree`, `app_info`, `active_tool`,
      `github_repo_search`, `github_repos`, `github_workflows`,
      `job_history`, `global_history`, `test_report`, `trigger_build`,
      `job_detail`, `pending_input`, `pipeline_stages`, `cancel_build`,
      `artifact_download`, `input_submit`.

      **Flagged, not in scope here**: `integration_test/app_test.dart` is a
      theming/navigation smoke test only — no build-trigger/log/GitHub
      flow. Expanding it into real E2E coverage needs a live backend +
      Jenkins/GitHub Actions target per `NFR-TEST-02/03` and is a separate,
      larger initiative.

Frontend: 203 → 345 tests (142 new), `flutter analyze` clean throughout.
**Flagged, not fixed**: `ProviderContainer`'s default retry policy (Riverpod
v3.3.1+) retries a failed `AsyncNotifier.build()` with backoff instead of
settling into `AsyncError`, so the `container.listen(...); await
expectLater(provider.future, throwsA(...))` failure-path pattern used by
several existing tests can hang/slow-resolve unless `retry: (_, __) => null`
is passed to the container. New tests were written with the workaround where
needed; whether this affects already-committed tests using the same pattern
wasn't exhaustively audited.

## CD (dormant — build verification only, no signing/upload)

- [x] P9-09 New `.github/workflows/cd.yml`, `workflow_dispatch`-only
      trigger (no automatic `push`/`pull_request` — exists and is
      invokable from the Actions tab, never runs on its own): a
      `flutter-build` job (`flutter build apk --release`, `flutter build
      ipa --release --no-codesign` on `macos-latest`, artifacts uploaded
      via `actions/upload-artifact`, nothing external) and a
      `backend-docker-build` job against a **new** minimal
      `JobTrigger-Backend/Dockerfile` (none exists today —
      `docker-compose.yml` only runs MongoDB) — `docker build` only, no
      push, no registry. Update `docs/deployment.md`'s "Manual for now" row
      to reflect build-verification now existing.

## Dev tooling

- [x] P9-10 `.github/dependabot.yml`: `pub` (`JobTrigger-Frontend`), `npm`
      (`JobTrigger-Backend`), `github-actions` ecosystems, weekly. Native
      GitHub feature, zero new dependency.
- [x] P9-11 Codecov: `codecov/codecov-action@v4` step in both
      `flutter-ci.yml` (uploads `coverage/lcov.info` from P9-04..08's
      `flutter test --coverage`) and `nodejs-test.yml` (uploads P9-03's
      `c8` lcov output via a new `npm run test:coverage` call replacing the
      plain `npm test` step), each gated on a secret-backed `env:` var
      (`if: secrets.*` isn't valid in a step `if:` — routed through `env:`
      first) so CI stays green until the token secret exists.
- [x] P9-12 SonarCloud: `sonar-project.properties` at repo root (source
      paths for both subprojects, exclusions for generated
      `*.g.dart`/`*.freezed.dart`/`node_modules`), scan step
      (`SonarSource/sonarqube-scan-action@v5` — the current action;
      `sonarcloud-github-action` is deprecated) in `nodejs-test.yml`, gated
      the same way as Codecov above. **Scoped to the backend**: SonarCloud
      has no native Dart analyzer, so `JobTrigger-Frontend` is included in
      `sonar.sources` for basic size/duplication metrics only, not
      Dart-specific rules — flagged in the properties file's comments so
      this isn't oversold as full Flutter code-quality scanning. Analyzes
      this repo's own code quality — unrelated to the separate `SonarQube`
      user-story epic, which is about a user connecting *their own*
      SonarQube server inside the app.
      `sonar.projectKey`/`sonar.organization` are placeholders (`CHANGE_ME`)
      until a real SonarCloud project exists to fill them in with.

**Manual prerequisite for P9-11/P9-12** (can't be done from this
environment): create the Codecov and SonarCloud accounts/projects and add
`CODECOV_TOKEN`/`SONAR_TOKEN` as GitHub repo secrets. Both steps self-skip
until then.
