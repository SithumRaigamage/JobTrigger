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
  Then `GET api/components/search_projects?organization=...` is called (any
  user with Browse access may; `api/projects/search` is administrator-only and
  is used only as a fallback for a server that lacks it) and the
  project list renders — `key`, `name`, `lastAnalysisDate`
- Scenario: Successful load against self-hosted Server
  Given an active self-hosted credential with no organization set
  Then `GET api/components/search_projects` is called without the `organization`
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

### US-SQ-PROJ-03 — See each project's health in the list

**Priority:** Should
**Source:** owner's local-server test, 2026-11-08
**Dependencies:** US-SQ-PROJ-01

As a user
I want each project card to show its quality-gate verdict and headline
numbers, and to sort and filter the list by them
So that I can find what needs attention without opening every project

**Acceptance Criteria**
- Scenario: Card numbers
  Given the project list has loaded
  Then each card shows its gate verdict (Passed / Failed / Warning / Not
  analyzed) and its bugs, vulnerabilities, code smells and coverage, loaded
  with one `GET api/measures/search` request per 100 projects, never one per
  project. A figure the server did not compute is "—", not 0
- Scenario: Sort and filter
  Given the list is shown
  Then it can be sorted by name, last analysed or quality gate (failing
  first), and narrowed to projects whose gate failed or warns
- Scenario: The numbers cannot be loaded
  Given that request fails
  Then the list still works, without the badges, and nothing is called
  passing
- Scenario: Last analysed
  Given `api/components/search_projects` leaves the date out unless asked
  Then the list asks for `f=analysisDate`, and a project still without a date
  looks up its newest analysis before being called "Never analyzed"

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

### US-SQ-QUALITY-05 — Ratings and technical debt

**Priority:** Should
**Source:** owner's local-server test, 2026-11-08
**Dependencies:** US-SQ-QUALITY-02

As a user
I want the reliability, security and maintainability ratings and the
technical debt
So that I can judge a project beyond its raw counts

**Acceptance Criteria**
- Scenario: Computed
  Then the project page shows each rating as A–E and the debt as SonarQube
  writes it (an 8-hour day: `2d 3h`), and marks any measure the quality gate
  failed on
- Scenario: Not computed
  Then no empty tile is drawn for it

### US-SQ-QUALITY-06 — Issue detail

**Priority:** Should
**Source:** owner's local-server test, 2026-11-08
**Dependencies:** US-SQ-QUALITY-03

As a user
I want to open an issue and see why it was raised and where
So that I can act on it from my phone

**Acceptance Criteria**
- Scenario: Detail
  Then the page shows type, severity, message, rule key and name
  (`api/rules/show`), file and line, effort to fix, status, author, when it
  was raised and tags, and the code around the issue
  (`api/sources/show`, markup removed) with the issue's line marked
- Scenario: Part of it fails
  Then what loaded is shown; if both the rule and the code fail, the reason
  and a retry

### US-SQ-OVERVIEW-01 — Overview tab (in place of History)

**Priority:** Should
**Source:** owner's local-server test, 2026-11-08
**Dependencies:** US-SQ-PROJ-03

As a user
I want one screen showing how all my projects are doing
So that SonarQube's second tab is useful, since it has no run history

**Acceptance Criteria**
- Scenario: The tab
  Given SonarQube is the active tool
  Then the second tab is "Overview", and Jenkins and GitHub Actions keep
  "History"
- Scenario: Content
  Then it shows counts of failing, warning, passing and not-analyzed
  projects, the totals of bugs, vulnerabilities and code smells, and the
  projects that need attention (failed before warning, worst first)
- Scenario: Honesty
  Then it never says all is well while verdicts are loading or failed to
  load, and says when it is based on only part of the project list

### US-SQ-LINK-01 — Open in SonarQube

**Priority:** Could
**Source:** owner's local-server test, 2026-11-08
**Dependencies:** US-SQ-QUALITY-03

