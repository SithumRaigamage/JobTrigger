# Epic: GH — GitHub Actions Integration

This epic is new scope, not a port of anything in the original SwiftUI
app — it's the second real CI tool this app supports, filling in the
`CiTool.githubActions` card that's existed as a disabled placeholder since
`ToolSelectionScreen` was built (`US-TOOL-02`). Decided with the user
2026-09-14: **full parity** with the Jenkins feature set (not a read-only
MVP), a **Personal Access Token** auth model (not OAuth), a **new backend
`GitHubCredential` model** (not client-storage-only), and a **separate
parallel credential type** alongside `JenkinsServer` (not a unified
polymorphic `Credential`).

Per the architecture survey done before writing this epic: there is no
shared "CI job/build/credential" abstraction anywhere in the codebase
today. Every layer below the routing shell and glass UI components needs a
fully parallel implementation — domain entities, DTOs, a repository, a
network client (Bearer token, not Basic Auth; no CSRF crumb; GitHub's own
rate-limit/pagination model), and every screen from repo-list down. This
epic's stories are written to be implemented in the same layered
architecture (`docs/architecture.md`), reusing `GlassSurface`,
`ResponsiveCenter`, the `Result`/`AppFailure` pattern, and Riverpod notifier
conventions — not reusing any Jenkins domain/data code.

## Why the shape differs from the Jenkins epics

Jenkins is one server exposing a **recursive folder tree** of jobs. GitHub
Actions has no equivalent hierarchy: a Personal Access Token grants access
to a **flat list of repositories**, each repository has a **flat list of
workflows** (from `.github/workflows/*.yml`), each workflow has a
**flat list of runs**, and each run has a **flat list of jobs**, each job
has an ordered **list of steps**. There is no "TREE" epic here — `GH-REPO`
below is the closest equivalent, and it's a two-level pick (repo, then
workflow), not arbitrary-depth folder navigation. A job's `steps[]` (each
with its own `status`/`conclusion`) is structurally the same shape as a
Jenkins pipeline's `stages[]` (`US-PIPE-04`) — the run-detail screen reuses
that stage-chip UI pattern rather than inventing a new one.

**Verified against GitHub's real REST API docs** (`docs.github.com`,
API version `2022-11-28`) before writing these stories — endpoint paths and
JSON shapes below are not guessed. One real limitation that shapes several
stories: **GitHub has no progressive/live log-streaming endpoint** like
Jenkins' `logText/progressiveText`. `GET .../jobs/{job_id}/logs` returns a
302 redirect to a full plain-text file download (link expires in 1 minute),
with no offset/range parameter and no documented "X-More-Data" equivalent —
there's nothing to tail. `US-GH-LOG-01` is scoped around this constraint
explicitly rather than faking a live-tail experience GitHub's public API
doesn't support.

---

## Epic GH-CRED — GitHub Credential Management

Mirrors `docs/user-stories/03-credential-management.md`'s shape for a
second, structurally different credential type. Backend: a new
`GitHubCredential` Mongoose model/controller/routes in `JobTrigger-Backend`,
same `userId`-scoped pattern as `JenkinsCredential`
(`JobTrigger-Backend/models/JenkinsCredential.js`), not a modification to
that existing model or its routes.

### US-GH-CRED-01 — Add a GitHub credential

**Priority:** Must
**Source:** new — GitHub Actions initiative
**Dependencies:** none

As a user
I want to add a GitHub Personal Access Token, scoped to an account/org
So that the app can list and act on my repositories' workflows

**Acceptance Criteria**
- Scenario: Successful add
  Given I enter a label, the PAT, and (optionally) a default org/owner
  filter, and tap Save
  Then the credential is created via the new backend endpoint and appears
  in the GitHub server list
- Scenario: PAT format validation
  Given the token field is empty or obviously malformed (GitHub PATs are
  prefixed `ghp_`/`github_pat_` for classic/fine-grained tokens)
  Then client-side validation blocks submission with an inline message,
  before any network call (`NFR-SEC-02`)
