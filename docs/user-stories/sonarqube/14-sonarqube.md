# Epic: SQ — SonarQube Integration

Promoted out of `10-out-of-scope-backlog.md`'s `BACKLOG-01`, filling in the
`CiTool.sonarqube` card that's existed as a disabled placeholder since
`ToolSelectionScreen` was built (`US-TOOL-02`). This is a **BA deliverable,
not an implementation plan** (per `CLAUDE.md` §9 and this story set's own
README): no code lands against this epic, no `CiTool.isAvailable` flip,
until it's separately promoted into an active phase the way GitHub Actions
was on 2026-09-14.

Endpoint paths and response shapes below are verified against SonarQube's
real Web API docs (`docs.sonarsource.com`, the stable `api/*` endpoints
also documented in-product under each instance's own Help menu) before
writing these stories, not guessed — same discipline epic GH used.

**Naming clarity, stated once up front**: this epic is about a user
connecting *their own* SonarQube server (or a SonarCloud organization) as a
monitored tool inside the app. It is unrelated to this repository's own
SonarCloud CI integration (`tasks/phase-9-testing-cicd-hardening.md` P9-12,
`sonar-project.properties`) — that's this project's own code-quality
tooling, a completely different concern from the product surface below.

## Why this epic's shape is fundamentally different from Jenkins/GitHub/GitLab

**SonarQube is not a build-trigger tool — it's a code-quality server that
other CI systems push analysis results to.** There is no "run," no
"trigger," no "cancel," no live console log, because SonarQube itself never
executes a build. A project's quality data only changes when some *other*
CI job (Jenkins, GitHub Actions, GitLab CI, a local `sonar-scanner` run)
pushes a new analysis to it. This has real, structural consequences for
every sub-epic below:

- **No SQ-RUN, no SQ-LOG, no SQ-HIST epics at all** — there's nothing to
  trigger, nothing to stream, and "history" here means *past analyses of
  the same project*, not past *builds*, folded into `SQ-QUALITY` rather
  than warranting its own epic the way build/run history does for the
  other three tools.
- **No live polling story.** `US-JOB-04`/`US-GL-RUN-03`'s 5-second
  build-status polling has no equivalent here — quality data is refreshed
  manually (pull-to-refresh), not on a timer, because there's no
  in-progress state to poll for.
- **Read-only, full stop.** Every story below is a `GET`. This is the
  first CI-tool epic in this app with zero mutating (`POST`/write) API
  calls.
  *(Note, 2026-11-09: true of everything built so far. Batch 7 under
  "Planned work" proposes this epic's first writes, with its own explicit
  approval; it is not started.)*

**Auth**: SonarQube's Web API uses `Authorization: Bearer <token>` — the
same header shape as GitHub, but a different *kind* of token (a SonarQube
User Token, generated in-product under My Account → Security, not a
platform-wide PAT with scopes).

**SonarCloud vs. self-hosted SonarQube Server**: both speak the same Web
API, but SonarCloud additionally requires an **organization key** in most
list/search calls (`api/projects/search?organization=...`), a concept
self-hosted SonarQube Server doesn't have at all. The credential model
below treats organization as optional specifically to cover both flavors
with one field, the same way `defaultOwner`/`defaultNamespace` are optional
on the GitHub/GitLab credentials.

---

## Epic SQ-CRED — SonarQube Credential Management

Mirrors `03-credential-management.md`'s shape for a fourth credential type.
Backend: a new `SonarQubeCredential` Mongoose model/controller/routes in
`JobTrigger-Backend`, same `userId`-scoped ownership pattern as the other
three — fields: `label`, `baseUrl` (default `https://sonarcloud.io`,
editable for self-hosted instances), `token` (the User Token),
`defaultOrganization` (optional — required in practice for SonarCloud,
meaningless for self-hosted Server), `isDefault`. **Not** a modification to
any existing credential model/controller — a fully separate parallel type.

### US-SQ-CRED-01 — Add a SonarQube credential

**Priority:** Must
**Source:** new — SonarQube initiative
**Dependencies:** none

As a user
I want to add a SonarQube server URL and User Token, with an optional
organization key
So that the app can show me my projects' quality status

**Acceptance Criteria**
- [x] Scenario: Successful add against SonarCloud
  Given I leave the instance URL at its `https://sonarcloud.io` default,
  enter a label, the token, and an organization key, and tap Save
  Then the credential is created via the new backend endpoint and appears
  in the SonarQube server list
  Evidence: `test/presentation/features/settings/sonarqube_credential_form_notifier_test.dart` "adding a credential refreshes the credentials list on success"; `test/data/repositories/sonarqube_credentials_repository_impl_test.dart` "add posts label/baseUrl/token/defaultOrganization/isDefault".
- [x] Scenario: Successful add against a self-hosted SonarQube Server
  Given I change the instance URL to `https://sonar.example.com` and leave
  the organization field empty
  Then the credential saves without requiring an organization — self-hosted
  Server has no such concept
  Evidence: `test/data/repositories/sonarqube_repository_impl_test.dart` "sends the organization on SonarCloud and none on self-hosted"; the organization is optional in the form and the API.
- [ ] Scenario: Token validation
  Given the token field is empty
  Then client-side validation blocks submission with an inline message,
  before any network call (`NFR-SEC-02`)
  Open: not built: the form checks the URL but not the token's shape before saving; only Test connection reveals a bad token.
- [x] Scenario: Instance URL validation
  Given the instance URL field is empty or not a well-formed URL
  Then client-side validation blocks submission with an inline message
  Evidence: `test/domain/credential/sonarqube_url_test.dart` "accepts SonarCloud and a self-hosted server", "names what is wrong"; `test/presentation/features/settings/sonarqube_credential_form_notifier_test.dart` "an unusable URL never reaches the backend".
- [x] Scenario: Save fails
  Given the backend request fails
  Then an `AppFailure`-mapped message is shown and the form retains
  entered values
  Evidence: `test/presentation/features/settings/sonarqube_credential_form_notifier_test.dart` "a repository failure surfaces as SonarQubeCredentialFormNotifier state error"; the shared EditSheet keeps typed values (proven for Jenkins in `test/presentation/features/settings/jenkins_server_list_test.dart`).

**Security & Privacy Notes**
- The token is never logged; `SonarQubeCredential`'s domain-side
  `toString()` is redacted, mirroring every other credential type.
- Whether tokens are encrypted at rest is a backend concern, documented not
  assumed — same flagged risk as every other credential type (`NFR-SEC-01`).

**UI / Design Notes**
- References `US-DESIGN-*` for the glass-card form treatment; mirrors
  `GitHubCredentialEditBottomSheet`'s wide/narrow split, with instance-URL
  and organization fields in place of GitHub's fields.

**Non-Functional Notes**
- `NFR-SEC-02` (client-side validation before any network call).

### US-SQ-CRED-02 — Edit / delete a SonarQube credential

**Priority:** Must
**Source:** new — SonarQube initiative
**Dependencies:** US-SQ-CRED-01

As a user
I want to edit or remove a saved SonarQube credential
So that I can rotate a token or drop a server I no longer monitor

**Acceptance Criteria**
- [x] Scenario: Edit updates label/URL/token/organization
  Given I open an existing credential's edit sheet
  Then the token field is never pre-filled (`NFR-SEC-01`'s redaction
  mechanism), with "leave blank to keep the current token" copy
  Evidence: `test/presentation/features/settings/sonarqube_credential_form_notifier_test.dart` "editing a credential calls repository.update with the given id"; the token field starts empty with "Leave blank to keep the current token" (`sonarqube_credential_edit_bottom_sheet.dart`); unreadable tokens must be re-entered: `test/presentation/features/settings/secret_reentry_test.dart` "the SonarQube edit sheet asks for the token again".
- [ ] Scenario: Delete with confirmation
  Given I swipe-delete a credential
  Then a confirmation dialog appears before the backend delete call fires
  Open: not proven for SonarQube rows: they share `_confirmDelete` and (since 2026-11-21) the delete-inside-confirm flow with Jenkins rows (`settings_screen.dart`), tested only for Jenkins.
- [x] Scenario: Deleting the active credential falls back
  Given the deleted credential was the active one
  Then another `isDefault`/first-remaining credential becomes active, or
  the active-credential state clears if none remain, mirroring
  `ActiveGitHubCredentialNotifier.deleteCredential`'s exact fallback logic
  Evidence: `test/data/credentials/active_sonarqube_credential_notifier_test.dart` "deleting the active credential falls back to the remaining isDefault credential", "deleting the only credential clears the active credential".

**Security & Privacy Notes**
- Ownership check (`userId` match) enforced backend-side on every
  update/delete.

**UI / Design Notes**
- References `US-DESIGN-*`.

**Non-Functional Notes**
- None beyond `NFR-SEC-*` above.

### US-SQ-CRED-03 — Switch the active SonarQube credential

**Priority:** Must
**Source:** new — SonarQube initiative
**Dependencies:** US-SQ-CRED-01

As a user
I want to switch which saved SonarQube credential is active
So that I can check a different server or organization

**Acceptance Criteria**
- [x] Scenario: Switching updates the active credential immediately
  Given I tap a non-active credential's radio indicator in the SonarQube
  section of Settings
  Then it becomes active and the project list (`US-SQ-PROJ-01`) refetches
  against it
  Evidence: `test/presentation/features/sonarqube/sonarqube_overview_test.dart` "the credential chip drops down the saved credentials and switches in place"; Fixed 2026-11-21: the first credential saved now becomes active (`test/data/credentials/first_credential_active_test.dart`).
- [x] Scenario: Independent from every other tool's active state
  Given Jenkins/GitHub/GitLab credentials are also configured
  Then switching the active SonarQube credential does not touch any of
  their active-selection state (`NFR-SEC-03`, now covering four
  independent auth/active-state domains)
  Evidence: Fixed 2026-11-21: test added: `test/data/credentials/active_tools_independent_test.dart` "switching SonarQube credentials leaves Jenkins and GitHub alone"; `test/core/network/sonarqube_auth_isolation_test.dart` "the SonarQube client carries neither the backend token nor another tool's".

**Security & Privacy Notes**
- References `NFR-SEC-03`.

**UI / Design Notes**
- References `US-DESIGN-*`; mirrors the existing settings sections'
  radio-indicator + switch-active-toast pattern.

**Non-Functional Notes**
- None beyond `NFR-SEC-03`.

### US-SQ-CRED-04 — Test a SonarQube connection

**Priority:** Should
**Source:** new — SonarQube initiative
**Dependencies:** US-SQ-CRED-01

As a user
I want to verify a SonarQube credential actually works before relying on it
So that I catch a bad token or wrong instance URL early

**Acceptance Criteria**
- [ ] Scenario: Successful test
  Given a valid instance URL and token
  When I tap "Test Connection"
  Then `GET {baseUrl}/api/authentication/validate` is called (SonarQube's
  own dedicated token-validation endpoint — returns `{valid: true/false}`,
  a genuinely different shape from Jenkins/GitHub/GitLab's "fetch my user"
  pattern, since this endpoint exists specifically for this purpose) and a
  success state is shown when `valid: true`
  Open: built differently on purpose: Test connection lists one project (`test/data/repositories/sonarqube_repository_impl_test.dart` "succeeds when one project can be listed, asking for just one") instead of `api/authentication/validate`, because a valid token can still be unable to browse ("a valid token whose user may not browse says so"). Needs rewording.
- [x] Scenario: Failed test
  Given `valid: false`, an invalid token, or an unreachable instance URL
  Then a clear `AppFailure`-mapped message is shown, and save remains
  allowed regardless (this is a nudge, not a gate)
  Evidence: `test/data/repositories/sonarqube_repository_impl_test.dart` "a valid token whose user may not browse says so"; `test/presentation/features/settings/test_sonarqube_connection_notifier_test.dart` "an unusable URL fails before any request"; saving never depends on a test.

**Security & Privacy Notes**
- None beyond the token-redaction notes above.

**UI / Design Notes**
- References `US-DESIGN-*`.

**Non-Functional Notes**
- None.

---

## Epic SQ-PROJ — Project Browsing

### US-SQ-PROJ-01 — Browse my SonarQube projects

**Priority:** Must
**Source:** new — SonarQube initiative
**Dependencies:** US-SQ-CRED-03 (an active credential must exist)

As a user
I want to see a flat, searchable list of my SonarQube projects
So that I can find the one I want to check the quality status of

**Acceptance Criteria**
- [x] Scenario: Successful load against SonarCloud
  Given an active SonarCloud credential with an organization set
  Then `GET api/components/search_projects?organization=...` is called (any
  user with Browse access may; `api/projects/search` is administrator-only and
  is used only as a fallback for a server that lacks it) and the
  project list renders — `key`, `name`, `lastAnalysisDate`
  Evidence: `test/data/repositories/sonarqube_repository_impl_test.dart` "uses search_projects, reads analysisDate and the paging total", "sends the organization on SonarCloud and none on self-hosted"; `test/presentation/features/sonarqube/sonarqube_project_screen_test.dart` "lists projects with key and last analysis".
- [x] Scenario: Successful load against self-hosted Server
  Given an active self-hosted credential with no organization set
  Then `GET api/components/search_projects` is called without the `organization`
  param
  Evidence: `test/data/repositories/sonarqube_repository_impl_test.dart` "sends the organization on SonarCloud and none on self-hosted".
- [x] Scenario: No active credential
  Given no SonarQube credential is active
  Then a `NoActiveSonarQubeCredentialView` gates the screen, mirroring
  `NoActiveGitHubCredentialView`/`NoActiveServerView`
  Evidence: `test/presentation/features/sonarqube/sonarqube_project_screen_test.dart` "with no credential, it asks for one instead of fetching".
- [x] Scenario: A project with no analysis yet
  Given a project whose `lastAnalysisDate` is absent (created but never
  scanned)
  Then it's shown with an explicit "Not analyzed yet" state rather than a
  blank or misleading quality indicator
  Evidence: `test/data/repositories/sonarqube_repository_impl_test.dart` "parses projects, including one that was never analysed"; `test/presentation/features/sonarqube/sonarqube_project_screen_test.dart` "a failed lookup says it is unknown, not "never analyzed"".
- [x] Scenario: Client-side search
  Given I type into the search field
  Then the list filters by `name`, case-insensitive, client-side, no
  per-keystroke network call (`NFR-PERF-02`)
  Evidence: `test/presentation/features/sonarqube/sonarqube_project_screen_test.dart` "search matches name or key, and says when nothing matches".
- [x] Scenario: Load fails
  Given the request fails (including a missing/wrong organization key for
  SonarCloud, which 404s rather than returning an empty list)
  Then an `AppFailure`-mapped error view with retry is shown, with the
  organization-key case surfacing a message distinct enough from a generic
  404 that the user knows to check their credential's organization field
  Evidence: `test/presentation/features/sonarqube/sonarqube_project_screen_test.dart` "a wrong SonarCloud organization is explained, with retry"; `test/data/repositories/sonarqube_repository_impl_test.dart` "a 404 with an organization is a wrong organization key".

**UI / Design Notes**
- References `US-DESIGN-*`; mirrors `GitHubRepoScreen`'s glass-card
  list/search/pull-to-refresh structure. Each tile shows a compact quality
  gate badge (`US-SQ-QUALITY-01`'s data) so the list itself is useful at a
  glance, not just a picker.

**Non-Functional Notes**
- `NFR-PERF-02` (client-side search, no per-keystroke network call).

---

### US-SQ-PROJ-03 — See each project's health in the list

**Priority:** Should
**Source:** owner's local-server test, 2026-11-08
**Dependencies:** US-SQ-PROJ-01

As a user
I want each project card to show its quality-gate verdict and headline
numbers, and to sort and filter the list by them
So that I can find what needs attention without opening every project

**Acceptance Criteria**
- [x] Scenario: Card numbers
  Given the project list has loaded
  Then each card shows its gate verdict (Passed / Failed / Warning / Not
  analyzed) and its bugs, vulnerabilities, code smells and coverage, loaded
  with one `GET api/measures/search` request per 100 projects, never one per
  project. A figure the server did not compute is "—", not 0
  Evidence: `test/presentation/features/sonarqube/sonarqube_project_cards_test.dart` "each card shows its gate verdict and headline numbers", "the numbers are loaded once for every project, in one go".
- [x] Scenario: Sort and filter
  Given the list is shown
  Then it can be sorted by name, last analysed or quality gate (failing
  first), and narrowed to projects whose gate failed or warns
  Evidence: `test/presentation/features/sonarqube/sonarqube_project_cards_test.dart` "sorting by quality gate puts failing projects first", "sorting by last analysed puts the newest first, undated last", ""Failing only" keeps just the failed and warning projects".
- [x] Scenario: The numbers cannot be loaded
  Given that request fails
  Then the list still works, without the badges, and nothing is called
  passing
  Evidence: `test/presentation/features/sonarqube/sonarqube_project_cards_test.dart` "if the numbers cannot be loaded the list still works".
- [x] Scenario: Last analysed
  Given `api/components/search_projects` leaves the date out unless asked
  Then the list asks for `f=analysisDate`, and a project still without a date
  looks up its newest analysis before being called "Never analyzed"
  Evidence: `test/data/repositories/sonarqube_repository_impl_test.dart` "asks search_projects for the analysis date, and only that call"; `test/presentation/features/sonarqube/sonarqube_project_screen_test.dart` "is taken from the analysis history, not called "never"", "a project that has a date does not ask for the history".

## Epic SQ-QUALITY — Quality Gate, Measures, and Issues

The core of this integration — everything a user actually wants to know
about a project's code health.

### US-SQ-QUALITY-01 — View a project's quality gate status

**Priority:** Must
**Source:** new — SonarQube initiative
**Dependencies:** US-SQ-PROJ-01

As a user
I want to see whether a project is passing or failing its quality gate
So that I know at a glance if it's in a healthy state

**Acceptance Criteria**
- [x] Scenario: Passing gate
  Given I open a project
  Then `GET api/qualitygates/project_status?projectKey=...` is called and
  a clear "Passed" state renders when `projectStatus.status == "OK"`
  Evidence: `test/presentation/features/sonarqube/sonarqube_project_detail_screen_test.dart` "a passing gate and its measures, with a dash for a metric the server did not compute".
- [x] Scenario: Failing gate, with the specific reasons
  Given `projectStatus.status == "ERROR"`
  Then each failing condition in `projectStatus.conditions[]` is listed
  with its metric, comparator, threshold, and actual value — not just a
  generic "failed" badge
  Evidence: `test/presentation/features/sonarqube/sonarqube_project_detail_screen_test.dart` "a failing gate says what failed and why"; `test/data/repositories/sonarqube_repository_impl_test.dart` "a failing gate lists its conditions".
- [x] Scenario: No quality gate result yet
  Given `projectStatus.status == "NONE"` (no analysis yet)
  Then an explicit "not yet analyzed" state is shown, consistent with
  `US-SQ-PROJ-01`'s list-level version of the same state
  Evidence: `test/presentation/features/sonarqube/sonarqube_project_detail_screen_test.dart` "a project never analysed says so instead of passing"; `test/data/repositories/sonarqube_repository_impl_test.dart` "a project never analysed has no verdict".
- [x] Scenario: Load fails
  Given the request fails
  Then an `AppFailure`-mapped error view with retry is shown
  Evidence: `test/presentation/features/sonarqube/sonarqube_project_detail_screen_test.dart` "a gate failure shows its error with retry".

**UI / Design Notes**
- References `US-DESIGN-*`; a glass-card status header, mirroring the
  weight `StatusIndicator` gives build/pipeline status elsewhere in the
  app — this is this tool's equivalent "at a glance" signal.

**Non-Functional Notes**
- None beyond standard `AppFailure` mapping.

### US-SQ-QUALITY-02 — View key measures

**Priority:** Must
**Source:** new — SonarQube initiative
**Dependencies:** US-SQ-QUALITY-01

As a user
I want to see a project's coverage, bugs, vulnerabilities, code smells, and
duplication metrics
So that I understand its quality beyond a single pass/fail signal

**Acceptance Criteria**
- [x] Scenario: Successful load
  Given I view a project's quality tab
  Then `GET api/measures/component?component=...&metricKeys=coverage,
  bugs,vulnerabilities,code_smells,duplicated_lines_density,ncloc` is
  called and each requested metric renders with its value and a
  human-readable label/unit (percentage for coverage/duplication, raw
  count for bugs/vulnerabilities/code smells, lines of code for `ncloc`)
  Evidence: `test/data/repositories/sonarqube_repository_impl_test.dart` "asks for the six measures and omits uncomputed ones"; `test/presentation/features/sonarqube/sonarqube_project_page_test.dart` "the six measure tiles are equal in size (the old ones were not)".
- [x] Scenario: A metric with no computed value
  Given a metric absent from the response (e.g. a language-specific metric
  that doesn't apply to this project)
  Then that metric's tile shows "—" rather than a zero, which would
  misleadingly imply a fully-verified perfect score
  Evidence: `test/presentation/features/sonarqube/sonarqube_project_detail_screen_test.dart` "a passing gate and its measures, with a dash for a metric the server did not compute".
- [x] Scenario: Load fails
  Given the request fails
  Then an `AppFailure`-mapped error view with retry is shown
  Evidence: `test/presentation/features/sonarqube/sonarqube_project_detail_screen_test.dart` "a measures failure does not hide the gate, and retries alone".

**UI / Design Notes**
- References `US-DESIGN-*`; a metrics grid of glass-card tiles, one per
  metric, matching this app's existing stat-tile visual language.

**Non-Functional Notes**
- None beyond standard `AppFailure` mapping.

### US-SQ-QUALITY-03 — Browse a project's issues

**Priority:** Should
**Source:** new — SonarQube initiative
**Dependencies:** US-SQ-QUALITY-01

As a user
I want to see the individual bugs, vulnerabilities, and code smells raised
against a project
So that I know specifically what needs fixing, not just an aggregate count

**Acceptance Criteria**
- [x] Scenario: Successful load
  Given I open a project's issues list
  Then `GET api/issues/search?componentKeys=...` is called and each
  issue's `type` (`BUG`/`VULNERABILITY`/`CODE_SMELL`), `severity`,
  `message`, and file/line location render
  Evidence: `test/presentation/features/sonarqube/sonarqube_issues_test.dart` "lists issues with type, severity and location"; `test/data/repositories/sonarqube_repository_impl_test.dart` "filters and pages on the server and trims the project prefix".
- [x] Scenario: Filter by type/severity
  Given I select a type or severity filter
  Then the request is re-issued with `types`/`severities` query params
  (server-side filtering, not client-side — this list can be large enough
  that client-side filtering over an unbounded fetch isn't appropriate,
  unlike the project-list search in `US-SQ-PROJ-01`)
  Evidence: `test/presentation/features/sonarqube/sonarqube_issues_test.dart` "changing the filter re-queries from page one on the server", "a filter chip narrows the list and Clear filters undoes it".
- [x] Scenario: Pagination
  Given more issues exist than one page (`api/issues/search`'s default
  page size)
  Then a "load more" affordance fetches subsequent pages via `p`/`ps`
  params, same pagination pattern as `US-GL-PROJ-01`
  Evidence: `test/presentation/features/sonarqube/sonarqube_issues_test.dart` "loads page one, then appends the next, then stops", "paging stops at the 10,000-result limit".
- [x] Scenario: No issues
  Given a clean project
  Then an explicit "No issues found" empty state is shown
  Evidence: `test/presentation/features/sonarqube/sonarqube_issues_test.dart` "a clean project and an over-filtered one say different things".
- [x] Scenario: Load fails
  Given the request fails
  Then an `AppFailure`-mapped error view with retry is shown
  Evidence: `test/presentation/features/sonarqube/sonarqube_issues_test.dart` "a load failure shows the error with retry", "a failed page keeps the list and can be retried".

**UI / Design Notes**
- References `US-DESIGN-*`; a filterable list, each row showing a
  type/severity icon consistent with the metrics grid's visual language
  from `US-SQ-QUALITY-02`.

**Non-Functional Notes**
- Server-side filtering/pagination, not client-side, given potentially
  large issue counts (contrast `NFR-PERF-02`'s client-side approach for
  the much smaller project list).

### US-SQ-QUALITY-04 — View past analysis history

**Priority:** Could
**Source:** new — SonarQube initiative
**Dependencies:** US-SQ-QUALITY-01

As a user
I want to see when a project was last analyzed and its recent analysis
history
So that I can tell whether the quality data I'm looking at is current

**Acceptance Criteria**
- [x] Scenario: Successful load
  Given I view a project's analysis history
  Then `GET api/project_analyses/search?project=...` is called and a
  simple timestamped list of past analyses renders (this is analysis
  history, not build history — there is no per-analysis drill-down the
  way a Jenkins build or GitLab pipeline has, since an analysis is a data
  snapshot, not a job run)
  Evidence: `test/presentation/features/sonarqube/sonarqube_analysis_screen_test.dart` "lists analyses with how long ago and the version"; `test/data/repositories/sonarqube_repository_impl_test.dart` "parses analyses newest first, tolerating missing fields".
- [x] Scenario: No analysis history
  Given a project with only one or zero analyses
  Then an explicit "not enough history yet" state is shown rather than an
  empty list with no explanation
  Evidence: `test/presentation/features/sonarqube/sonarqube_analysis_screen_test.dart` "a single analysis explains there is not enough history", "a never-analysed project says so, not a blank list".

**Non-Functional Notes**
- Genuinely optional (`Could` priority) — the quality gate + measures
  views (`US-SQ-QUALITY-01`/`02`) already cover the primary use case;
  history is a nice-to-have, not do this before those are solid.

### US-SQ-QUALITY-05 — Ratings and technical debt

**Priority:** Should
**Source:** owner's local-server test, 2026-11-08
**Dependencies:** US-SQ-QUALITY-02

As a user
I want the reliability, security and maintainability ratings and the
technical debt
So that I can judge a project beyond its raw counts

**Acceptance Criteria**
- [x] Scenario: Computed
  Then the project page shows each rating as A–E and the debt as SonarQube
  writes it (an 8-hour day: `2d 3h`), and marks any measure the quality gate
  failed on
  Evidence: `test/presentation/features/sonarqube/sonarqube_project_page_test.dart` "ratings and technical debt are shown when computed", "a measure the gate failed on is marked for screen readers".
- [x] Scenario: Not computed
  Then no empty tile is drawn for it
  Evidence: `test/presentation/features/sonarqube/sonarqube_project_page_test.dart` "without them, no empty rating or debt tiles are drawn".

### US-SQ-QUALITY-06 — Issue detail

**Priority:** Should
**Source:** owner's local-server test, 2026-11-08
**Dependencies:** US-SQ-QUALITY-03

As a user
I want to open an issue and see why it was raised and where
So that I can act on it from my phone

**Acceptance Criteria**
- [x] Scenario: Detail
  Then the page shows type, severity, message, rule key and name
  (`api/rules/show`), file and line, effort to fix, status, author, when it
  was raised and tags, and the code around the issue
  (`api/sources/show`, markup removed) with the issue's line marked
  Evidence: `test/presentation/features/sonarqube/sonarqube_issue_screen_test.dart` "shows what is wrong, where, and the facts about it", "shows the code around the issue with its line marked".
- [x] Scenario: Part of it fails
  Then what loaded is shown; if both the rule and the code fail, the reason
  and a retry
  Evidence: `test/presentation/features/sonarqube/sonarqube_issue_screen_test.dart` "code that cannot be loaded says why, and retry works"; `test/data/repositories/sonarqube_repository_impl_test.dart` "one failing leaves the other", "both failing is the failure".

### US-SQ-OVERVIEW-01 — Overview tab (in place of History)

**Priority:** Should
**Source:** owner's local-server test, 2026-11-08
**Dependencies:** US-SQ-PROJ-03

As a user
I want one screen showing how all my projects are doing
So that SonarQube's second tab is useful, since it has no run history

**Acceptance Criteria**
- [x] Scenario: The tab
  Given SonarQube is the active tool
  Then the second tab is "Overview", and Jenkins and GitHub Actions keep
  "History"
  Evidence: `test/presentation/features/sonarqube/sonarqube_tab_wiring_test.dart` "SonarQube shows an Overview tab; other tools keep History".
- [x] Scenario: Content
  Then it shows counts of failing, warning, passing and not-analyzed
  projects, the totals of bugs, vulnerabilities and code smells, and the
  projects that need attention (failed before warning, worst first)
  Evidence: `test/presentation/features/sonarqube/sonarqube_overview_test.dart` "counts verdicts, totals the numbers and lists what needs a look", "failed before warning, with the worse project first".
- [x] Scenario: Honesty
  Then it never says all is well while verdicts are loading or failed to
  load, and says when it is based on only part of the project list
  Evidence: `test/presentation/features/sonarqube/sonarqube_overview_test.dart` "does not claim all is well while verdicts are missing", "a partial list says what it is based on, and loads more".

### US-SQ-LINK-01 — Open in SonarQube

**Priority:** Could
**Source:** owner's local-server test, 2026-11-08
**Dependencies:** US-SQ-QUALITY-03

As a user
I want to open a project or an issue in SonarQube's own web UI
So that I can see more than the app shows

**Acceptance Criteria**
- [x] Scenario: Link
  Then a project opens `{base}/dashboard?id=KEY` and an issue opens
  `{base}/project/issues?id=KEY&issues=ISSUE&open=ISSUE`, in the browser,
  with a server path (`/sonar`) kept and keys encoded
  Evidence: `test/domain/sonarqube/sonarqube_links_test.dart` "carries the project key and nothing else"; `test/presentation/features/sonarqube/sonarqube_project_page_test.dart` "Open in SonarQube opens the project in the browser"; `test/presentation/features/sonarqube/sonarqube_issue_screen_test.dart` "Open in SonarQube opens this issue in the browser".

---

## Planned work — documented 2026-11-09

Each story below carries its own **Status** line (batches 1–3 built and
batch 4 started 2026-11-17; the rest proposed). It was listed for the owner
on 2026-11-08, after the first SonarQube build-out (`P10-07`…`P10-17`) was
tested on the iPhone, and is recorded here on 2026-11-09 so it is not lost. Each
batch becomes a task in `tasks/phase-10-sonarqube.md` (`P10-18`…`P10-24`).
Nothing starts until the owner picks a batch and approves its plan
(`CLAUDE.md` §9).

**Verification status, stated once.** The endpoints named in these stories
come from SonarQube's Web API documentation. Only the calls already built
(`P10-07`…`P10-17`) have run against a real server, and only the owner's
local Community Build 26.1. Anything here that depends on a response shape
says so, and the plan for its batch checks it against the owner's server
first. The owner has said they test on a physical iPhone; see `CLAUDE.md` §10.

| Batch | Theme | Stories | Kind |
|---|---|---|---|
| 1 | Understand why a gate fails, and what is mine | US-SQ-ISSUES-01, US-SQ-CE-01, US-SQ-QUALITY-07, US-SQ-QUALITY-08, US-SQ-QUALITY-09 | read-only |
| 2 | Alerts | US-SQ-WATCH-01 | local notifications |
| 3 | Deeper project views | US-SQ-QUALITY-10, US-SQ-HOTSPOT-01, US-SQ-QUALITY-11, US-SQ-QUALITY-12, US-SQ-QUALITY-13, US-SQ-ISSUES-02 | read-only |
| 4 | Across projects and the server | US-SQ-ISSUES-03, US-SQ-SERVER-01, US-SQ-OVERVIEW-02 | read-only |
| 5 | Shortcuts and offline | US-SQ-PIN-01, US-SQ-WIDGET-01, US-SQ-OFFLINE-01, US-SQ-LINK-02, US-SQ-ISSUES-04 | device-side |
| 6 | Connecting the tools | US-SQ-XTOOL-01, US-SQ-XTOOL-02, US-SQ-XTOOL-03 | cross-tool |
| 7 | Changing data on the server | US-SQ-WRITE-01, US-SQ-WRITE-02, US-SQ-WRITE-03, US-SQ-WRITE-04 | writes |

**Suggested order** (the 2026-11-08 recommendation): batch 1, then batch 2, then the rest as the owner picks. Batch 1 comes first because the quality gate is judged on **new code**, which the app does not show yet. Batch 6 edits Jenkins and GitHub screens and batch 7 writes to the server, so each needs a separate go-ahead.

## Batch 1 — Understand why a gate fails, and what is mine (2026-11-09)

First in line (recommended to the owner on 2026-11-08). All five are `GET`s over data the app already reaches, and the quality gate is judged on **new code**, which the app does not show yet.

### US-SQ-ISSUES-01 — My issues across every project

**Batch:** 1 · **Priority:** Should · **Effort:** M
**Documented:** 2026-11-09 · **Status:** built 2026-11-17 (P10-18)
**Dependencies:** US-SQ-QUALITY-03, US-SQ-OVERVIEW-01

As a user
I want to see the open issues assigned to me, across all projects
So that I know what is mine to fix without opening each project

**Acceptance Criteria**
- [x] Scenario: Assigned to me
  Given I am signed in with a user token
  Then `GET api/issues/search?assignees=__me__&resolved=false` is called with no `componentKeys`, and the issues render in the same rows as the project issues list, each with its project name
  Evidence: `test/data/repositories/sonarqube_repository_impl_test.dart` "lists the caller's issues with no project filter"; `test/presentation/features/sonarqube/sonarqube_batch1_test.dart` "my issues lists the project and file, and filters on the server (US-SQ-ISSUES-01)".
- [x] Scenario: Filter and page
  Given the list is large
  Then the type and severity filters re-query the server and "Load more" pages it, as in `US-SQ-QUALITY-03`
  Evidence: `test/presentation/features/sonarqube/sonarqube_batch1_test.dart` "my issues lists the project and file, and filters on the server (US-SQ-ISSUES-01)".
- [x] Scenario: Nothing assigned
  Then "Nothing is assigned to you" is shown, not an empty list
  Evidence: `test/presentation/features/sonarqube/sonarqube_batch1_test.dart` "nothing assigned says exactly that (US-SQ-ISSUES-01)".

**Notes**
- Lives as a section of the Overview tab or a screen reached from it; the choice is made in the batch's plan.
- SonarQube stops paging at 10,000 results; the existing cap and note apply.
- `__me__` as an assignee value is from the Web API docs; not yet checked against the owner's server.

### US-SQ-CE-01 — Analysis status: running, queued or failed

**Batch:** 1 · **Priority:** Should · **Effort:** S–M
**Documented:** 2026-11-09 · **Status:** built 2026-11-17 (P10-18)
**Dependencies:** US-SQ-QUALITY-04

As a user
I want to see when a project is being analysed, is waiting, or its last analysis failed
So that I don't mistake a stale result for a current one

**Acceptance Criteria**
- [x] Scenario: In progress
  Given a scan is running or queued
  Then `GET api/ce/component?component=KEY` shows it, and the project page and its card say "Analysing…" or "Queued"
  Evidence: `test/presentation/features/sonarqube/sonarqube_batch1_test.dart` "a running scan says so; a quiet one says nothing (US-SQ-CE-01)"; `test/domain/sonarqube/sonarqube_insights_test.dart` "reports a running or queued scan".
- [x] Scenario: Last analysis failed
  Given the newest background task failed
  Then the page says so, with the time, so the gate shown is understood to be from an older analysis
  Evidence: `test/presentation/features/sonarqube/sonarqube_batch1_test.dart` "a failed analysis says when and why (US-SQ-CE-01)".
- [x] Scenario: Quiet
  Given nothing is pending and the last task succeeded
  Then nothing extra is drawn
  Evidence: `test/presentation/features/sonarqube/sonarqube_batch1_test.dart` "a running scan says so; a quiet one says nothing (US-SQ-CE-01)"; `test/domain/sonarqube/sonarqube_insights_test.dart` "is quiet when the newest task succeeded".

**Notes**
- No polling: checked when the page opens and on pull-to-refresh, as for the rest of the epic.
- Requires Browse permission on the project.

### US-SQ-QUALITY-07 — All gate conditions, passing ones too

**Batch:** 1 · **Priority:** Should · **Effort:** S
**Documented:** 2026-11-09 · **Status:** built 2026-11-17 (P10-18)
**Dependencies:** US-SQ-QUALITY-01

As a user
I want to see every condition of the quality gate with its threshold and my value
So that I know how close a passing project is to failing

**Acceptance Criteria**
- [x] Scenario: List
  Given the gate result has conditions
  Then each is listed with its metric, threshold, actual value and an OK or failed mark, failed ones first
  Evidence: `test/presentation/features/sonarqube/sonarqube_batch1_test.dart` "every gate condition is listed, failing ones first (US-SQ-QUALITY-07)".
- [x] Scenario: No conditions
  Then "This gate has no conditions" is shown
  Evidence: `test/presentation/features/sonarqube/sonarqube_batch1_test.dart` "a gate without conditions says so".

**Notes**
- The conditions already arrive in `api/qualitygates/project_status`; this only stops hiding the passing ones.
- Today only failing conditions are listed, under "What failed"; that block stays.

### US-SQ-QUALITY-08 — New code versus overall code

**Batch:** 1 · **Priority:** Should · **Effort:** M
**Documented:** 2026-11-09 · **Status:** built 2026-11-17 (P10-18)
**Dependencies:** US-SQ-QUALITY-02

As a user
I want to switch the measures between new code and overall code
So that I see the numbers the quality gate is actually judged on

**Acceptance Criteria**
- [x] Scenario: Switch
  Given a project page
  Then a switch shows Overall (today's view) or New code (`new_bugs`, `new_vulnerabilities`, `new_code_smells`, `new_coverage`, `new_duplicated_lines_density`, `new_lines`)
  Evidence: `test/presentation/features/sonarqube/sonarqube_batch1_test.dart` "the switch shows new-code measures only when the server has them (US-SQ-QUALITY-08)"; `test/data/repositories/sonarqube_repository_impl_test.dart` "asks for the new-code metrics and keeps what came back".
- [x] Scenario: No new-code period
  Given the project has no new-code period or no new code
  Then the switch says so instead of showing zeros
  Evidence: `test/presentation/features/sonarqube/sonarqube_batch1_test.dart` "no new-code switch when the server computes none (US-SQ-QUALITY-08)".

**Notes**
- How `api/measures/component` reports new-code values (a `period` object) varies by SonarQube version: **to be checked against the owner's server before the plan is final.**
- Measures stay labelled; a zero is never invented for a metric the server did not compute (see `US-SQ-QUALITY-02`).

### US-SQ-QUALITY-09 — Compare with the previous analysis

**Batch:** 1 · **Priority:** Could · **Effort:** M
**Documented:** 2026-11-09 · **Status:** built 2026-11-17 (P10-18)
**Dependencies:** US-SQ-QUALITY-04

As a user
I want to see what changed since the previous analysis
So that I notice a regression right away

**Acceptance Criteria**
- [x] Scenario: Delta
  Given at least two analyses
  Then each headline measure shows its change since the previous one (for example "+2 bugs", "coverage −1%"), worse in the failure colour
  Evidence: `test/presentation/features/sonarqube/sonarqube_batch1_test.dart` "the change since the previous analysis is shown (US-SQ-QUALITY-09)"; `test/domain/sonarqube/sonarqube_insights_test.dart` "more bugs is worse, less coverage is worse".
- [x] Scenario: One analysis
  Then no change is shown, and "Not enough history yet" applies
  Evidence: `test/data/repositories/sonarqube_repository_impl_test.dart` "turns two history points into a delta, drops a single point"; `test/domain/sonarqube/sonarqube_insights_test.dart` "needs two readable points, never invents one".

**Notes**
- `GET api/measures/search_history?component=KEY&metrics=...&ps=2`.
- Direction of "worse" depends on the metric (more bugs is worse, more coverage is better).

## Batch 2 — Alerts (2026-11-09)

After batch 1. This is what makes the app useful when it is closed. It reuses the Jenkins build watch (`US-JX-10`): local notifications and a best-effort periodic check, with no push server.

### US-SQ-WATCH-01 — Notify me when a gate fails after a new scan

**Batch:** 2 · **Priority:** Should · **Effort:** M–L
**Documented:** 2026-11-09 · **Status:** built 2026-11-17 (P10-19)
**Dependencies:** US-SQ-CE-01, `US-JX-10`'s watch plumbing

As a user
I want to be told when a project I watch fails its quality gate
So that I hear about a regression without opening the app

**Acceptance Criteria**
- [ ] Scenario: Watch a project
  Given I open a project
  Then I can turn on "Notify me when the gate fails"; it is stored on the device
  Open: not proven: the watch decision and the runner are tested (`test/domain/sonarqube/sonarqube_project_watch_test.dart`, `test/presentation/features/sonarqube/sonarqube_watch_runner_test.dart`), but no test turns the watch on from the project page or checks it is stored.
- [x] Scenario: Notified
  Given a watched project's newest analysis fails its gate
  Then one local notification names the project and what failed, once per analysis
  Evidence: `test/presentation/features/sonarqube/sonarqube_watch_runner_test.dart` "notifies once per new failing analysis and stores what it saw", "a failing gate with no analysis time does not re-notify every pass"; `test/domain/sonarqube/sonarqube_project_watch_test.dart` "a failing gate on an unseen analysis notifies, once".
- [ ] Scenario: Honest limits
  Given iOS decides when background work runs
  Then the screen says checks are best-effort and also run when the app is opened
  Open: not proven: the project page has the best-effort copy (`sonarqube_project_detail_screen.dart`), but no test checks it.
- [ ] Scenario: Off
  Given I turn the last watch off
  Then the background check is unregistered
  Open: not proven: no test shows the background check unregistered when the last SonarQube watch is turned off (the Jenkins equivalent is tested in `test/presentation/features/notifications/build_watch_notifier_test.dart`).

**Notes**
- Uses `flutter_local_notifications` and `workmanager`, both already approved in `CLAUDE.md` §3 (P11-24); no new dependency.
- The check reads the gate and the analysis date only, and holds no credential beyond what the app already stores.
- Cannot be verified in a test environment: needs a real device and a real analysis.

## Batch 3 — Deeper project views (2026-11-09)

Read-only depth for one project. Independent of each other; any can be taken alone.

### US-SQ-QUALITY-10 — Branch and pull request picker

**Batch:** 3 · **Priority:** Could · **Effort:** M
**Documented:** 2026-11-09 · **Status:** built 2026-11-17 (P10-20)
**Dependencies:** US-SQ-QUALITY-02

As a user
I want to see the gate and measures for a branch or pull request
So that I can check a change before it merges

**Acceptance Criteria**
- [x] Scenario: Choose
  Given the server lists more than the main branch (`GET api/project_branches/list`, `api/project_pull_requests/list`)
  Then a picker switches the page to that branch or pull request
  Evidence: `test/presentation/features/sonarqube/sonarqube_project_detail_screen_test.dart` "shows the choices when the server has them", "choosing one re-queries the gate", "another project keeps its own ref".
- [x] Scenario: Main only
  Given the server lists only the main branch
  Then no picker is shown
  Evidence: `test/presentation/features/sonarqube/sonarqube_project_detail_screen_test.dart` "is hidden when the server only has main".

**Notes**
- **Edition-dependent**: SonarQube Community Build may only analyse the main branch; branches and pull requests need an edition that supports them. Hide the picker rather than show a dead one.
- Every project call then carries a `branch` or `pullRequest` parameter.
- **Built 2026-11-17:** choices come from both `api/project_branches/list`
  and `api/project_pull_requests/list` (main excluded, malformed entries
  skipped); a server where either call fails simply offers no choices and
  the picker stays hidden. The selection is one `SonarQubeBranchRef` state;
  the SonarQube `Dio` is rebuilt with it, and an interceptor adds `branch=`
  or `pullRequest=` to the project-scoped endpoints only (gate, measures,
  measures history, component tree, issues, hotspots, analyses, ce/component),
  never to the branch or PR listings themselves. So one tap reloads the gate,
  measures, issues, hotspots, trends and worst files for that ref, since
  every notifier already watches the repository. Main branch adds no
  parameter at all. The selection is **per project** (a map keyed by project
  key, defaulting to main), so switching one project leaves the others as
  they were. The interceptor resolves a request's project from its own
  `project`/`projectKey`/`component`/`componentKeys` parameter. Widget tests
  cover the picker: hidden when only main exists, showing the choices
  otherwise, and choosing one re-querying the gate. Not verified against an
  edition that serves branches or pull requests.

### US-SQ-HOTSPOT-01 — Security hotspots

**Batch:** 3 · **Priority:** Should · **Effort:** M
**Documented:** 2026-11-09 · **Status:** built 2026-11-17 (P10-20)
**Dependencies:** US-SQ-QUALITY-03

As a user
I want to see a project's security hotspots and their review status
So that I know which security-sensitive code still needs a review

**Acceptance Criteria**
- [x] Scenario: List
  Given a project
  Then `GET api/hotspots/search?project=KEY` lists hotspots, filterable by status (to review, reviewed), with file and line
  Evidence: `test/presentation/features/sonarqube/sonarqube_hotspots_test.dart` "lists the ones to review with category, place and probability spelled out", "switching to Reviewed asks the server for those".
- [x] Scenario: Detail
  Given I open one
  Then its rule, vulnerability probability and the code around it are shown, as for an issue
  Evidence: `test/presentation/features/sonarqube/sonarqube_hotspots_test.dart` "expanding a hotspot shows its rule and the code".

**Notes**
- Reviewing a hotspot is a write and is `US-SQ-WRITE-04`, not this story.
- `api/hotspots/show` for the detail.
- **Built 2026-11-17:** project page → *Security hotspots*; *To review* /
  *Reviewed* chips ask the server for each (`status=TO_REVIEW|REVIEWED`,
  `ps=50`, *Load more*); a row shows its category, `file:line` and the
  probability spelled out ("High probability") rather than as a colour, and
  expanding it loads the rule's name plus the same code snippet an issue page
  shows. Not verified against a real server.

### US-SQ-QUALITY-11 — Trends over time

**Batch:** 3 · **Priority:** Could · **Effort:** M
**Documented:** 2026-11-09 · **Status:** built 2026-11-17 (P10-20)
**Dependencies:** US-SQ-QUALITY-04

As a user
I want to see how coverage, bugs and debt moved over time
So that I can tell whether the project is getting better

**Acceptance Criteria**
- [x] Scenario: Chart
  Given a project with several analyses
  Then a simple line chart of a chosen measure is drawn from `api/measures/search_history`, with the value of the touched point readable
  Evidence: `test/presentation/features/sonarqube/sonarqube_trends_test.dart` "draws the history and reads out the latest point", "a different measure re-queries the server".
- [x] Scenario: Too little data
  Then "Not enough history yet" is shown
  Evidence: `test/presentation/features/sonarqube/sonarqube_trends_test.dart` "says so when there is too little history".

**Notes**
- No chart library is in the locked stack (`CLAUDE.md` §3): either a small custom painter, or a flagged dependency request. **Decide in the plan, don't add silently.**
- The chart must also be readable without colour (labels, not only a line).
- **Decided and built 2026-11-17: a small custom painter, no dependency.**
  Project page → *Trends*, chips for Coverage / Bugs / Code smells /
  Duplication from `api/measures/search_history` (points the server sends
  without a value are dropped, `DateTime.tryParse` guards the date). The
  painter draws a grid with each value written as text, the line, its dots
  and both end dates; a tap picks the nearest point
  (`nearestSonarQubePointIndex`, pure and tested) and the date · value is
  written under the chart, so nothing depends on colour. Fewer than two
  points says "Not enough history yet". A semantics label states lowest,
  highest and their dates. Not verified against a real server.

### US-SQ-QUALITY-12 — Worst files

**Batch:** 3 · **Priority:** Could · **Effort:** M
**Documented:** 2026-11-09 · **Status:** built 2026-11-17 (P10-20)
**Dependencies:** US-SQ-QUALITY-03

As a user
I want to see the files with the most issues, the least coverage or the most duplication
So that I know where to start

**Acceptance Criteria**
- [x] Scenario: Ranking
  Given a project and a chosen measure
  Then `GET api/measures/component_tree` (file level, sorted by that measure) lists the ten worst files with their values
  Evidence: `test/presentation/features/sonarqube/sonarqube_worst_files_test.dart` "ranks the files with their values, lowest coverage first", "a different ranking asks for that metric".
- [x] Scenario: Open a file
  Then a tap shows that file's issues
  Evidence: `test/presentation/features/sonarqube/sonarqube_worst_files_test.dart` "tapping a file opens its own issues".

**Notes**
- Uses `strategy=leaves`, `qualifiers=FIL`, `s=metric`, `metricSort`, `ps=10`.
- **Built 2026-11-17:** project page → *Worst files*, four rankings with
  their own direction — *Least covered* sorts ascending (no coverage is
  worst), *Most duplicated*, *Most issues* and *Most complex* sort
  descending. A file the server sends no value for shows `—`, not `0%`.
  Tapping a file opens a sheet with that file's open issues
  (`api/issues/search?componentKeys=<projectKey>:<path>`, through the same
  parsing as every issue list); a file with none says so. Not verified
  against a real server.

### US-SQ-QUALITY-13 — Language breakdown

**Batch:** 3 · **Priority:** Could · **Effort:** S
**Documented:** 2026-11-09 · **Status:** built 2026-11-17 (P10-20)
**Dependencies:** US-SQ-QUALITY-02

As a user
I want to see how the lines of code split by language
So that I understand what the project is made of

**Acceptance Criteria**
- [x] Scenario: Breakdown
  Given the metric `ncloc_language_distribution` (for example `java=1200;js=340`)
  Then a list or bar shows each language with its lines and share
  Evidence: `test/presentation/features/sonarqube/sonarqube_language_breakdown_test.dart` "lists each language with its lines and share".
- [x] Scenario: Missing
  Then the section is left out
  Evidence: `test/presentation/features/sonarqube/sonarqube_language_breakdown_test.dart` "is left off the page when the server has no distribution".

**Notes**
- The metric is a `;`-separated string and needs parsing; keep that in the domain layer with tests.
- **Built 2026-11-17:** `SonarQubeLanguageBreakdown.parse` in the domain
  (tested): biggest first, ties by name, share rounded, fragments that are
  not `name=<positive int>` skipped, all-zero or absent = empty. The section
  sits under the measures on the project page as bars with "1200 lines ·
  78%" written out, and is left off entirely when the server reports
  nothing — no empty heading. It rides in the existing measures call
  (`fetchMeasures` now also asks for `ncloc_language_distribution`), so a
  server without it costs no extra request. Not verified against a real
  server.

### US-SQ-ISSUES-02 — Group issues by file, rule or severity

**Batch:** 3 · **Priority:** Could · **Effort:** S–M
**Documented:** 2026-11-09 · **Status:** built 2026-11-17 (P10-20)
**Dependencies:** US-SQ-QUALITY-03

As a user
I want to group a project's issues
So that a long list becomes something I can scan

**Acceptance Criteria**
- [x] Scenario: Group
  Given the issues list
  Then a control groups it by file, rule or severity, each group showing its count
  Evidence: `test/presentation/features/sonarqube/sonarqube_issues_test.dart` "By file shows the server groups with their counts", "No grouping brings the issues back".
- [x] Scenario: Server side
  Then grouping uses the server's facets (`facets=files,rules,severities`) so counts are right beyond the first page
  Evidence: `test/presentation/features/sonarqube/sonarqube_issues_test.dart` "By file shows the server groups with their counts"; `test/domain/sonarqube_issue_grouping_test.dart` "reads the requested facet, biggest group first".

**Notes**
- Keeps the server-side filtering and paging of `US-SQ-QUALITY-03`.
- **Built 2026-11-17:** chips above the list — No grouping / By file / By
  rule / By severity. Choosing one asks the server for that facet
  (`facets=files|rules|severities`) and the body becomes the groups with the
  server's counts, biggest first, so the numbers are right beyond the first
  page; the filter chips still narrow both. No grouping asks for no facet at
  all, so a server that charges for facets is not charged for nothing. A
  facet the server omits leaves the usual issue list in place rather than an
  empty group screen.

## Batch 4 — Across projects and the server (2026-11-09)

Read-only views that span projects, plus the server itself.

### US-SQ-ISSUES-03 — Search issues across projects

**Batch:** 4 · **Priority:** Could · **Effort:** M
**Documented:** 2026-11-09 · **Status:** built 2026-11-17 (P10-21), changed from "text"
**Dependencies:** US-SQ-ISSUES-01

As a user
I want to search issues by text or rule across every project
So that I can find a known problem wherever it is

**Acceptance Criteria**
- [x] Scenario: Search
  Given a search term or rule
  Then `GET api/issues/search` with the matching parameters lists results across projects, server-filtered and paged
  Evidence: `test/presentation/features/sonarqube/sonarqube_issue_search_test.dart` "asks nothing until a term is submitted, then lists matches (US-SQ-ISSUES-03)".
- [x] Scenario: None
  Then "No issues match" is shown
  Evidence: `test/presentation/features/sonarqube/sonarqube_issue_search_test.dart` "says "No issues match" when nothing comes back".

**Notes**
- The exact text-search parameter is confirmed against the owner's server in the plan; not assumed here.
- **Built 2026-11-17, and the parameter does not exist.** `api/issues/search` has no `q` (SonarQube 26.1's own web-service listing; an unknown `q` is silently ignored and returns everything). Search is therefore by an exact server-side filter: rule (`rules`), tag (`tags`), file path (`files`) or issue key (`issues`). Free text over the message is not offered, because filtering it on the device would only cover what is loaded.

### US-SQ-SERVER-01 — Server health and version

**Batch:** 4 · **Priority:** Could · **Effort:** S
**Documented:** 2026-11-09 · **Status:** built 2026-11-17 (P10-21)
**Dependencies:** US-SQ-CRED-04

As a user
I want to see my SonarQube server's version and status
So that I can tell a server problem from an app problem

**Acceptance Criteria**
- [x] Scenario: Info
  Given an active credential
  Then the version (`api/server/version`) and status (`api/system/status`, for example UP or STARTING) are shown, with an edition hint where the server reports one
  Evidence: `test/presentation/features/sonarqube/sonarqube_server_screen_test.dart` "shows the version and the status", "a server that is starting explains itself".
- [x] Scenario: Unreachable
  Then the same error view as elsewhere, with a retry
  Evidence: `test/presentation/features/sonarqube/sonarqube_server_screen_test.dart` "an unreachable server shows the error with retry".

**Notes**
- `api/system/health` and the background-task queue need administrator rights; shown only if the token allows it, never required.
- **Built 2026-11-17:** project page → *Server version and status*. Version
  from `api/server/version`, status from `api/system/status`, made readable
  (`UP` → "Up") with a sentence for the cases people actually hit —
  starting, maintenance — and an unreachable server reuses the app's error
  view with retry. Edition is not shown, and the page says why: the
  endpoints that report it need administrator rights, so nothing is asked
  for that would 403 for a normal token. Not verified against a real
  server.

### US-SQ-OVERVIEW-02 — Overview trend: are more projects failing?

**Batch:** 4 · **Priority:** Could · **Effort:** M
**Documented:** 2026-11-09 · **Status:** built 2026-11-17 (P10-21)
**Dependencies:** US-SQ-OVERVIEW-01

As a user
I want to see whether the number of failing projects is going up or down
So that I see the direction, not only today's count

**Acceptance Criteria**
- [x] Scenario: Trend
  Given the Overview has been opened on different days
  Then it shows the change in failing projects since the last snapshot
  Evidence: `test/presentation/features/sonarqube/sonarqube_overview_test.dart` "shows the change in failing projects since the last look (US-SQ-OVERVIEW-02)"; `test/domain/sonarqube/sonarqube_overview_trend_test.dart` "compares with the newest snapshot at least an hour old".
- [x] Scenario: First time
  Then no trend is shown, with a note that it starts now
  Evidence: `test/presentation/features/sonarqube/sonarqube_overview_test.dart` "the first visit says the trend starts now (US-SQ-OVERVIEW-02)".

**Notes**
- SonarQube has no portfolio-level history for this, so the app would **store its own small snapshots on the device** (counts only, no secrets, in `shared_preferences`). Honest label: "since you last looked", not "over time".
- **Built 2026-11-17:** compares with the newest snapshot at least an hour old, so two quick visits do not erase "yesterday"; keeps 30 per credential; counts only; first visit says the trend starts now.
- The alternative is computing it from each project's history, which costs one request per project; rejected for the rate-limit-style reasons of `US-GH-HIST-02`.

## Batch 5 — Shortcuts and offline (2026-11-09)

Convenience that mostly reuses plumbing the Jenkins work already built.

### US-SQ-PIN-01 — Pin projects

**Batch:** 5 · **Priority:** Should · **Effort:** S–M
**Documented:** 2026-11-09 · **Status:** built 2026-11-17 (P10-22)
**Dependencies:** US-SQ-PROJ-03

As a user
I want to pin the projects I care about
So that they sit at the top of the list and the Overview

**Acceptance Criteria**
- [x] Scenario: Pin
  Given a project card or page
  Then I can pin or unpin it; pinned projects sort first
  Evidence: `test/presentation/features/sonarqube/sonarqube_pins_test.dart` "the card pins and unpins, and says which", "pinned failing projects are listed first in the overview".
- [x] Scenario: Kept
  Then pins are remembered on the device per credential
  Evidence: `test/presentation/features/sonarqube/sonarqube_pins_test.dart` "pins are remembered per credential (US-SQ-PIN-01)".

**Notes**
- Pins are **local**, not SonarQube's server-side favourites (`api/favorites/*` would write to the server and is a `US-SQ-WRITE-*` concern). The plan may offer the server favourites later.
- Mirrors Jenkins pinned jobs (`US-JX-23`).

### US-SQ-WIDGET-01 — Home-screen widget for pinned projects

**Batch:** 5 · **Priority:** Could · **Effort:** L
**Documented:** 2026-11-09 · **Status:** built 2026-11-17 (P10-22)
**Dependencies:** US-SQ-PIN-01, `US-JX-23`'s widget plumbing

As a user
I want to see my pinned projects' gate status on my home screen
So that I check them without opening the app

**Acceptance Criteria**
- [ ] Scenario: Widget
  Given pinned projects
  Then the widget lists each with its gate verdict and the time it was last updated
  Open: device-only: the native widgets draw the verdicts (no Flutter test); check on the iPhone (M-01).
- [x] Scenario: No credentials
  Then the widget holds no credential and never calls SonarQube itself; it shows a snapshot the app wrote
  Evidence: `test/presentation/features/home_widget/sonarqube_widget_sync_test.dart` "a pinned project's verdict reaches the widget, with no credential (US-SQ-WIDGET-01)", "with the app lock on, the widget shows only a count".

**Notes**
- Reuses the `home_widget` plumbing (iOS WidgetKit extension and the Android provider), approved in `CLAUDE.md` §3 (P11-26). Needs native work on both platforms, hence L.
- Only verifiable on a real device.

### US-SQ-OFFLINE-01 — Offline copy of the last data

**Batch:** 5 · **Priority:** Could · **Effort:** M
**Documented:** 2026-11-09 · **Status:** built 2026-11-17 (P10-22)
**Dependencies:** US-SQ-PROJ-03

As a user
I want to see the last data I loaded when I have no connection
So that I can still check a project on the train

**Acceptance Criteria**
- [x] Scenario: Cached
  Given I have loaded the project list and a project
  Then with no connection they show the saved copy, marked "Saved 2h ago"
  Evidence: `test/data/cache/sonarqube_cache_test.dart` "no connection shows the saved list and numbers, marked saved", "a refused token is never answered with old data".
- [x] Scenario: Never secrets
  Then only non-secret project data is cached, in the same place and the same way as the Jenkins tree cache (`US-JX-20`), and is cleared on sign-out
  Evidence: `test/data/cache/sonarqube_cache_test.dart` "saves and reads the list and the numbers, and nothing secret", "a corrupt file is no cache, and clearAll removes everything"; logout calls `clearAll` (`auth_notifier.dart`).

**Notes**
- Reuses `path_provider` and the Jenkins cache pattern (`P11-23`).

### US-SQ-LINK-02 — Deep links to a project

**Batch:** 5 · **Priority:** Could · **Effort:** S
**Documented:** 2026-11-09 · **Status:** built 2026-11-17 (P10-22)
**Dependencies:** US-SQ-LINK-01

As a user
I want to open a project in the app from a link
So that a teammate's message can take me straight to it

**Acceptance Criteria**
- [ ] Scenario: Open
  Given `jobtrigger://app/sonarqube/project?key=KEY`
  Then the app opens that project when SonarQube credentials exist, else explains what is missing
  Open: partly: a valid key routes to the project look-up (`test/presentation/navigation/app_router_test.dart` "a SonarQube project link needs a valid key, else Home"; `test/data/repositories/sonarqube_repository_impl_test.dart` "fetchProjectByKey reads a project from components/show"), but no test covers the "what is missing" message without a SonarQube credential.
- [x] Scenario: Guarded
  Then a link without a valid key lands on Home, like the other extra-only routes (AUD-51)
  Evidence: `test/presentation/navigation/app_router_test.dart` "a SonarQube project link needs a valid key, else Home"; `test/domain/sonarqube/sonarqube_links_test.dart` "accepts real keys and refuses anything else".

**Notes**
- Must not let a link choose the server or carry a token: the key only.

### US-SQ-ISSUES-04 — Copy and share an issue

**Batch:** 5 · **Priority:** Could · **Effort:** S
**Documented:** 2026-11-09 · **Status:** built 2026-11-17 (P10-22)
**Dependencies:** US-SQ-QUALITY-06

As a user
I want to copy or share an issue's details
So that I can send it to a teammate

**Acceptance Criteria**
- [x] Scenario: Share
  Given an issue page
  Then Copy and Share send the message, rule, location and the link from `US-SQ-LINK-01`
  Evidence: `test/domain/sonarqube/sonarqube_links_test.dart` "has message, rule, location and the web link", "leaves out what is unknown".
- [x] Scenario: No secrets
  Then the text never contains a token
  Evidence: `test/domain/sonarqube/sonarqube_links_test.dart` "has message, rule, location and the web link"; the text is built only from issue fields and the web link (`sonarQubeIssueShareText`).

**Notes**
- Uses `share_plus`, already in the stack (P5-12).

## Batch 6 — Connecting the tools (2026-11-09)

Touches the Jenkins and GitHub screens, so it needs the owner's explicit go-ahead and `CLAUDE.md` §11 care: Jenkins is frozen except for bug fixes, and each tool is its own auth domain (`NFR-SEC-03`). The link between a Jenkins job (or GitHub repo) and a SonarQube project is **stored on the device, not on any server**, and never shares credentials between tools.

### US-SQ-XTOOL-01 — Show a project's SonarQube gate on a Jenkins build

**Batch:** 6 · **Priority:** Could · **Effort:** M–L
**Documented:** 2026-11-09 · **Status:** built 2026-11-17 (P10-23)
**Dependencies:** US-SQ-PROJ-01, a Jenkins build page

As a user
I want to see the quality gate for the SonarQube project linked to a Jenkins job
So that I know whether a build also passed its quality gate

**Acceptance Criteria**
- [x] Scenario: Link
  Given a Jenkins job
  Then I can link it to a SonarQube project once, on the device
  Evidence: `test/presentation/features/sonarqube/sonarqube_gate_link_test.dart` "link once, then the gate shows beside the build, unlink confirms (US-SQ-XTOOL-01)".
- [x] Scenario: Show
  Given a linked job
  Then its build page shows the gate verdict using the SonarQube credential, with a tap through to the project
  Evidence: `test/presentation/features/sonarqube/sonarqube_gate_link_test.dart` "link once, then the gate shows beside the build, unlink confirms (US-SQ-XTOOL-01)".
- [x] Scenario: Separate
  Given no SonarQube credential
  Then nothing is shown and Jenkins behaves exactly as before
  Evidence: `test/presentation/features/sonarqube/sonarqube_gate_link_test.dart` "with no SonarQube credential nothing is drawn (US-SQ-XTOOL-01)", "a device that never set SonarQube up reads nothing from it", "a configured device with a credential that is gone draws nothing".

**Notes**
- A change to the Jenkins build page is the one place this batch edits frozen Jenkins code; the plan must show the diff first.

### US-SQ-XTOOL-02 — Scan from Jenkins

**Batch:** 6 · **Priority:** Could · **Effort:** L
**Documented:** 2026-11-09 · **Status:** built 2026-11-17 (P10-23)
**Dependencies:** US-SQ-XTOOL-01

As a user
I want to run the Jenkins job that scans a project, then watch the SonarQube result
So that a re-scan is one flow on my phone

**Acceptance Criteria**
- [x] Scenario: Run
  Given a linked job
  Then "Scan now" uses the existing Jenkins trigger and confirmation flow
  Evidence: `test/presentation/features/sonarqube/sonarqube_gate_link_test.dart` ""Scan now" finds the linked Jenkins job (US-SQ-XTOOL-02)".
- [x] Scenario: Follow
  Then the project page shows `US-SQ-CE-01`'s analysis status until the new result arrives
  Evidence: `test/presentation/features/sonarqube/sonarqube_batch1_test.dart` "a running scan says so; a quiet one says nothing (US-SQ-CE-01)".

**Notes**
- Reuses Jenkins trigger and watch as they are; does not change them.

### US-SQ-XTOOL-03 — Show the gate beside a GitHub workflow run

**Batch:** 6 · **Priority:** Could · **Effort:** M–L
**Documented:** 2026-11-09 · **Status:** built 2026-11-17 (P10-23)
**Dependencies:** US-SQ-PROJ-01, GitHub run detail

As a user
I want to see the SonarQube gate for the repository's linked project on a workflow run
So that I see build and quality together

**Acceptance Criteria**
- [x] Scenario: Link and show
  Given a GitHub repo linked to a SonarQube project on the device
  Then a run's page shows the gate verdict, and nothing changes for an unlinked repo
  Evidence: `test/presentation/features/sonarqube/sonarqube_gate_link_test.dart` "a GitHub link and a Jenkins link are separate".

**Notes**
- Same separation rules as `US-SQ-XTOOL-01`.

## Batch 7 — Changing data on the server (2026-11-09)

**The first writes in this epic.** The epic's stories so far are all `GET`s (see "Read-only, full stop" above, as built); this batch is where that stops being true, so it is last and needs its own explicit approval. A token whose user may modify issues is required; a 403 is reported with `SonarQubeAccessDeniedFailure`'s wording. Every action asks for confirmation, like Jenkins trigger and cancel, and none changes the screen before the server answers.

### US-SQ-WRITE-01 — Assign an issue

**Batch:** 7 · **Priority:** Could · **Effort:** M
**Documented:** 2026-11-09 · **Status:** built 2026-11-17 (P10-24)
**Dependencies:** US-SQ-QUALITY-06

As a user
I want to assign an issue to someone, or to myself
So that it has an owner

**Acceptance Criteria**
- [x] Scenario: Assign
  Given an issue page
  Then I can choose an assignee (`POST api/issues/assign`), confirm, and see it applied only after the server accepts it
  Evidence: `test/presentation/features/sonarqube/sonarqube_writes_test.dart` "assigning to me uses the id assign understands (found live)", "the screen changes only after the server has answered (US-SQ-WRITE-02)"; `test/data/repositories/sonarqube_repository_impl_test.dart` "each change is one form-encoded POST, values in the body".
- [x] Scenario: Refused
  Given the token cannot modify issues
  Then the reason is shown and nothing changes
  Evidence: `test/presentation/features/sonarqube/sonarqube_writes_test.dart` "a 403 shows the clear message and changes nothing".

**Notes**
- Looking up assignable users (`api/users/search`) may need extra permission; the plan handles its absence.
- **Built 2026-11-17:** no user lookup (it needs administrator rights): assign to *me* (`_me`, which `assign` wants; `__me__` is only for search), to a login the user types, or unassign.

### US-SQ-WRITE-02 — Change an issue's status

**Batch:** 7 · **Priority:** Could · **Effort:** M
**Documented:** 2026-11-09 · **Status:** built 2026-11-17 (P10-24)
**Dependencies:** US-SQ-QUALITY-06

As a user
I want to confirm an issue, mark it a false positive, accept it or reopen it
So that the list reflects my decision

**Acceptance Criteria**
- [x] Scenario: Transition
  Given an issue
  Then only the transitions the server offers (`POST api/issues/do_transition`: confirm, unconfirm, reopen, resolve, falsepositive, wontfix/accept) are shown, each with a confirmation
  Evidence: `test/presentation/features/sonarqube/sonarqube_writes_test.dart` "shows the server's status and only the transitions it offers (US-SQ-WRITE-02)", "a status change asks first, and cancelling sends nothing".

**Notes**
- The offered transitions come from the issue itself (`transitions`), never a fixed list in the app.

### US-SQ-WRITE-03 — Comment on an issue

**Batch:** 7 · **Priority:** Could · **Effort:** S–M
**Documented:** 2026-11-09 · **Status:** built 2026-11-17 (P10-24)
**Dependencies:** US-SQ-QUALITY-06

As a user
I want to add a comment to an issue
So that I can leave context for the team

**Acceptance Criteria**
- [x] Scenario: Comment
  Given an issue page
  Then I can write a comment (`POST api/issues/add_comment`); it is sent as a form value, never built into a URL by hand, and shown once saved
  Evidence: `test/presentation/features/sonarqube/sonarqube_writes_test.dart` "a comment warns it is public, is cleared only once saved (US-SQ-WRITE-03)"; `test/data/repositories/sonarqube_repository_impl_test.dart` "each change is one form-encoded POST, values in the body".

**Notes**
- Comments are visible to others: the field says so before sending.

### US-SQ-WRITE-04 — Review a security hotspot

**Batch:** 7 · **Priority:** Could · **Effort:** M
**Documented:** 2026-11-09 · **Status:** built 2026-11-17 (P10-24)
**Dependencies:** US-SQ-HOTSPOT-01

As a user
I want to mark a hotspot safe, or fixed
So that the review queue shrinks

**Acceptance Criteria**
- [ ] Scenario: Review
  Given a hotspot
  Then I can set its status and resolution (`POST api/hotspots/change_status`) after a confirmation, with an optional comment
  Open: partly: the request is proven (`test/data/repositories/sonarqube_repository_impl_test.dart` "each change is one form-encoded POST, values in the body", including `api/hotspots/change_status`), but no test covers the confirmation and comment in the hotspot screen.

**Notes**
- Needs the permission to review hotspots on that project.