As a user
I want to open a project or an issue in SonarQube's own web UI
So that I can see more than the app shows

**Acceptance Criteria**
- Scenario: Link
  Then a project opens `{base}/dashboard?id=KEY` and an issue opens
  `{base}/project/issues?id=KEY&issues=ISSUE&open=ISSUE`, in the browser,
  with a server path (`/sonar`) kept and keys encoded

---

## Planned work — documented 2026-11-09

Everything below is **proposed and not started**. It was listed for the owner
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
**Documented:** 2026-11-09 · **Status:** proposed, not started
**Dependencies:** US-SQ-QUALITY-03, US-SQ-OVERVIEW-01

As a user
I want to see the open issues assigned to me, across all projects
So that I know what is mine to fix without opening each project

**Acceptance Criteria**
- Scenario: Assigned to me
  Given I am signed in with a user token
  Then `GET api/issues/search?assignees=__me__&resolved=false` is called with no `componentKeys`, and the issues render in the same rows as the project issues list, each with its project name
- Scenario: Filter and page
  Given the list is large
  Then the type and severity filters re-query the server and "Load more" pages it, as in `US-SQ-QUALITY-03`
- Scenario: Nothing assigned
  Then "Nothing is assigned to you" is shown, not an empty list

**Notes**
- Lives as a section of the Overview tab or a screen reached from it; the choice is made in the batch's plan.
- SonarQube stops paging at 10,000 results; the existing cap and note apply.
- `__me__` as an assignee value is from the Web API docs; not yet checked against the owner's server.

### US-SQ-CE-01 — Analysis status: running, queued or failed

**Batch:** 1 · **Priority:** Should · **Effort:** S–M
**Documented:** 2026-11-09 · **Status:** proposed, not started
**Dependencies:** US-SQ-QUALITY-04

As a user
I want to see when a project is being analysed, is waiting, or its last analysis failed
So that I don't mistake a stale result for a current one

**Acceptance Criteria**
- Scenario: In progress
  Given a scan is running or queued
  Then `GET api/ce/component?component=KEY` shows it, and the project page and its card say "Analysing…" or "Queued"
- Scenario: Last analysis failed
  Given the newest background task failed
  Then the page says so, with the time, so the gate shown is understood to be from an older analysis
- Scenario: Quiet
  Given nothing is pending and the last task succeeded
  Then nothing extra is drawn

**Notes**
- No polling: checked when the page opens and on pull-to-refresh, as for the rest of the epic.
- Requires Browse permission on the project.

### US-SQ-QUALITY-07 — All gate conditions, passing ones too

**Batch:** 1 · **Priority:** Should · **Effort:** S
**Documented:** 2026-11-09 · **Status:** proposed, not started
**Dependencies:** US-SQ-QUALITY-01

As a user
I want to see every condition of the quality gate with its threshold and my value
So that I know how close a passing project is to failing

**Acceptance Criteria**
- Scenario: List
  Given the gate result has conditions
  Then each is listed with its metric, threshold, actual value and an OK or failed mark, failed ones first
- Scenario: No conditions
  Then "This gate has no conditions" is shown

**Notes**
- The conditions already arrive in `api/qualitygates/project_status`; this only stops hiding the passing ones.
- Today only failing conditions are listed, under "What failed"; that block stays.

### US-SQ-QUALITY-08 — New code versus overall code

**Batch:** 1 · **Priority:** Should · **Effort:** M
**Documented:** 2026-11-09 · **Status:** proposed, not started
**Dependencies:** US-SQ-QUALITY-02

As a user
I want to switch the measures between new code and overall code
So that I see the numbers the quality gate is actually judged on