- Scenario: Token lacks required scope
  Given the PAT is well-formed but the test-connection check (`US-GH-CRED-04`)
  reveals it lacks `repo`/`workflow` scope (classic) or Actions
  read/write permission (fine-grained)
  Then save is still allowed (matching `US-CRED-02`'s "test is a nudge, not
  a gate" precedent) but a warning is shown so the user isn't surprised
  later when triggering fails
- Scenario: Save fails
  Given the backend request fails
  Then an `AppFailure`-mapped message is shown and the form retains
  entered values

**Security & Privacy Notes**
- The PAT is the credential's `secret` — same handling as a Jenkins
  password (`NFR-SEC-01`): secure storage only on-device for anything
  cached locally, never logged, never in a redacted `toString()` gap.
- **Flagged risk (backend track):** whether the backend encrypts stored
  GitHub PATs at rest in MongoDB is a backend concern outside this epic's
  client-side scope — same posture as `US-CRED-02`'s existing flagged risk
  for Jenkins passwords, not assumed safe.

**UI / Design Notes**
- Same glass bottom-sheet form pattern as `ServerEditBottomSheet`
  (`US-CRED-02`/`03`), new `GitHubCredentialEditBottomSheet`.

**Non-Functional Notes**
- NFR-SEC-01, NFR-SEC-02, NFR-TEST-03

---

### US-GH-CRED-02 — Edit and delete a GitHub credential

**Priority:** Must
**Source:** new — GitHub Actions initiative
**Dependencies:** US-GH-CRED-01

As a user
I want to edit a saved GitHub credential's label/org filter or delete it
So that I can keep my saved accounts current

**Acceptance Criteria**
- Scenario: Edit label/org filter
  Given I open an existing credential and change its label or default org
  Then the update is saved via the backend, PAT field never pre-filled
  with the real secret (matches `US-CRED-03`)
- Scenario: Replace the PAT
  Given I paste a new token into the PAT field while editing
  Then the new token replaces the stored one on save
- Scenario: Delete requires confirmation
  Given I swipe-delete or tap delete on a credential
  Then a confirmation dialog is required (matches `US-CRED-04`) before the
  backend delete call fires
- Scenario: Deleting the active GitHub credential
  Given the credential being deleted is the currently active one
  Then the same fallback logic as `US-CRED-04`/`ActiveServerNotifier`
  applies, scoped to GitHub credentials only — falling back to another
  saved GitHub credential or an empty state, never touching the active
  Jenkins server

**Security & Privacy Notes**
- Same as US-GH-CRED-01.

**UI / Design Notes**
- Same list/swipe-delete pattern as `SettingsScreen`'s Jenkins server list,
  in a separate "GitHub" section (not merged into the Jenkins list — two
  visually distinct credential types, per the separate-parallel-model
  decision).

**Non-Functional Notes**
- NFR-SEC-01, NFR-TEST-03

---

### US-GH-CRED-03 — Switch the active GitHub credential

**Priority:** Must
**Source:** new — GitHub Actions initiative
**Dependencies:** US-GH-CRED-01

As a user with multiple saved GitHub credentials (e.g. personal + work org)
I want to switch which one is active
So that repo/workflow browsing reflects the account I'm currently working as

**Acceptance Criteria**
- Scenario: Switch succeeds
  Given I tap a non-active credential in the list
  Then it becomes active immediately (client-side, matching
  `ActiveServerNotifier`'s existing pattern — no backend "switch" call
  needed, same as Jenkins' `SettingsScreen._setActiveServer`), and a
  confirmation toast shows
- Scenario: Active GitHub credential is independent of active Jenkins server
  Given both an active Jenkins server and an active GitHub credential exist
  Then switching one never affects the other — they're two independent
  "active" concepts, not a single "active CI tool" selector

**Security & Privacy Notes**
- None beyond US-GH-CRED-01.

**UI / Design Notes**
- Radio-style indicator per row, matching the pattern just fixed for the
  Jenkins server list (not the original checkmark-only indicator).

**Non-Functional Notes**
- NFR-TEST-03

---

### US-GH-CRED-04 — Test a GitHub credential before trusting it

**Priority:** Must
**Source:** new — GitHub Actions initiative
**Dependencies:** none

As a user adding or editing a GitHub credential
I want to verify the token actually works before saving
So that I don't save a broken credential and discover it later

**Acceptance Criteria**
- Scenario: Valid token
  Given I tap "Test connection" with a PAT entered
  Then `GET https://api.github.com/user` is called with
  `Authorization: Bearer <PAT>`; success shows the authenticated
  username, confirming the token is live
- Scenario: Invalid/expired token
  Given the token is rejected (401)
  Then a clear `AuthFailure`-mapped message is shown, distinct from a
  network failure
- Scenario: Rate-limited
  Given the response is a 403 with `X-RateLimit-Remaining: 0`
  Then a specific "rate limited, try again later" message is shown rather
  than a generic server error — GitHub's rate-limit shape is distinct
  enough from Jenkins' error surface to warrant its own case in
  `AppFailure` handling for this client

**Security & Privacy Notes**
- Uses a throwaway `Dio` instance, same pattern as
  `testJenkinsConnection()` — never the active GitHub client, so testing a
  candidate token doesn't disturb an existing session.

**UI / Design Notes**
- Same inline status text pattern as `US-CRED-06`'s Jenkins test-connection
  UI.

**Non-Functional Notes**
- NFR-TEST-03

---

## Epic GH-REPO — Repository & Workflow Browsing

### US-GH-REPO-01 — View accessible repositories

**Priority:** Must
**Source:** new — GitHub Actions initiative
**Dependencies:** US-GH-CRED-01, US-GH-CRED-03

As a user with an active GitHub credential
I want to see the repositories that credential can access
So that I can pick one to browse its workflows

**Acceptance Criteria**
- Scenario: List loads
  Given an active GitHub credential
  Then `GET /user/repos?per_page=100&sort=updated` is called (paginated —
  GitHub returns `Link` headers for further pages; load more on scroll,
  not all pages upfront) and repos render name + owner + private/public
  indicator
- Scenario: Default org filter applied
  Given the credential has a default org/owner filter set
  (`US-GH-CRED-01`)
  Then the list is pre-filtered to that owner, with a visible way to clear
  the filter and see everything the token can reach
- Scenario: Empty / load failure
  Given the token has access to no repos, or the fetch fails
  Then the same empty-state / `AppFailure`+retry pattern as `US-TREE-01`
  applies

**Security & Privacy Notes**
- None beyond existing per-credential Bearer auth handling.

**UI / Design Notes**
- Reuses the glass card list pattern from `HomeScreen`'s job tiles, new
  `GitHubRepoScreen`.

**Non-Functional Notes**
- NFR-TEST-03, NFR-PERF-02 (client-side search filtering, once loaded —
  no per-keystroke network call, same discipline as `US-TREE-03`)

---

### US-GH-REPO-02 — View a repository's workflows

**Priority:** Must
**Source:** new — GitHub Actions initiative
**Dependencies:** US-GH-REPO-01

As a user who picked a repository
I want to see its workflows
So that I can pick one to view runs or trigger

**Acceptance Criteria**
- Scenario: List loads
  Given I tap a repo
  Then `GET /repos/{owner}/{repo}/actions/workflows` is called, rendering
  each workflow's `name` and `state` (`active`/`disabled_manually`/etc.)
- Scenario: Disabled workflow
  Given a workflow's `state` isn't `active`
  Then it's shown visually de-emphasized with a "disabled" label, and
  triggering it (`US-GH-RUN-02`) is blocked with an explanatory message
  rather than sent to fail server-side
- Scenario: No workflows / load failure
  Given the repo has no workflow files, or the fetch fails
  Then the same empty-state / `AppFailure`+retry pattern applies

**Security & Privacy Notes**
- None beyond existing auth handling.

**UI / Design Notes**
- Same glass list pattern as US-GH-REPO-01, one level deeper — not a
  recursive tree (see epic intro), so no breadcrumb component is needed
  here, just a simple back navigation.

**Non-Functional Notes**
- NFR-TEST-03

---

## Epic GH-RUN — Workflow Runs: View, Trigger, Live Status, Cancel

Mirrors `docs/user-stories/05-job-detail-build-trigger.md`'s shape. A
GitHub "workflow run" is the rough equivalent of a Jenkins "build."

### US-GH-RUN-01 — View a workflow's recent runs

**Priority:** Must
**Source:** new — GitHub Actions initiative
**Dependencies:** US-GH-REPO-02

As a user viewing a workflow
I want to see its recent runs and each one's outcome
So that I have context before deciding whether/how to trigger it again

**Acceptance Criteria**
- Scenario: Runs load
  Given I open a workflow
  Then `GET /repos/{owner}/{repo}/actions/workflows/{workflow_id}/runs`
  is called, rendering each run's `status` (`queued`/`in_progress`/
  `completed`/`waiting`/`requested`/`pending`) and, once `completed`, its
  `conclusion` (`success`/`failure`/`cancelled`/`skipped`/`timed_out`/
  `action_required`/`neutral`/`stale`) — **two separate fields**, not one,
  matching GitHub's actual API shape (distinct from Jenkins' single
  `result` string)
