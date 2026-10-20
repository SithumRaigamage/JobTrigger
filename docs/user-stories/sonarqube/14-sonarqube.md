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
- Scenario: Successful add against SonarCloud
  Given I leave the instance URL at its `https://sonarcloud.io` default,
  enter a label, the token, and an organization key, and tap Save
  Then the credential is created via the new backend endpoint and appears
  in the SonarQube server list
- Scenario: Successful add against a self-hosted SonarQube Server
  Given I change the instance URL to `https://sonar.example.com` and leave
  the organization field empty
  Then the credential saves without requiring an organization — self-hosted
  Server has no such concept
- Scenario: Token validation
  Given the token field is empty
  Then client-side validation blocks submission with an inline message,
  before any network call (`NFR-SEC-02`)
- Scenario: Instance URL validation
  Given the instance URL field is empty or not a well-formed URL
  Then client-side validation blocks submission with an inline message
- Scenario: Save fails
  Given the backend request fails
  Then an `AppFailure`-mapped message is shown and the form retains
  entered values

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
- Scenario: Edit updates label/URL/token/organization
  Given I open an existing credential's edit sheet
  Then the token field is never pre-filled (`NFR-SEC-01`'s redaction
  mechanism), with "leave blank to keep the current token" copy
- Scenario: Delete with confirmation
  Given I swipe-delete a credential
  Then a confirmation dialog appears before the backend delete call fires
- Scenario: Deleting the active credential falls back
  Given the deleted credential was the active one
  Then another `isDefault`/first-remaining credential becomes active, or
  the active-credential state clears if none remain, mirroring
  `ActiveGitHubCredentialNotifier.deleteCredential`'s exact fallback logic

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
- Scenario: Switching updates the active credential immediately
  Given I tap a non-active credential's radio indicator in the SonarQube
  section of Settings
  Then it becomes active and the project list (`US-SQ-PROJ-01`) refetches
  against it
- Scenario: Independent from every other tool's active state
  Given Jenkins/GitHub/GitLab credentials are also configured
  Then switching the active SonarQube credential does not touch any of
  their active-selection state (`NFR-SEC-03`, now covering four
  independent auth/active-state domains)

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
- Scenario: Successful test
  Given a valid instance URL and token
  When I tap "Test Connection"
  Then `GET {baseUrl}/api/authentication/validate` is called (SonarQube's
  own dedicated token-validation endpoint — returns `{valid: true/false}`,
  a genuinely different shape from Jenkins/GitHub/GitLab's "fetch my user"
  pattern, since this endpoint exists specifically for this purpose) and a
  success state is shown when `valid: true`
- Scenario: Failed test
  Given `valid: false`, an invalid token, or an unreachable instance URL
  Then a clear `AppFailure`-mapped message is shown, and save remains
  allowed regardless (this is a nudge, not a gate)

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
- Scenario: Successful load against SonarCloud
  Given an active SonarCloud credential with an organization set
  Then `GET api/projects/search?organization=...` is called and the
  project list renders — `key`, `name`, `lastAnalysisDate`
- Scenario: Successful load against self-hosted Server
  Given an active self-hosted credential with no organization set
  Then `GET api/projects/search` is called without the `organization`
  param
- Scenario: No active credential
  Given no SonarQube credential is active
  Then a `NoActiveSonarQubeCredentialView` gates the screen, mirroring
  `NoActiveGitHubCredentialView`/`NoActiveServerView`
- Scenario: A project with no analysis yet
  Given a project whose `lastAnalysisDate` is absent (created but never
  scanned)
  Then it's shown with an explicit "Not analyzed yet" state rather than a
  blank or misleading quality indicator
- Scenario: Client-side search
  Given I type into the search field
  Then the list filters by `name`, case-insensitive, client-side, no
  per-keystroke network call (`NFR-PERF-02`)
