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

- [x] P10-01 `data/models/credential/sonarqube_credential_dto.dart`,
      `domain/credential/sonarqube_credential.dart` — mirrors
      `github_credential.dart`'s shape (`id`, `label`, PAT renamed `secret`
      domain-side, `baseUrl`, `defaultOrganization`, `isDefault`),
      including the redacted `toString()`.
- [x] P10-02 `SonarQubeCredentialsRepository` interface + impl — CRUD
      against P10-00's `/api/sonarqube-credentials` endpoints via
      `dioBackendProvider`, `Result<T, AppFailure>` throughout, mirrors
      `GitHubCredentialsRepositoryImpl` structurally.
- [x] P10-03 `core/network/sonarqube_client_factory.dart` —
      `buildSonarQubeDio({baseUrl, token})` sets
      `Authorization: Bearer <token>` against the credential's own
      `baseUrl` (configurable per-credential, unlike GitHub's fixed
      `api.github.com` — closer to Jenkins' per-server client shape) +
      `testSonarQubeConnection()` hitting `GET {baseUrl}/api/authentication/validate`
      (US-SQ-CRED-04's dedicated validation endpoint, not a "fetch my
      user" pattern like the other three tools). Returns `Result<void,
      AppFailure>` since the endpoint has nothing else to report.
- [x] P10-04 `SonarQubeCredentialsNotifier` (list, mirrors
      `GitHubCredentialsNotifier`) + `ActiveSonarQubeCredentialNotifier`
      (mirrors `ActiveGitHubCredentialNotifier` exactly — rehydrate,
      set, clear, delete-with-fallback), entirely independent state: its
      own provider, its own `SharedPreferences` key
      (`active_sonarqube_credential_id`), zero shared code (`NFR-SEC-03`,
      now four independent auth/active-state domains).
- [x] P10-05 Settings UI: `SonarQubeCredentialFormNotifier` (mirrors
      `GitHubCredentialFormNotifier`, **including** the
      set-active-on-`isDefault` fix from `tasks/phase-9-testing-cicd-hardening.md`
      P9-05 from day one), `TestSonarQubeConnectionNotifier` (state is
      `AsyncValue<bool?>`, not `<void>` -- a `void` state can't distinguish
      "never tested" from "tested successfully," both render as
      `AsyncData(null)`), `SonarQubeCredentialEditBottomSheet` (mirrors
      `GitHubCredentialEditBottomSheet`, with `baseUrl`/`defaultOrganization`
      fields in place of GitHub's fields). `SettingsScreen` gets a new
      "SonarQube" section alongside Jenkins/GitHub's, via the existing
      shared `_credentialSlivers<T>` helper -- `showJenkinsSection`'s
      condition had to change from a single negation to excluding both
      other tools.
- [x] P10-06 Unit tests for all of the above — repository CRUD, active-
      credential fallback logic, client factory header/base-URL
      construction, notifier state transitions, plus two new
      `settings_screen_test.dart` cases — mirroring the exact test files
      GH's equivalent tasks produced. 26 new tests, full suite now 371
      (was 345), `flutter analyze` clean throughout.

## SQ-PROJ — Project Browsing

- [x] P10-07 `SonarQubeProject` domain type + DTO
      (`data/models/sonarqube/sonarqube_project_dto.dart`) — `key`, `name`,
      `lastAnalysisDate` (nullable — a project can exist with no analysis
      yet, per `US-SQ-PROJ-01`).
      **Done 2026-11-08.** `domain/sonarqube/sonarqube_project.dart` +
      freezed DTO; a project name falls back to its key, and an unreadable
      `lastAnalysisDate` is "no date" rather than a crash.
- [x] P10-08 `SonarQubeRepository.fetchProjects()` — `GET api/projects/search`,
      optionally with `?organization=` when the active credential's
      `defaultOrganization` is set; surfaces a distinct message for a
      wrong/missing SonarCloud organization key (404) vs. a generic load
      failure, per `US-SQ-PROJ-01`'s flagged scenario.
      **Done 2026-11-08 (implemented and unit-tested; real-server check
      pending).** `SonarQubeRepositoryImpl.fetchProjects` sends
      `organization` only when the credential has a non-blank one, first
      page at `ps=500` (the API maximum). A 404 *with* an organization
      becomes the new `SonarQubeOrganizationNotFoundFailure` ("SonarCloud
      doesn't know that organization…"); without one it stays a plain
      not-found.
- [x] P10-09 `SonarQubeProjectScreen` — mirrors `GitHubRepoScreen`'s
      glass-card list/search/pull-to-refresh structure, gated on
      `activeSonarQubeCredentialNotifierProvider` via a new
      `NoActiveSonarQubeCredentialView`. This is the task that flips
      `CiTool.sonarqube.isAvailable` to `true` and wires the Home tab's
      tool-aware router switch (`app_router.dart`'s `_ToolAwareHomeScreen`)
      to render it when SonarQube is the active tool — the actual point at
      which this integration becomes reachable in the app, so treat this
      task's plan/design checkpoint with the same weight P8-11 (GH's
      equivalent routing task) got.

      **Done 2026-11-08.** `SonarQubeProjectScreen` (account label,
      search by name or key, glass cards with key and "Analyzed 3h ago" /
      "Never analyzed", pull-to-refresh, empty and error-with-retry states),
      gated by `NoActiveSonarQubeCredentialView`. `CiTool.sonarqube` is now
      available and the Home tab routes to it. The History tab shows an
      explicit "SonarQube has no run history" message instead of falling
      through to Jenkins' history. Project cards are inert until the
      quality screens (P10-10..12).
## SQ-QUALITY — Quality Gate, Measures, and Issues

- [x] P10-10 `SonarQubeQualityGateStatus` domain type + DTO +
      `SonarQubeRepository.fetchQualityGateStatus(projectKey)` — `GET
      api/qualitygates/project_status`, including the per-condition
      breakdown (metric/comparator/threshold/actual value) for a failing
      gate, per `US-SQ-QUALITY-01`.
      **Done 2026-11-08 (implemented and unit-tested; real-server check
      pending).** `SonarQubeQualityGate` (passed / warning / failed / none;
      anything unrecognised is "none", never a guessed pass) with its
      conditions. Only failing conditions are listed, each as "Coverage on
      new code: 62.1%" plus "Fails when below 80%" (SonarQube's comparator
      is the failure direction, so LT reads "below"). A never-analysed
      project says "Not yet analyzed".
- [x] P10-11 Measures grid — `SonarQubeRepository.fetchMeasures(projectKey)`
      (`GET api/measures/component` for coverage/bugs/vulnerabilities/
      code_smells/duplicated_lines_density/ncloc) + a glass-card stat-tile
      grid UI, per `US-SQ-QUALITY-02`.
      **Done 2026-11-08 (implemented and unit-tested; real-server check
      pending).** Six measures in a glass-card grid on
      `SonarQubeProjectDetailScreen` (opened by tapping a project). A metric
      the server didn't compute shows "—", not 0. Percentages keep one
      decimal, counts get separators, ratings become A–E
      (`domain/sonarqube/sonarqube_metrics.dart`). Gate and measures load
      and fail independently, each with its own retry. The gate and measures
      calls send no `organization`: a project key is unique and neither
      endpoint documents the parameter.
- [x] P10-12 Issues list — `SonarQubeRepository.fetchIssues(projectKey,
      {types, severities, page})` (`GET api/issues/search`, server-side
      filtered/paginated per `US-SQ-QUALITY-03`, not client-side like the
      project list) + a filterable list UI.
      **Done 2026-11-08 (implemented and unit-tested; real-server check
      pending).** `fetchIssues` sends `componentKeys`, `resolved=false`,
      `ps=50`, `p`, and `types`/`severities` from the filter, in display
      order. `SonarQubeIssuesScreen`: type and severity filter chips (each
      change re-queries from page one), a total count, rows with type icon,
      message, `file:line` and a severity pill (words, not only colour),
      load-more on scroll, and a retry that keeps the loaded list on a failed
      page. Two empty states: "No issues found" vs "No issues match these
      filters". SonarQube refuses to page past 10,000 results, so paging
      stops there with a note to narrow the filters. Reached from the new
      Issues row on the project detail screen.
- [x] P10-13 Analysis history (`Could` priority, do last) —
      `SonarQubeRepository.fetchAnalysisHistory(projectKey)` (`GET
      api/project_analyses/search`) + a simple timestamped list, per
      `US-SQ-QUALITY-04`.

      **Done 2026-11-08 (implemented and unit-tested; real-server check
      pending).** `fetchAnalysisHistory` (latest 50, sorted newest first,
      undated last). `SonarQubeAnalysisScreen` is a timestamped list with
      "2h ago" and the project version when the build set one. A single
      analysis shows "Not enough history yet", and none shows "has not been
      analyzed yet", rather than a bare list. Rows open nothing: an analysis
      is a snapshot, not a run. Reached from a new Analysis history row on
      the project detail screen.
## Cross-cutting

- [ ] P10-14 `NFR-SEC-03` verification: a live test confirming a SonarQube
      401 never triggers Jenkins/GitHub's auth handling or the backend's
      global logout, and vice versa — four independent auth failure
      domains, not two or three.
      **Partly done 2026-11-08 (left unchecked).** Automated evidence in
      `test/core/network/sonarqube_auth_isolation_test.dart` (real client
      factories, scripted adapters): a SonarQube 401 is only an
      `AuthFailure` (no `SessionSignal`, backend tokens kept); a 403 is a
      permission failure, not an auth one; the backend losing its session
      leaves the SonarQube, GitHub and Jenkins clients working with their own
      credentials; the SonarQube client never carries the backend token.
      Still open: the live check against a real SonarQube, which needs a real
      server and token.
- [x] P10-16 **Fixes and improvements after the owner's local-server test
      (2026-11-08).** The owner tested every SonarQube screen against a local
      server. Four changes, none touching Jenkins or GitHub behaviour:
      - **Project list endpoint.** `api/projects/search` needs administrator
        rights (stated by SonarQube's docs; not confirmed against the
        owner's server). The list now uses `api/components/search_projects`,
        which needs only Browse access and is what SonarQube's own Projects
        page calls. A server without it (404 or 400) falls back to the old
        call, so a setup that worked keeps working. A 403 is final.
      - **Connection test also lists one project,** so a token that is valid
        but whose user can't browse is caught when adding the credential.
      - **More than 500 projects.** The list pages (`p`), shows "Showing N of
        M projects" with a Load more button, loads more on scroll, and says
        when a search only covers the loaded projects.
      - **SonarQube wording.** New `SonarQubeAccessDeniedFailure` (403) and
        `SonarQubeProjectNotFoundFailure` (404 on a project) replace the
        generic "You don't have permission to do this on this server" for
        SonarQube only; the shared failures' text is unchanged (guarded by
        `test/core/error/shared_failure_copy_test.dart`).
      Existing tests were only changed where behaviour changed on purpose:
      the project list's return type, its endpoint path, and the two 403 and
      one project-404 expectations. Not verified against a real server:
      `search_projects`'s response shape comes from SonarQube's documentation.
- [x] P10-17 **SonarQube polish after the second owner test (2026-11-08):**
      five fixes and the features the owner approved (US-SQ-PROJ-03,
      US-SQ-OVERVIEW-01, US-SQ-QUALITY-05/06, US-SQ-LINK-01). Jenkins is
      untouched; GitHub gets only the first-open fix below.
      - **First-open flash.** The active credential is null while the saved
        list loads, so "No credential" showed until Settings reloaded it. A
        shared `CredentialLoadGate` (spinner while loading, the error with a
        retry, "no credential" only when the list is empty) is used on the
        SonarQube **and GitHub** Home screens: the same fix Jenkins got in
        P19-02.
      - **"Never analyzed".** The owner's server returns no `analysisDate`
        from `search_projects` unless `f=analysisDate` is sent (seen in a
        real reply). It is now sent, and a project still without a date
        looks up its newest analysis first.
      - **History tab.** SonarQube's second tab is an Overview (counts, totals,
        projects needing attention). `MainScaffold` got an optional
        `overviewTab` flag, off by default, set by the router; Jenkins and
        GitHub keep "History", proved through the real router.
      - **Cards.** The uneven tiles came from the shared card shrinking to its
        content; tiles now fill their width. Project cards show the gate
        verdict and numbers (one `api/measures/search` call per 100
        projects), with sort and a failing-only filter.
      - **Project page.** Redesigned: ratings, technical debt, gate-failed
        measures marked, last-analysed header, Explore card, Open in
        SonarQube. **Issue page:** rule, facts, and the code around it.
      Found by the tests along the way and fixed: a summaries notifier that
      could be disposed while its request ran, a provider modified during
      its own build, and a stray `#` on every link.
      Not verified on a real server: `api/measures/search`,
      `api/sources/show` (response shape) and `api/rules/show` follow
      SonarQube's documentation; the owner's iPhone test is the check.
- [ ] P10-15 Full real-server verification pass: every SQ-CRED/PROJ/QUALITY
      task above manually verified against a real SonarCloud organization
      and a real self-hosted SonarQube Server instance (both flavors, per
      the epic's own scope note) before this phase is marked done.

## Planned batches (documented 2026-11-09, none started)

Listed for the owner on 2026-11-08 and written up as user stories on
2026-11-09 under "Planned work" in
`docs/user-stories/sonarqube/14-sonarqube.md`. One task per batch. **None
starts until the owner picks it and approves its plan** (`CLAUDE.md` §9).
Suggested order: P10-18, then P10-19, then as picked. Every batch ends with
the whole suite run (`CLAUDE.md` §11) and an iPhone test by the owner.

- [ ] P10-18 **Batch 1: understand why a gate fails, and what is mine.**
      `US-SQ-ISSUES-01` (my issues across projects), `US-SQ-CE-01`
      (analysis running, queued or failed), `US-SQ-QUALITY-07` (all gate
      conditions), `US-SQ-QUALITY-08` (new code vs overall; **check how the
      owner's server reports new-code values first**),
      `US-SQ-QUALITY-09` (compare with the previous analysis). Read-only.
- [ ] P10-19 **Batch 2: alerts.** `US-SQ-WATCH-01` (notify when a watched
      project fails its gate). Local notifications and a best-effort
      background check, reusing the Jenkins watch; no new dependency. Only
      verifiable on a real device with a real analysis.
- [ ] P10-20 **Batch 3: deeper project views.** `US-SQ-QUALITY-10` (branch
      and pull request picker; **edition-dependent, hidden when the server
      lists only the main branch**), `US-SQ-HOTSPOT-01`,
      `US-SQ-QUALITY-11` (trends; **needs a decision on the chart: custom
      painter or a flagged dependency**), `US-SQ-QUALITY-12`,
      `US-SQ-QUALITY-13`, `US-SQ-ISSUES-02`. Read-only; any can be taken
      alone.
- [ ] P10-21 **Batch 4: across projects and the server.**
      `US-SQ-ISSUES-03` (search issues), `US-SQ-SERVER-01` (version and
      status), `US-SQ-OVERVIEW-02` (failing-projects trend, from the app's
      own device-side snapshots). Read-only.
- [ ] P10-22 **Batch 5: shortcuts and offline.** `US-SQ-PIN-01` (local pins),
      `US-SQ-WIDGET-01` (home-screen widget; native work on both platforms,
      device-only check), `US-SQ-OFFLINE-01`, `US-SQ-LINK-02` (deep links),
      `US-SQ-ISSUES-04` (copy and share). Reuses plumbing from Phase 11.
- [ ] P10-23 **Batch 6: connecting the tools.** `US-SQ-XTOOL-01..03`
      (Jenkins build or GitHub run beside the SonarQube gate; scan from
      Jenkins). **Edits Jenkins and GitHub screens**, so it needs the
      owner's explicit go-ahead and the diff shown first; Jenkins is frozen
      except for bug fixes. The link between a job or repo and a project is
      stored on the device only; credentials are never shared between tools.
- [ ] P10-24 **Batch 7: changing data on the server.** `US-SQ-WRITE-01..04`
      (assign, change status, comment, review a hotspot). **The first writes
      in this epic**, so it is last and needs its own approval; needs a token
      whose user may modify issues; every action confirms and nothing changes
      on screen before the server answers.