- Scenario: No runs yet / load failure
  Given the workflow has never run, or the fetch fails
  Then the same "no builds yet" / `AppFailure`+retry pattern as
  `US-JOB-01` applies

**Security & Privacy Notes**
- None beyond existing auth handling.

**UI / Design Notes**
- Status+conclusion pair rendered as one color+icon+text indicator (two
  GitHub fields collapsing to the same single visual language as Jenkins'
  `result`, so the UI doesn't need to teach users a second status model).

**Non-Functional Notes**
- NFR-TEST-03, NFR-A11Y-03

---

### US-GH-RUN-02 — Trigger a workflow run

**Priority:** Must
**Source:** new — GitHub Actions initiative
**Dependencies:** US-GH-RUN-01

As a user
I want to trigger a workflow, with inputs if it declares any
So that I can kick off a run from my phone

**Acceptance Criteria**
- Scenario: Workflow requires `workflow_dispatch` to be triggerable at all
  Given a workflow's YAML has no `on: workflow_dispatch:` trigger
  Then the app cannot detect this ahead of time from the REST API alone
  (GitHub doesn't expose parsed trigger config) — the Trigger action is
  always offered, and a 422 from the dispatch call surfaces as a clear
  "this workflow can't be triggered manually" message rather than a
  generic error, **flagged as a real UX gap versus Jenkins** (where
  `isParameterized`/parameterless triggerability is known upfront from
  `property[parameterDefinitions]`) rather than silently worked around
- Scenario: Branch/ref selection
  Given `workflow_dispatch` requires a target `ref` (branch/tag)
  Then the trigger form includes a ref field, defaulting to the repo's
  default branch (`GET /repos/{owner}/{repo}` → `default_branch`)
- Scenario: Trigger with inputs
  Given the workflow declares `workflow_dispatch.inputs` in its YAML
  (not discoverable via REST — **input names/types must be entered
  manually by the user**, since GitHub's API doesn't expose a workflow's
  parsed input schema the way Jenkins exposes `parameterDefinitions`)
  Then the form is a simple key/value list the user fills in themselves,
  sent as the `inputs` object — **a real, flagged parity gap**: unlike
  `US-JOB-03`'s typed parameter form (dropdown/switch/text per declared
  type), GitHub triggering here is untyped free-text key/value pairs,
  because the API genuinely doesn't expose more
- Scenario: Successful trigger
  Given I confirm
  Then `POST .../dispatches` is called; a 204 response means *accepted*,
  not *started* — GitHub's dispatch response carries no run ID, so the
  UI shows "Triggered — refreshing shortly" and refreshes the runs list
  (`US-GH-RUN-01`) rather than claiming to know the exact new run's
  identity immediately (a real difference from Jenkins' `Location`-header
  queue-item tracking, `US-PIPE-01` — GitHub's dispatch endpoint gives
  nothing to track by)
- Scenario: Confirmation before triggering
  Given the real side effects of triggering a live workflow
  Then a confirmation step is required, same rationale as `US-JOB-02`

**Security & Privacy Notes**
- Untyped input values are user-supplied text sent as JSON object values
  via the standard HTTP client's JSON encoding (never string-concatenated),
  same injection-prevention posture as `US-JOB-03`.

**UI / Design Notes**
- Trigger button + ref field + optional inputs list, on the workflow
  detail screen.

**Non-Functional Notes**
- NFR-SEC-04, NFR-TEST-03

---

### US-GH-RUN-03 — See live run status

**Priority:** Must
**Source:** new — GitHub Actions initiative
**Dependencies:** US-GH-RUN-02

As a user watching a run
I want its status to update automatically
So that I don't have to manually refresh to know when it finishes

**Acceptance Criteria**
- Scenario: Polling while not completed
  Given a run's `status` isn't `completed`
  Then the app polls `GET .../runs/{run_id}` every 5s (same cadence as
  `US-JOB-04`, no documented reason GitHub needs a different interval)
  until `status` becomes `completed`
- Scenario: Polling stops on completion or screen exit
  Given the run completes, or the user navigates away
  Then polling stops — same notifier-owned-timer/`ref.onDispose` discipline
  as `BuildStatusPollingNotifier`
- Scenario: Rate-limit awareness
  Given GitHub's REST API has a real hourly rate limit (5,000 req/hr for
  an authenticated PAT) that Jenkins (self-hosted, no such limit) doesn't
  have
  Then a 403 rate-limit response mid-poll stops polling with a clear
  message rather than retrying into a worse rate-limit state — **flagged
  as a real constraint this client must respect that has no Jenkins
  equivalent**

