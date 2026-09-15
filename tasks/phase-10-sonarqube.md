# Phase 10 — SonarQube Integration (Epic SQ)

Goal: implement `docs/user-stories/sonarqube/14-sonarqube.md`'s SonarQube
support — a fourth credential type/tool alongside Jenkins, GitHub Actions,
and the still-docs-only GitLab CI, promoted out of `tasks/backlog.md`'s
deferred item on 2026-09-15 (decision: development starts with SonarQube,
ahead of GitLab CI and CircleCI, which remain docs-only for now).

This is structurally unlike every other CI-tool phase so far: SonarQube is
a code-quality server, not a build-trigger tool, so there is **no
SQ-RUN/SQ-LOG/SQ-HIST section at all** — no trigger, no cancel, no live
console log, no polling. Every task below is read-only. No Jenkins/GitHub
domain or data code is reused; only the routing shell, glass UI components,
the `Result`/`AppFailure` pattern, and Riverpod notifier conventions carry
over, same as epic GH. Endpoint paths/response shapes are verified against
SonarQube's real Web API docs (`docs.sonarsource.com`), not guessed — still
needs `NFR-TEST-03`-equivalent real-server verification before any task
here is marked done, same as Jenkins/GH needed.

Working order is dependency-driven: backend first (nothing client-side can
work without it), then credentials, then project browsing, then quality
gate/measures/issues last (the actual point of this integration, but it
needs an active credential and a project picked first). Each task needs a
plan/design checkpoint before its code lands, per `CLAUDE.md` §9 — same
cadence Phases 7/8 used. Also closes a real gap noticed while planning this
phase: none of the four "source of truth" docs (`docs/architecture.md`,
`docs/data-models.md`, `docs/api-reference.md`, `docs/state-management.md`)
were ever updated for GH's implementation — P10-00 brings the backend piece
of *this* phase into line with `CLAUDE.md` §2's stated standard instead of
repeating that gap; the docs are not retroactively fixed for GH here, that
would be unrelated scope creep for this phase.

## Backend

- [x] P10-00 New `JobTrigger-Backend` `SonarQubeCredential` Mongoose model
      (`models/SonarQubeCredential.js`) + controller
      (`controllers/sonarqubeCredentialsController.js`) + routes
      (`routes/sonarqubeCredentialRoutes.js`, mounted at
      `/api/sonarqube-credentials` in `server.js`) — mirrors
      `GitHubCredential`'s shape/behavior (get/add/update/delete + a
      `switch/:id` active-credential endpoint, same ownership checks, same
      "unset others' `isDefault` first" logic), fields per the epic doc:
      `label`, `baseUrl` (default `https://sonarcloud.io`), `token`,
      `defaultOrganization` (optional), `isDefault`. **Not** a modification
      to `JenkinsCredential`/`GitHubCredential` or their controllers — fully
      separate files, per the credential-architecture decision epic GH set.
      Built with Phase 9's ObjectId-validation/ValidationError-mapping/
      ownership-before-side-effect fixes from day one (`tasks/phase-9-testing-cicd-hardening.md`
      P9-01), not copying the bugs those controllers originally shipped
      with. New tests in `test/sonarqube_credentials.test.js` (mirroring
      `github_credentials.test.js`) plus SonarQube coverage added to the
      existing `test/credentials_validation.test.js` and
      `test/credentials_ownership.test.js`-equivalent checks, reusing those
      files' structure rather than new parallel ones. Also updates
      `docs/data-models.md` (new `## SonarQube Credential` entry) and
      `docs/api-reference.md` (five new `/api/sonarqube-credentials/*`
      rows) — see this file's intro for why.

## SQ-CRED — Credential management (client)

- [ ] P10-01 `data/models/credential/sonarqube_credential_dto.dart`,
      `domain/credential/sonarqube_credential.dart` — mirrors
      `github_credential.dart`'s shape (`id`, `label`, PAT renamed `secret`
      domain-side, `baseUrl`, `defaultOrganization`, `isDefault`),
      including the redacted `toString()`.
- [ ] P10-02 `SonarQubeCredentialsRepository` interface + impl — CRUD
      against P10-00's `/api/sonarqube-credentials` endpoints via
      `dioBackendProvider`, `Result<T, AppFailure>` throughout, mirrors
      `GitHubCredentialsRepositoryImpl` structurally.