**Acceptance Criteria**
- Scenario: Switch
  Given a project page
  Then a switch shows Overall (today's view) or New code (`new_bugs`, `new_vulnerabilities`, `new_code_smells`, `new_coverage`, `new_duplicated_lines_density`, `new_lines`)
- Scenario: No new-code period
  Given the project has no new-code period or no new code
  Then the switch says so instead of showing zeros

**Notes**
- How `api/measures/component` reports new-code values (a `period` object) varies by SonarQube version: **to be checked against the owner's server before the plan is final.**
- Measures stay labelled; a zero is never invented for a metric the server did not compute (see `US-SQ-QUALITY-02`).

### US-SQ-QUALITY-09 — Compare with the previous analysis

**Batch:** 1 · **Priority:** Could · **Effort:** M
**Documented:** 2026-11-09 · **Status:** proposed, not started
**Dependencies:** US-SQ-QUALITY-04

As a user
I want to see what changed since the previous analysis
So that I notice a regression right away

**Acceptance Criteria**
- Scenario: Delta
  Given at least two analyses
  Then each headline measure shows its change since the previous one (for example "+2 bugs", "coverage −1%"), worse in the failure colour
- Scenario: One analysis
  Then no change is shown, and "Not enough history yet" applies

**Notes**
- `GET api/measures/search_history?component=KEY&metrics=...&ps=2`.
- Direction of "worse" depends on the metric (more bugs is worse, more coverage is better).

## Batch 2 — Alerts (2026-11-09)

After batch 1. This is what makes the app useful when it is closed. It reuses the Jenkins build watch (`US-JX-10`): local notifications and a best-effort periodic check, with no push server.

### US-SQ-WATCH-01 — Notify me when a gate fails after a new scan

**Batch:** 2 · **Priority:** Should · **Effort:** M–L
**Documented:** 2026-11-09 · **Status:** proposed, not started
**Dependencies:** US-SQ-CE-01, `US-JX-10`'s watch plumbing

As a user
I want to be told when a project I watch fails its quality gate
So that I hear about a regression without opening the app

**Acceptance Criteria**
- Scenario: Watch a project
  Given I open a project
  Then I can turn on "Notify me when the gate fails"; it is stored on the device
- Scenario: Notified
  Given a watched project's newest analysis fails its gate
  Then one local notification names the project and what failed, once per analysis
- Scenario: Honest limits
  Given iOS decides when background work runs
  Then the screen says checks are best-effort and also run when the app is opened
- Scenario: Off
  Given I turn the last watch off
  Then the background check is unregistered

**Notes**
- Uses `flutter_local_notifications` and `workmanager`, both already approved in `CLAUDE.md` §3 (P11-24); no new dependency.
- The check reads the gate and the analysis date only, and holds no credential beyond what the app already stores.
- Cannot be verified in a test environment: needs a real device and a real analysis.

## Batch 3 — Deeper project views (2026-11-09)

Read-only depth for one project. Independent of each other; any can be taken alone.

### US-SQ-QUALITY-10 — Branch and pull request picker

**Batch:** 3 · **Priority:** Could · **Effort:** M
**Documented:** 2026-11-09 · **Status:** proposed, not started
**Dependencies:** US-SQ-QUALITY-02

As a user
I want to see the gate and measures for a branch or pull request
So that I can check a change before it merges

**Acceptance Criteria**
- Scenario: Choose
  Given the server lists more than the main branch (`GET api/project_branches/list`, `api/project_pull_requests/list`)
  Then a picker switches the page to that branch or pull request
- Scenario: Main only
  Given the server lists only the main branch
  Then no picker is shown

**Notes**
- **Edition-dependent**: SonarQube Community Build may only analyse the main branch; branches and pull requests need an edition that supports them. Hide the picker rather than show a dead one.
- Every project call then carries a `branch` or `pullRequest` parameter.

### US-SQ-HOTSPOT-01 — Security hotspots

**Batch:** 3 · **Priority:** Should · **Effort:** M
**Documented:** 2026-11-09 · **Status:** proposed, not started
**Dependencies:** US-SQ-QUALITY-03

As a user
I want to see a project's security hotspots and their review status
So that I know which security-sensitive code still needs a review

**Acceptance Criteria**
- Scenario: List
  Given a project
  Then `GET api/hotspots/search?project=KEY` lists hotspots, filterable by status (to review, reviewed), with file and line
- Scenario: Detail
  Given I open one
  Then its rule, vulnerability probability and the code around it are shown, as for an issue

**Notes**
- Reviewing a hotspot is a write and is `US-SQ-WRITE-04`, not this story.
- `api/hotspots/show` for the detail.

### US-SQ-QUALITY-11 — Trends over time

**Batch:** 3 · **Priority:** Could · **Effort:** M
**Documented:** 2026-11-09 · **Status:** proposed, not started
**Dependencies:** US-SQ-QUALITY-04

As a user
I want to see how coverage, bugs and debt moved over time
So that I can tell whether the project is getting better

**Acceptance Criteria**
- Scenario: Chart
  Given a project with several analyses
  Then a simple line chart of a chosen measure is drawn from `api/measures/search_history`, with the value of the touched point readable
- Scenario: Too little data
  Then "Not enough history yet" is shown

**Notes**
- No chart library is in the locked stack (`CLAUDE.md` §3): either a small custom painter, or a flagged dependency request. **Decide in the plan, don't add silently.**
- The chart must also be readable without colour (labels, not only a line).

### US-SQ-QUALITY-12 — Worst files

**Batch:** 3 · **Priority:** Could · **Effort:** M
**Documented:** 2026-11-09 · **Status:** proposed, not started
**Dependencies:** US-SQ-QUALITY-03

As a user
I want to see the files with the most issues, the least coverage or the most duplication
So that I know where to start

**Acceptance Criteria**
- Scenario: Ranking
  Given a project and a chosen measure
  Then `GET api/measures/component_tree` (file level, sorted by that measure) lists the ten worst files with their values
- Scenario: Open a file
  Then a tap shows that file's issues

**Notes**
- Uses `strategy=leaves`, `qualifiers=FIL`, `s=metric`, `metricSort`, `ps=10`.

### US-SQ-QUALITY-13 — Language breakdown

**Batch:** 3 · **Priority:** Could · **Effort:** S
**Documented:** 2026-11-09 · **Status:** proposed, not started
**Dependencies:** US-SQ-QUALITY-02

As a user
I want to see how the lines of code split by language
So that I understand what the project is made of

**Acceptance Criteria**
- Scenario: Breakdown
  Given the metric `ncloc_language_distribution` (for example `java=1200;js=340`)
  Then a list or bar shows each language with its lines and share
- Scenario: Missing
  Then the section is left out

**Notes**
- The metric is a `;`-separated string and needs parsing; keep that in the domain layer with tests.

### US-SQ-ISSUES-02 — Group issues by file, rule or severity

**Batch:** 3 · **Priority:** Could · **Effort:** S–M
**Documented:** 2026-11-09 · **Status:** proposed, not started
**Dependencies:** US-SQ-QUALITY-03

As a user
I want to group a project's issues
So that a long list becomes something I can scan

**Acceptance Criteria**
- Scenario: Group
  Given the issues list
  Then a control groups it by file, rule or severity, each group showing its count
- Scenario: Server side
  Then grouping uses the server's facets (`facets=files,rules,severities`) so counts are right beyond the first page

**Notes**
- Keeps the server-side filtering and paging of `US-SQ-QUALITY-03`.

## Batch 4 — Across projects and the server (2026-11-09)

Read-only views that span projects, plus the server itself.

### US-SQ-ISSUES-03 — Search issues across projects

**Batch:** 4 · **Priority:** Could · **Effort:** M
**Documented:** 2026-11-09 · **Status:** proposed, not started
**Dependencies:** US-SQ-ISSUES-01

As a user
I want to search issues by text or rule across every project
So that I can find a known problem wherever it is

**Acceptance Criteria**
- Scenario: Search
  Given a search term or rule
  Then `GET api/issues/search` with the matching parameters lists results across projects, server-filtered and paged
- Scenario: None
  Then "No issues match" is shown

**Notes**
- The exact text-search parameter is confirmed against the owner's server in the plan; not assumed here.

### US-SQ-SERVER-01 — Server health and version

**Batch:** 4 · **Priority:** Could · **Effort:** S
**Documented:** 2026-11-09 · **Status:** proposed, not started
**Dependencies:** US-SQ-CRED-04

As a user
I want to see my SonarQube server's version and status
So that I can tell a server problem from an app problem

**Acceptance Criteria**
- Scenario: Info
  Given an active credential
  Then the version (`api/server/version`) and status (`api/system/status`, for example UP or STARTING) are shown, with an edition hint where the server reports one
- Scenario: Unreachable
  Then the same error view as elsewhere, with a retry

**Notes**
- `api/system/health` and the background-task queue need administrator rights; shown only if the token allows it, never required.

### US-SQ-OVERVIEW-02 — Overview trend: are more projects failing?

**Batch:** 4 · **Priority:** Could · **Effort:** M
**Documented:** 2026-11-09 · **Status:** proposed, not started
**Dependencies:** US-SQ-OVERVIEW-01

As a user
I want to see whether the number of failing projects is going up or down
So that I see the direction, not only today's count

**Acceptance Criteria**
- Scenario: Trend
  Given the Overview has been opened on different days
  Then it shows the change in failing projects since the last snapshot
- Scenario: First time
  Then no trend is shown, with a note that it starts now

**Notes**
- SonarQube has no portfolio-level history for this, so the app would **store its own small snapshots on the device** (counts only, no secrets, in `shared_preferences`). Honest label: "since you last looked", not "over time".
- The alternative is computing it from each project's history, which costs one request per project; rejected for the rate-limit-style reasons of `US-GH-HIST-02`.

## Batch 5 — Shortcuts and offline (2026-11-09)

Convenience that mostly reuses plumbing the Jenkins work already built.

### US-SQ-PIN-01 — Pin projects

**Batch:** 5 · **Priority:** Should · **Effort:** S–M
**Documented:** 2026-11-09 · **Status:** proposed, not started
**Dependencies:** US-SQ-PROJ-03

As a user
I want to pin the projects I care about
So that they sit at the top of the list and the Overview

**Acceptance Criteria**
- Scenario: Pin
  Given a project card or page
  Then I can pin or unpin it; pinned projects sort first
- Scenario: Kept
  Then pins are remembered on the device per credential

**Notes**
- Pins are **local**, not SonarQube's server-side favourites (`api/favorites/*` would write to the server and is a `US-SQ-WRITE-*` concern). The plan may offer the server favourites later.
- Mirrors Jenkins pinned jobs (`US-JX-23`).

### US-SQ-WIDGET-01 — Home-screen widget for pinned projects

**Batch:** 5 · **Priority:** Could · **Effort:** L
**Documented:** 2026-11-09 · **Status:** proposed, not started
**Dependencies:** US-SQ-PIN-01, `US-JX-23`'s widget plumbing

As a user
I want to see my pinned projects' gate status on my home screen
So that I check them without opening the app

**Acceptance Criteria**
- Scenario: Widget
  Given pinned projects
  Then the widget lists each with its gate verdict and the time it was last updated
- Scenario: No credentials
  Then the widget holds no credential and never calls SonarQube itself; it shows a snapshot the app wrote

**Notes**
- Reuses the `home_widget` plumbing (iOS WidgetKit extension and the Android provider), approved in `CLAUDE.md` §3 (P11-26). Needs native work on both platforms, hence L.
- Only verifiable on a real device.

### US-SQ-OFFLINE-01 — Offline copy of the last data

**Batch:** 5 · **Priority:** Could · **Effort:** M
**Documented:** 2026-11-09 · **Status:** proposed, not started
**Dependencies:** US-SQ-PROJ-03

As a user
I want to see the last data I loaded when I have no connection
So that I can still check a project on the train

**Acceptance Criteria**
- Scenario: Cached
  Given I have loaded the project list and a project
  Then with no connection they show the saved copy, marked "Saved 2h ago"
- Scenario: Never secrets
  Then only non-secret project data is cached, in the same place and the same way as the Jenkins tree cache (`US-JX-20`), and is cleared on sign-out

**Notes**
- Reuses `path_provider` and the Jenkins cache pattern (`P11-23`).

### US-SQ-LINK-02 — Deep links to a project

**Batch:** 5 · **Priority:** Could · **Effort:** S
**Documented:** 2026-11-09 · **Status:** proposed, not started
**Dependencies:** US-SQ-LINK-01

As a user
I want to open a project in the app from a link
So that a teammate's message can take me straight to it

**Acceptance Criteria**
- Scenario: Open
  Given `jobtrigger://app/sonarqube/project?key=KEY`
  Then the app opens that project when SonarQube credentials exist, else explains what is missing
- Scenario: Guarded
  Then a link without a valid key lands on Home, like the other extra-only routes (AUD-51)

**Notes**
- Must not let a link choose the server or carry a token: the key only.

### US-SQ-ISSUES-04 — Copy and share an issue

**Batch:** 5 · **Priority:** Could · **Effort:** S
**Documented:** 2026-11-09 · **Status:** proposed, not started
**Dependencies:** US-SQ-QUALITY-06

As a user
I want to copy or share an issue's details
So that I can send it to a teammate

**Acceptance Criteria**
- Scenario: Share
  Given an issue page
  Then Copy and Share send the message, rule, location and the link from `US-SQ-LINK-01`
- Scenario: No secrets
  Then the text never contains a token

**Notes**
- Uses `share_plus`, already in the stack (P5-12).

## Batch 6 — Connecting the tools (2026-11-09)

Touches the Jenkins and GitHub screens, so it needs the owner's explicit go-ahead and `CLAUDE.md` §11 care: Jenkins is frozen except for bug fixes, and each tool is its own auth domain (`NFR-SEC-03`). The link between a Jenkins job (or GitHub repo) and a SonarQube project is **stored on the device, not on any server**, and never shares credentials between tools.

### US-SQ-XTOOL-01 — Show a project's SonarQube gate on a Jenkins build

**Batch:** 6 · **Priority:** Could · **Effort:** M–L
**Documented:** 2026-11-09 · **Status:** proposed, not started
**Dependencies:** US-SQ-PROJ-01, a Jenkins build page

As a user
I want to see the quality gate for the SonarQube project linked to a Jenkins job
So that I know whether a build also passed its quality gate

**Acceptance Criteria**
- Scenario: Link
  Given a Jenkins job
  Then I can link it to a SonarQube project once, on the device
- Scenario: Show
  Given a linked job
  Then its build page shows the gate verdict using the SonarQube credential, with a tap through to the project
- Scenario: Separate
  Given no SonarQube credential
  Then nothing is shown and Jenkins behaves exactly as before

**Notes**
- A change to the Jenkins build page is the one place this batch edits frozen Jenkins code; the plan must show the diff first.

### US-SQ-XTOOL-02 — Scan from Jenkins

**Batch:** 6 · **Priority:** Could · **Effort:** L
**Documented:** 2026-11-09 · **Status:** proposed, not started
**Dependencies:** US-SQ-XTOOL-01

As a user
I want to run the Jenkins job that scans a project, then watch the SonarQube result
So that a re-scan is one flow on my phone

**Acceptance Criteria**
- Scenario: Run
  Given a linked job
  Then "Scan now" uses the existing Jenkins trigger and confirmation flow
- Scenario: Follow
  Then the project page shows `US-SQ-CE-01`'s analysis status until the new result arrives

**Notes**
- Reuses Jenkins trigger and watch as they are; does not change them.

### US-SQ-XTOOL-03 — Show the gate beside a GitHub workflow run

**Batch:** 6 · **Priority:** Could · **Effort:** M–L
**Documented:** 2026-11-09 · **Status:** proposed, not started
**Dependencies:** US-SQ-PROJ-01, GitHub run detail

As a user
I want to see the SonarQube gate for the repository's linked project on a workflow run
So that I see build and quality together

**Acceptance Criteria**
- Scenario: Link and show
  Given a GitHub repo linked to a SonarQube project on the device
  Then a run's page shows the gate verdict, and nothing changes for an unlinked repo

**Notes**
- Same separation rules as `US-SQ-XTOOL-01`.

## Batch 7 — Changing data on the server (2026-11-09)

**The first writes in this epic.** The epic's stories so far are all `GET`s (see "Read-only, full stop" above, as built); this batch is where that stops being true, so it is last and needs its own explicit approval. A token whose user may modify issues is required; a 403 is reported with `SonarQubeAccessDeniedFailure`'s wording. Every action asks for confirmation, like Jenkins trigger and cancel, and none changes the screen before the server answers.

### US-SQ-WRITE-01 — Assign an issue

**Batch:** 7 · **Priority:** Could · **Effort:** M
**Documented:** 2026-11-09 · **Status:** proposed, not started
**Dependencies:** US-SQ-QUALITY-06

As a user
I want to assign an issue to someone, or to myself
So that it has an owner

**Acceptance Criteria**
- Scenario: Assign
  Given an issue page
  Then I can choose an assignee (`POST api/issues/assign`), confirm, and see it applied only after the server accepts it
- Scenario: Refused
  Given the token cannot modify issues
  Then the reason is shown and nothing changes

**Notes**
- Looking up assignable users (`api/users/search`) may need extra permission; the plan handles its absence.

### US-SQ-WRITE-02 — Change an issue's status

**Batch:** 7 · **Priority:** Could · **Effort:** M
**Documented:** 2026-11-09 · **Status:** proposed, not started
**Dependencies:** US-SQ-QUALITY-06

As a user
I want to confirm an issue, mark it a false positive, accept it or reopen it
So that the list reflects my decision

**Acceptance Criteria**
- Scenario: Transition
  Given an issue
  Then only the transitions the server offers (`POST api/issues/do_transition`: confirm, unconfirm, reopen, resolve, falsepositive, wontfix/accept) are shown, each with a confirmation

**Notes**
- The offered transitions come from the issue itself (`transitions`), never a fixed list in the app.

### US-SQ-WRITE-03 — Comment on an issue

**Batch:** 7 · **Priority:** Could · **Effort:** S–M
**Documented:** 2026-11-09 · **Status:** proposed, not started
**Dependencies:** US-SQ-QUALITY-06

As a user
I want to add a comment to an issue
So that I can leave context for the team

**Acceptance Criteria**
- Scenario: Comment
  Given an issue page
  Then I can write a comment (`POST api/issues/add_comment`); it is sent as a form value, never built into a URL by hand, and shown once saved

**Notes**
- Comments are visible to others: the field says so before sending.

### US-SQ-WRITE-04 — Review a security hotspot

**Batch:** 7 · **Priority:** Could · **Effort:** M
**Documented:** 2026-11-09 · **Status:** proposed, not started
**Dependencies:** US-SQ-HOTSPOT-01

As a user
I want to mark a hotspot safe, or fixed
So that the review queue shrinks

**Acceptance Criteria**
- Scenario: Review
  Given a hotspot
  Then I can set its status and resolution (`POST api/hotspots/change_status`) after a confirmation, with an optional comment

**Notes**
- Needs the permission to review hotspots on that project.