- Scenario: Load fails
  Given the request fails (including a missing/wrong organization key for
  SonarCloud, which 404s rather than returning an empty list)
  Then an `AppFailure`-mapped error view with retry is shown, with the
  organization-key case surfacing a message distinct enough from a generic
  404 that the user knows to check their credential's organization field

**UI / Design Notes**
- References `US-DESIGN-*`; mirrors `GitHubRepoScreen`'s glass-card
  list/search/pull-to-refresh structure. Each tile shows a compact quality
  gate badge (`US-SQ-QUALITY-01`'s data) so the list itself is useful at a
  glance, not just a picker.

**Non-Functional Notes**
- `NFR-PERF-02` (client-side search, no per-keystroke network call).

---

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
- Scenario: Passing gate
  Given I open a project
  Then `GET api/qualitygates/project_status?projectKey=...` is called and
  a clear "Passed" state renders when `projectStatus.status == "OK"`
- Scenario: Failing gate, with the specific reasons
  Given `projectStatus.status == "ERROR"`
  Then each failing condition in `projectStatus.conditions[]` is listed
  with its metric, comparator, threshold, and actual value — not just a
  generic "failed" badge
- Scenario: No quality gate result yet
  Given `projectStatus.status == "NONE"` (no analysis yet)
  Then an explicit "not yet analyzed" state is shown, consistent with
  `US-SQ-PROJ-01`'s list-level version of the same state
- Scenario: Load fails
  Given the request fails
  Then an `AppFailure`-mapped error view with retry is shown

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
- Scenario: Successful load
  Given I view a project's quality tab
  Then `GET api/measures/component?component=...&metricKeys=coverage,
  bugs,vulnerabilities,code_smells,duplicated_lines_density,ncloc` is
  called and each requested metric renders with its value and a
  human-readable label/unit (percentage for coverage/duplication, raw
  count for bugs/vulnerabilities/code smells, lines of code for `ncloc`)
- Scenario: A metric with no computed value
  Given a metric absent from the response (e.g. a language-specific metric
  that doesn't apply to this project)
  Then that metric's tile shows "—" rather than a zero, which would
  misleadingly imply a fully-verified perfect score
- Scenario: Load fails
  Given the request fails
  Then an `AppFailure`-mapped error view with retry is shown

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
- Scenario: Successful load
  Given I open a project's issues list
  Then `GET api/issues/search?componentKeys=...` is called and each
  issue's `type` (`BUG`/`VULNERABILITY`/`CODE_SMELL`), `severity`,
  `message`, and file/line location render
- Scenario: Filter by type/severity
  Given I select a type or severity filter
  Then the request is re-issued with `types`/`severities` query params
  (server-side filtering, not client-side — this list can be large enough
  that client-side filtering over an unbounded fetch isn't appropriate,
  unlike the project-list search in `US-SQ-PROJ-01`)
- Scenario: Pagination
  Given more issues exist than one page (`api/issues/search`'s default
  page size)
  Then a "load more" affordance fetches subsequent pages via `p`/`ps`
  params, same pagination pattern as `US-GL-PROJ-01`
- Scenario: No issues
  Given a clean project
  Then an explicit "No issues found" empty state is shown
- Scenario: Load fails
  Given the request fails
  Then an `AppFailure`-mapped error view with retry is shown

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
- Scenario: Successful load
  Given I view a project's analysis history
  Then `GET api/project_analyses/search?project=...` is called and a
  simple timestamped list of past analyses renders (this is analysis
  history, not build history — there is no per-analysis drill-down the
  way a Jenkins build or GitLab pipeline has, since an analysis is a data
  snapshot, not a job run)
- Scenario: No analysis history
  Given a project with only one or zero analyses
  Then an explicit "not enough history yet" state is shown rather than an
  empty list with no explanation

**Non-Functional Notes**
- Genuinely optional (`Could` priority) — the quality gate + measures
  views (`US-SQ-QUALITY-01`/`02`) already cover the primary use case;
  history is a nice-to-have, not do this before those are solid.