- [ ] P10-03 `core/network/sonarqube_client_factory.dart` —
      `buildSonarQubeDio({baseUrl, token})` sets
      `Authorization: Bearer <token>` against the credential's own
      `baseUrl` (configurable per-credential, unlike GitHub's fixed
      `api.github.com` — closer to Jenkins' per-server client shape) +
      `testSonarQubeConnection()` hitting `GET {baseUrl}/api/authentication/validate`
      (US-SQ-CRED-04's dedicated validation endpoint, not a "fetch my
      user" pattern like the other three tools).
- [ ] P10-04 `SonarQubeCredentialsNotifier` (list, mirrors
      `GitHubCredentialsNotifier`) + `ActiveSonarQubeCredentialNotifier`
      (mirrors `ActiveGitHubCredentialNotifier` exactly — rehydrate,
      set, clear, delete-with-fallback), entirely independent state: its
      own provider, its own `SharedPreferences` key
      (`active_sonarqube_credential_id`), zero shared code (`NFR-SEC-03`,
      now four independent auth/active-state domains).
- [ ] P10-05 Settings UI: `SonarQubeCredentialFormNotifier` (mirrors
      `GitHubCredentialFormNotifier`, **including** the
      set-active-on-`isDefault` fix from `tasks/phase-9-testing-cicd-hardening.md`
      P9-05 from day one), `TestSonarQubeConnectionNotifier`,
      `SonarQubeCredentialEditBottomSheet` (mirrors
      `GitHubCredentialEditBottomSheet`, with `baseUrl`/`defaultOrganization`
      fields in place of GitHub's fields). `SettingsScreen` gets a new
      "SonarQube" section alongside Jenkins/GitHub's, via the existing
      shared `_credentialSlivers<T>` helper.
- [ ] P10-06 Unit tests for all of the above — repository CRUD, active-
      credential fallback logic, client factory header/base-URL
      construction, notifier state transitions — mirroring the exact test
      files GH's equivalent tasks produced (`github_credentials_repository_impl_test.dart`,
      `active_github_credential_notifier_test.dart`,
      `github_client_factory_test.dart`, etc.).

## SQ-PROJ — Project Browsing

- [ ] P10-07 `SonarQubeProject` domain type + DTO
      (`data/models/sonarqube/sonarqube_project_dto.dart`) — `key`, `name`,
      `lastAnalysisDate` (nullable — a project can exist with no analysis
      yet, per `US-SQ-PROJ-01`).
- [ ] P10-08 `SonarQubeRepository.fetchProjects()` — `GET api/projects/search`,
      optionally with `?organization=` when the active credential's
      `defaultOrganization` is set; surfaces a distinct message for a
      wrong/missing SonarCloud organization key (404) vs. a generic load
      failure, per `US-SQ-PROJ-01`'s flagged scenario.
- [ ] P10-09 `SonarQubeProjectScreen` — mirrors `GitHubRepoScreen`'s
      glass-card list/search/pull-to-refresh structure, gated on
      `activeSonarQubeCredentialNotifierProvider` via a new
      `NoActiveSonarQubeCredentialView`. This is the task that flips
      `CiTool.sonarqube.isAvailable` to `true` and wires the Home tab's
      tool-aware router switch (`app_router.dart`'s `_ToolAwareHomeScreen`)
      to render it when SonarQube is the active tool — the actual point at
      which this integration becomes reachable in the app, so treat this
      task's plan/design checkpoint with the same weight P8-11 (GH's
      equivalent routing task) got.

## SQ-QUALITY — Quality Gate, Measures, and Issues

- [ ] P10-10 `SonarQubeQualityGateStatus` domain type + DTO +
      `SonarQubeRepository.fetchQualityGateStatus(projectKey)` — `GET
      api/qualitygates/project_status`, including the per-condition
      breakdown (metric/comparator/threshold/actual value) for a failing
      gate, per `US-SQ-QUALITY-01`.
- [ ] P10-11 Measures grid — `SonarQubeRepository.fetchMeasures(projectKey)`
      (`GET api/measures/component` for coverage/bugs/vulnerabilities/
      code_smells/duplicated_lines_density/ncloc) + a glass-card stat-tile
      grid UI, per `US-SQ-QUALITY-02`.
- [ ] P10-12 Issues list — `SonarQubeRepository.fetchIssues(projectKey,
      {types, severities, page})` (`GET api/issues/search`, server-side
      filtered/paginated per `US-SQ-QUALITY-03`, not client-side like the
      project list) + a filterable list UI.
- [ ] P10-13 Analysis history (`Could` priority, do last) —
      `SonarQubeRepository.fetchAnalysisHistory(projectKey)` (`GET
      api/project_analyses/search`) + a simple timestamped list, per
      `US-SQ-QUALITY-04`.

## Cross-cutting

- [ ] P10-14 `NFR-SEC-03` verification: a live test confirming a SonarQube
      401 never triggers Jenkins/GitHub's auth handling or the backend's
      global logout, and vice versa — four independent auth failure
      domains, not two or three.
- [ ] P10-15 Full real-server verification pass: every SQ-CRED/PROJ/QUALITY
      task above manually verified against a real SonarCloud organization
      and a real self-hosted SonarQube Server instance (both flavors, per
      the epic's own scope note) before this phase is marked done.