**Security & Privacy Notes**
- None beyond existing auth handling.

**UI / Design Notes**
- Same progress-indicator treatment as `US-JOB-04`'s job-detail card.

**Non-Functional Notes**
- NFR-PERF-01, NFR-TEST-03

---

### US-GH-RUN-04 — Cancel a running workflow run

**Priority:** Must
**Source:** new — GitHub Actions initiative
**Dependencies:** US-GH-RUN-03

As a user who triggered a run by mistake
I want to cancel it
So that I don't have to wait for it to finish or find a laptop

**Acceptance Criteria**
- Scenario: Successful cancel
  Given a run is in progress
  When I tap Cancel and confirm
  Then `POST .../runs/{run_id}/cancel` is called (202 Accepted — GitHub's
  cancel is itself asynchronous, the run doesn't stop instantly); the UI
  shows a "cancelling" transitional state (not an immediate optimistic
  `cancelled` flip like Jenkins' `US-JOB-05`, since GitHub's cancel is
  genuinely slower/eventual) until the next poll confirms the real
  `conclusion`
- Scenario: Confirmation required
  Given the same real-side-effect rationale as `US-JOB-05`
  Then a confirmation step is required
- Scenario: Cancel request fails
  Given the cancel call itself fails (network/auth)
  Then an `AppFailure`-mapped message is shown; no state is optimistically
  changed since GitHub's own response doesn't warrant it here

**Security & Privacy Notes**
- Same destructive-action safeguards as US-JOB-05.

**UI / Design Notes**
- Same cancel-button treatment as `US-JOB-05`, with the "cancelling…"
  transitional label reflecting GitHub's async cancel semantics.

**Non-Functional Notes**
- NFR-SEC-04, NFR-TEST-03

---

### US-GH-RUN-05 — View per-job step breakdown

**Priority:** Should
**Source:** new — GitHub Actions initiative
**Dependencies:** US-GH-RUN-01

As a user checking a run
I want to see each job's steps and their outcome
So that I can tell what failed without downloading the full log

**Acceptance Criteria**
- Scenario: Steps load
  Given a run has one or more jobs
  Then `GET .../runs/{run_id}/jobs` is called, and each job's `steps[]`
  (each with its own `status`/`conclusion`/`name`) renders as a chip row —
  **reuses the exact stage-chip UI pattern already built for Jenkins
  pipelines** (`US-PIPE-04`'s `_StageChipRow`), since the data shape
  (ordered list, each with status+conclusion+name) is structurally the
  same
- Scenario: Multiple jobs in one run
  Given a run has more than one job (a build matrix, or parallel jobs)
  Then each job's step list is shown as its own group, labeled with the
  job's `name`

**Security & Privacy Notes**
- None beyond existing auth handling.

**UI / Design Notes**
- Directly reuses `_StageChipRow`'s visual pattern (promote it out of
  `job_detail_screen.dart` into a shared widget if this story is
  implemented, rather than duplicating the chip-row code).

**Non-Functional Notes**
- NFR-TEST-03, NFR-A11Y-03

---

## Epic GH-LOG — Job Log Viewing

### US-GH-LOG-01 — View a job's log

**Priority:** Must
**Source:** new — GitHub Actions initiative
**Dependencies:** US-GH-RUN-05

As a user checking a job's outcome
I want to read its log
So that I can see what happened without a laptop

**Acceptance Criteria**
- Scenario: Completed job
  Given a job has `status: completed`
  Then `GET .../jobs/{job_id}/logs` is called, following the 302 redirect
  to fetch the plain-text log body, rendered in the same virtualized
  `ListView.builder` console viewer as `US-LOG-01` (reused as-is — the
  *rendering* is identical, only the *fetch mechanism* differs)
- Scenario: Job still in progress — no live tail
  Given a job's `status` isn't `completed`
  Then the screen shows an explicit "log available once this job
  finishes" state rather than attempting to poll a partial log — GitHub's
  logs endpoint has no documented offset/tail mechanism to poll safely
  (unlike Jenkins' `progressiveText`, see epic intro); a manual
  "check now" refresh action is offered instead of automatic polling, so
  the user isn't left with silently-stale expectations
  set by `US-LOG-01`'s live-while-building behavior
- Scenario: Redirect link expiry
  Given the redirect URL is time-limited (expires ~1 minute per GitHub's
  docs)
  Then the fetch-and-follow happens as one atomic repository-layer
  operation, never surfacing the intermediate redirect URL to the UI or
  caching it for later reuse
- Scenario: Load failure
  Given the log fetch fails
  Then the same `AppFailure`+retry pattern as `US-LOG-01` applies

**Security & Privacy Notes**
- Same inherent risk as `US-LOG-01`: console output is whatever the
  workflow itself printed, may contain accidentally-leaked secrets: the
  app cannot and does not redact GitHub-side log content, called out
  explicitly rather than assumed safe (`NFR-SEC-05`-style posture).

**UI / Design Notes**
- Reuses `ConsoleLogViewer` (`US-LOG-01`) unmodified for rendering; only
  the fetch (`GitHubRepository.fetchJobLog`, one-shot rather than
  progressive) differs from `BuildLogNotifier`'s polling loop.

**Non-Functional Notes**
- NFR-PERF-03, NFR-TEST-03

---

### US-GH-LOG-02 — Copy or share a job log

**Priority:** Should
**Source:** new — GitHub Actions initiative
**Dependencies:** US-GH-LOG-01

As a user
I want to copy or share a job's log text
So that I can send it to a teammate or paste it elsewhere

**Acceptance Criteria**
- Scenario: Copy / Share
  Given a log has loaded
  Then the same Copy-to-clipboard and Share-via-`share_plus` actions as
  `US-LOG-03` are available, operating on the full downloaded log text
  (never partial, since `US-GH-LOG-01` has no progressive/partial state)

**Security & Privacy Notes**
- Same first-share secret-exposure notice as `US-LOG-03`.

**UI / Design Notes**
- Identical action-button placement to `BuildLogScreen`'s existing
  copy/share icons.

**Non-Functional Notes**
- NFR-TEST-03

---

## Epic GH-HIST — Run History

### US-GH-HIST-01 — View a workflow's run history

**Priority:** Should
**Source:** new — GitHub Actions initiative
**Dependencies:** US-GH-RUN-01

As a user
I want a dedicated history view of a workflow's past runs
So that I can review trends without re-opening the workflow detail screen

**Acceptance Criteria**
- Scenario: History loads
  Given I open a workflow's history
  Then the same `GET .../workflows/{workflow_id}/runs` call as
  `US-GH-RUN-01` (paginated, most-recent-first — this *is* effectively
  the same data, so this screen is a fuller-page presentation of it, not
  a separate fetch with different parameters) renders as a scrollable list

**Security & Privacy Notes**
- None beyond existing auth handling.

**UI / Design Notes**
- Reuses `HistoryTile`'s visual pattern (status dot, title, timestamp),
  adapted for a `GitHubWorkflowRun` instead of a `JenkinsBuild`.

**Non-Functional Notes**
- NFR-TEST-03

---

### US-GH-HIST-02 — Global cross-repo run history

**Priority:** Could
**Source:** new — GitHub Actions initiative
**Dependencies:** US-GH-REPO-01, US-GH-RUN-01

As a user with several repos/workflows
I want a single global feed of recent runs across all of them
So that I don't have to check each repo individually

**Acceptance Criteria**
- Scenario: Feasibility gap, flagged rather than silently built differently
  Given GitHub's REST API has **no single endpoint** for "recent runs
  across every repo a token can access" (unlike Jenkins' `US-HIST-01`,
  which derives this for free from the already-fetched job tree)
  Then this story requires fanning out one `GET .../runs?per_page=5`
  call per accessible repository and merging client-side by timestamp —
  **explicitly scoped as `Could`, not `Must`**, because on an account
  with many repos this is O(n) requests against GitHub's 5,000/hr rate
  limit for one screen, a real cost Jenkins' equivalent doesn't have
  - Scenario: Rate-limit-aware fallback
    Given the repo count is large enough that fanning out risks the rate
    limit
    Then the feed caps how many repos it fans out to (e.g. the N most
    recently updated, from `US-GH-REPO-01`'s already-sorted list) rather
    than exhausting the rate limit on one screen

**Security & Privacy Notes**
- None beyond existing auth handling.

**UI / Design Notes**
- Same `HistoryTile`-based list as `GlobalHistoryScreen`, with an
  owner/repo prefix per entry (mirrors `jobName` prefix in the Jenkins
  version).

**Non-Functional Notes**
- NFR-TEST-03
