# Epic: GL — GitLab CI Integration

Promoted out of `10-out-of-scope-backlog.md`'s `BACKLOG-01`, the same way
GitHub Actions was — a third real CI tool alongside Jenkins and GitHub
Actions, filling in the `CiTool.gitlab` card that's existed as a disabled
placeholder since `ToolSelectionScreen` was built (`US-TOOL-02`). This is a
**BA deliverable, not an implementation plan** (per `CLAUDE.md` §9 and this
story set's own README): no code lands against this epic, no `CiTool
.isAvailable` flip, until it's separately promoted into an active phase the
way GitHub Actions was on 2026-09-14.

Endpoint paths and response shapes below are verified against GitLab's real
REST API docs (`docs.gitlab.com/api/pipelines`, `docs.gitlab.com/api/jobs`,
API version v4) before writing these stories, not guessed — same discipline
epic GH used.

## Why the shape differs from Jenkins and GitHub Actions

GitLab's model sits structurally between the other two. Like GitHub, a
Personal Access Token grants access to a **flat list of projects** (`GET
/projects?membership=true`), not a Jenkins-style recursive folder tree — so
there's no "GL-TREE" epic for the same reason GH has no "GH-TREE" one. Unlike
GitHub, **GitLab supports self-hosted instances** (gitlab.com or a private
`gitlab.example.com`), so a GitLab credential needs a configurable base URL
alongside the token — closer to Jenkins' credential shape than GitHub's
fixed-`api.github.com` one. Each project has a flat list of **pipelines**
(not "workflow runs" — GitLab's terminology), and each pipeline has a flat
list of **jobs**.

**Auth**: GitLab's REST API uses a `PRIVATE-TOKEN: <token>` header, not
GitHub's `Authorization: Bearer <token>` — a third distinct auth header
shape this app now speaks, alongside Jenkins' HTTP Basic Auth and GitHub's
Bearer token (`NFR-SEC-03`'s "three independent auth failure domains"
precedent from epic GH extends to four once this ships).

**Log capability — GitLab's real advantage over GitHub**: `GET
/projects/:id/jobs/:job_id/trace` returns the job's current full plain-text
output on every call, including while the job is still `running` — safe to
poll repeatedly for a live-updating tail, unlike GitHub's
`.../jobs/{job_id}/logs`, which only works once a job is `completed` and
redirects to a short-lived download link with no partial-output story at
all. `US-GL-LOG-01` is written around this real capability, not scoped down
the way `US-GH-LOG-01` had to be.

---

## Epic GL-CRED — GitLab Credential Management

Mirrors `03-credential-management.md`'s shape for a third credential type.
Backend: a new `GitLabCredential` Mongoose model/controller/routes in
`JobTrigger-Backend`, same `userId`-scoped ownership pattern as
`JenkinsCredential`/`GitHubCredential` — fields: `label`, `baseUrl` (default
`https://gitlab.com`, editable for self-hosted instances), `token` (the
PAT), `defaultNamespace` (optional group/user filter for the project list,
mirroring `GitHubCredential.defaultOwner`), `isDefault`. **Not** a
modification to either existing credential model or controller — a fully
separate parallel type, per the same credential-architecture decision epic
GH made.

### US-GL-CRED-01 — Add a GitLab credential

**Priority:** Must
**Source:** new — GitLab CI initiative
**Dependencies:** none

As a user
I want to add a GitLab instance URL and Personal Access Token, scoped to an
optional group/namespace
So that the app can list and act on my projects' pipelines

**Acceptance Criteria**
- Scenario: Successful add against gitlab.com
  Given I leave the instance URL at its `https://gitlab.com` default, enter
  a label, the PAT, and (optionally) a default namespace filter, and tap
  Save
  Then the credential is created via the new backend endpoint and appears
  in the GitLab server list
- Scenario: Successful add against a self-hosted instance
  Given I change the instance URL to `https://gitlab.example.com`
  Then that URL, not the default, is what every subsequent request for this
  credential targets
- Scenario: PAT format validation
  Given the token field is empty
  Then client-side validation blocks submission with an inline message,
  before any network call (`NFR-SEC-02`) — GitLab PATs have no single
  stable prefix to pattern-match the way GitHub's `ghp_`/`github_pat_` do,
  so this is a non-empty check only, not a format check
- Scenario: Instance URL validation
  Given the instance URL field is empty or not a well-formed URL
  Then client-side validation blocks submission with an inline message
- Scenario: Token lacks required scope
  Given the PAT is well-formed but the test-connection check
  (`US-GL-CRED-04`) reveals it lacks `api`/`read_api` scope
  Then save is still allowed (matching `US-CRED-02`/`US-GH-CRED-01`'s "test
  is a nudge, not a gate" precedent) but a warning is shown
- Scenario: Save fails
  Given the backend request fails
  Then an `AppFailure`-mapped message is shown and the form retains
  entered values

**Security & Privacy Notes**
- The PAT is never logged; `GitLabCredential`'s domain-side `toString()` is
  redacted, mirroring `JenkinsServer.secret`/`GitHubCredential.secret`.
- Whether PATs are encrypted at rest is a backend concern, documented not
  assumed — same flagged risk as Jenkins passwords and GitHub PATs
  (`NFR-SEC-01`).

**UI / Design Notes**
- References `US-DESIGN-*` for the glass-card form treatment; mirrors
  `GitHubCredentialEditBottomSheet`'s wide/narrow split exactly, with an
  added instance-URL field GitHub's form doesn't have.

**Non-Functional Notes**
- `NFR-SEC-02` (client-side validation before any network call).

### US-GL-CRED-02 — Edit / delete a GitLab credential

**Priority:** Must
**Source:** new — GitLab CI initiative
**Dependencies:** US-GL-CRED-01

As a user
I want to edit or remove a saved GitLab credential
So that I can rotate a token or drop an instance I no longer use

**Acceptance Criteria**
- Scenario: Edit updates label/URL/token/namespace
  Given I open an existing credential's edit sheet
  Then the PAT field is never pre-filled (`NFR-SEC-01`'s redaction
  mechanism), with "leave blank to keep the current token" copy, matching
  `US-CRED-03`/`US-GH-CRED-02`
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
  update/delete, same pattern as both existing credential types.

**UI / Design Notes**
- References `US-DESIGN-*`.

**Non-Functional Notes**
- None beyond `NFR-SEC-*` above.

### US-GL-CRED-03 — Switch the active GitLab credential

**Priority:** Must
**Source:** new — GitLab CI initiative
**Dependencies:** US-GL-CRED-01

As a user
I want to switch which saved GitLab credential is active
So that I can work against a different project namespace or instance

**Acceptance Criteria**
- Scenario: Switching updates the active credential immediately
  Given I tap a non-active credential's radio indicator in the GitLab
  section of Settings
  Then it becomes active and the project list (`US-GL-PROJ-01`) refetches
  against it
- Scenario: Independent from Jenkins/GitHub's active state
  Given a Jenkins server and a GitHub credential are also configured
  Then switching the active GitLab credential does not touch either of
  their active-selection state — three fully independent "active"
  notifiers, not a unified concept (`NFR-SEC-03`)

**Security & Privacy Notes**
- References `NFR-SEC-03`.

**UI / Design Notes**
- References `US-DESIGN-*`; mirrors the existing Jenkins/GitHub settings
  sections' radio-indicator + switch-active-toast pattern.

**Non-Functional Notes**
- None beyond `NFR-SEC-03`.

### US-GL-CRED-04 — Test a GitLab connection

**Priority:** Should
**Source:** new — GitLab CI initiative
**Dependencies:** US-GL-CRED-01

As a user
I want to verify a GitLab credential actually works before relying on it
So that I catch a bad token or wrong instance URL early

**Acceptance Criteria**
- Scenario: Successful test
  Given a valid instance URL and PAT
  When I tap "Test Connection"
  Then `GET {baseUrl}/api/v4/user` is called and the authenticated
  username is shown on success, mirroring `testJenkinsConnection`/
  `testGitHubConnection`'s pattern exactly
- Scenario: Failed test
  Given an invalid token or unreachable instance URL
  Then a clear `AppFailure`-mapped message is shown, and save remains
  allowed regardless (this is a nudge, not a gate)

**Security & Privacy Notes**
- None beyond the PAT-redaction notes above.

**UI / Design Notes**
- References `US-DESIGN-*`.

**Non-Functional Notes**
- None.

---

## Epic GL-PROJ — Project & Pipeline Browsing

### US-GL-PROJ-01 — Browse my GitLab projects

**Priority:** Must
**Source:** new — GitLab CI initiative
**Dependencies:** US-GL-CRED-03 (an active credential must exist)

As a user
I want to see a flat, searchable list of my GitLab projects
So that I can find the one I want to check on

**Acceptance Criteria**
- Scenario: Successful load
  Given an active GitLab credential
  Then `GET /projects?membership=true` (optionally filtered by
  `defaultNamespace` if set) is called and the project list renders —
  `name`, `path_with_namespace`, `default_branch`, `visibility`
- Scenario: No active credential
  Given no GitLab credential is active
  Then a `NoActiveGitLabCredentialView` gates the screen, mirroring
  `NoActiveGitHubCredentialView`/`NoActiveServerView`
- Scenario: Client-side search
  Given I type into the search field
  Then the list filters by `path_with_namespace`, case-insensitive,
  client-side, no per-keystroke network call (`NFR-PERF-02`), mirroring
  `US-GH-REPO-01`'s search behavior
- Scenario: Pagination
  Given the account has more than one page of projects (GitLab's default
  `per_page` is 20, paginated via `page`/`per_page` query params, not a
  `Link` header body wrapper the way GitHub nests `workflows[]`)
  Then the screen loads the first page and offers a "load more" affordance
  for subsequent pages, rather than silently truncating the list
- Scenario: Load fails
  Given the request fails
  Then an `AppFailure`-mapped error view with retry is shown

**UI / Design Notes**
- References `US-DESIGN-*`; mirrors `GitHubRepoScreen`'s glass-card
  list/search/pull-to-refresh structure, gated on `activeGitLabCredentialNotifierProvider`.

**Non-Functional Notes**
- `NFR-PERF-02` (client-side search, no per-keystroke network call).

### US-GL-PROJ-02 — Browse a project's pipelines

**Priority:** Must
**Source:** new — GitLab CI initiative
**Dependencies:** US-GL-PROJ-01

As a user
I want to see a project's recent pipelines
So that I can check their status or drill into one

**Acceptance Criteria**
- Scenario: Successful load
  Given I tap a project
  Then `GET /projects/:id/pipelines` is called and the pipeline list
  renders — `id`, `status`, `ref`, `sha` (short form shown), `created_at`
- Scenario: Status is visually distinguished
  Given pipelines with different `status` values (`success`, `failed`,
  `running`, `canceled`, `pending`, `skipped`, `manual`, etc.)
  Then each renders with a status-appropriate color/icon, matching the
  existing `StatusIndicator` pattern's approach to Jenkins' `color` field
  and GitHub's `conclusion`
- Scenario: Load fails
  Given the request fails
  Then an `AppFailure`-mapped error view with retry is shown

**UI / Design Notes**
- References `US-DESIGN-*`; reuses `StatusIndicator` extended for GitLab's
  status vocabulary rather than inventing a new status-chip widget.

**Non-Functional Notes**
- None beyond standard `AppFailure` mapping.

---

## Epic GL-RUN — Pipelines: view, trigger, live status, cancel, retry

### US-GL-RUN-01 — View pipeline detail and jobs

**Priority:** Must
**Source:** new — GitLab CI initiative
**Dependencies:** US-GL-PROJ-02

As a user
I want to see a pipeline's jobs and their individual statuses
So that I know exactly what's running or what failed

**Acceptance Criteria**
- Scenario: Successful load
  Given I tap a pipeline
  Then `GET /projects/:id/pipelines/:pipeline_id/jobs` is called and each
  job's `name`, `stage`, `status` renders, grouped/ordered by stage —
  structurally the same shape as a Jenkins pipeline's `stages[]`
  (`US-PIPE-04`) and GitHub's job `steps[]`, so the run-detail screen
  reuses the shared stage-chip UI pattern those two already established
  (`P8-19`'s promoted `stage_chip_row.dart`), not a new one
- Scenario: Load fails
  Given the request fails
  Then an `AppFailure`-mapped error view with retry is shown

**UI / Design Notes**
- References `US-DESIGN-*`; reuses the shared stage-chip widget.

**Non-Functional Notes**
- None beyond standard `AppFailure` mapping.

### US-GL-RUN-02 — Trigger a new pipeline

**Priority:** Must
**Source:** new — GitLab CI initiative
**Dependencies:** US-GL-PROJ-02

As a user
I want to trigger a new pipeline on a chosen branch/tag
So that I can kick off a build without a laptop

**Acceptance Criteria**
- Scenario: Successful trigger
  Given I pick a ref (defaulting to the project's `default_branch`) and
  confirm
  Then `POST /projects/:id/pipeline` is called with that `ref`, and on
  success the new pipeline's `id`/`status` is returned directly in the
  response body — unlike GitHub's 204-with-no-body dispatch
  (`US-GH-RUN-02`), GitLab's trigger response is immediately trackable, no
  "refresh and hope" step needed
- Scenario: Optional variables
  Given the project defines pipeline variables the user wants to override
  Then an untyped key/value inputs list is offered (GitLab's API accepts
  an arbitrary `variables` array; like `US-GH-RUN-02`, there's no declared
  schema to render a typed `ParameterForm` from)
- Scenario: Trigger fails
  Given the ref doesn't exist or the token lacks permission
  Then a clear, specific `AppFailure` message is shown, not a generic
  server error
- Scenario: Confirm-before-trigger
  Given I tap the trigger action
  Then a confirmation dialog appears before the request fires, mirroring
  `US-JOB-02`/`US-GH-RUN-02`'s existing pattern

**Security & Privacy Notes**
- None beyond the credential-scoped PAT permissions already governing what
  the token can trigger.

**UI / Design Notes**
- References `US-DESIGN-*`; mirrors the GitHub run-detail trigger form's
  layout (`US-GH-RUN-02`/`P8-17`), swapping in GitLab's ref/variables shape.

**Non-Functional Notes**
- None.

### US-GL-RUN-03 — Live pipeline status polling

**Priority:** Must
**Source:** new — GitLab CI initiative
**Dependencies:** US-GL-RUN-01

As a user
I want a running pipeline's status to update live on screen
So that I don't have to manually refresh to see it finish

**Acceptance Criteria**
- Scenario: Polls while running
  Given a pipeline in `running`/`pending` status
  Then the app polls `GET /projects/:id/pipelines/:pipeline_id` every 5s,
  matching `BuildStatusPollingNotifier`'s cadence (`US-JOB-04`), stopping
  once `status` reaches a terminal value (`success`, `failed`, `canceled`,
  `skipped`)
- Scenario: Rate-limited response
  Given a `429` response mid-poll
  Then polling stops with a clear message rather than retrying into a
  worse state, mirroring `US-GH-RUN-03`'s same precaution
- Scenario: Timer cleanup
  Given the screen is disposed while polling is active
  Then the timer is cancelled — no fetches after disposal, same
  `ref.onDispose` discipline as every other polling notifier in this app

**Non-Functional Notes**
- None beyond the polling cadence above.

### US-GL-RUN-04 — Cancel a running pipeline

**Priority:** Must
**Source:** new — GitLab CI initiative
**Dependencies:** US-GL-RUN-01

As a user
I want to cancel a pipeline that's still running
So that I can stop a build I triggered by mistake or no longer need

**Acceptance Criteria**
- Scenario: Successful cancel
  Given a running pipeline
  When I confirm cancel
  Then `POST /projects/:id/pipelines/:pipeline_id/cancel` is called; the
  response returns the pipeline's updated status directly (`canceling` or
  `canceled` depending on timing) — closer to Jenkins' optimistic-flip
  precedent (`US-JOB-05`) than GitHub's fully-async 202 with no immediate
  status (`US-GH-RUN-04`), since GitLab's cancel response is synchronous
- Scenario: Cancel fails
  Given the request fails
  Then an `AppFailure`-mapped message is shown and the pipeline's displayed
  status is left untouched
- Scenario: Confirm-before-cancel
  Given I tap cancel
  Then a confirmation dialog appears before the request fires

**Non-Functional Notes**
- None.

### US-GL-RUN-05 — Retry a failed pipeline or job

**Priority:** Should
**Source:** new — GitLab CI initiative
**Dependencies:** US-GL-RUN-01

As a user
I want to retry a failed pipeline or an individual failed job within it
So that I can recover from a flaky failure without re-triggering everything

**Acceptance Criteria**
- Scenario: Retry a whole pipeline
  Given a pipeline with `status: failed`
  When I confirm retry
  Then `POST /projects/:id/pipelines/:pipeline_id/retry` is called,
  re-running only the failed/canceled jobs — a capability neither Jenkins
  nor GitHub Actions' integration in this app currently exposes (Jenkins
  pipelines have a "replay" concept, `US-PIPE-05`, but no
  failed-jobs-only retry; GitHub's dispatch always re-triggers the whole
  workflow from scratch)
- Scenario: Retry a single job
  Given an individual failed job within a still-viewable pipeline
  When I confirm retry on that job
  Then `POST /projects/:id/jobs/:job_id/retry` is called instead
- Scenario: Retry fails
  Given the request fails
  Then an `AppFailure`-mapped message is shown

**Non-Functional Notes**
- None.

---

## Epic GL-LOG — Job Trace Viewing

### US-GL-LOG-01 — View a job's trace, live while running

**Priority:** Must
**Source:** new — GitLab CI initiative
**Dependencies:** US-GL-RUN-01

As a user
I want to view a job's console output, including while it's still running
So that I can watch a build progress the way I can with Jenkins

**Acceptance Criteria**
- Scenario: View a running job's trace
  Given a job in `running` status
  Then `GET /projects/:id/jobs/:job_id/trace` is polled (matching this
  app's existing progressive-log pattern, `US-LOG-01`) and each response's
  full current output is shown, appended/diffed against what's already
  rendered — GitLab's trace endpoint returns the complete log-so-far on
  every call, not an incremental chunk, so the client computes the diff
  itself rather than relying on a server-provided offset the way Jenkins'
  `progressiveText` (`X-Text-Size`) does
- Scenario: View a completed job's trace
  Given a job in a terminal status
  Then one final trace fetch renders the complete output, no further
  polling
- Scenario: Trace fetch fails
  Given the request fails
  Then an `AppFailure`-mapped error view with retry is shown, without
  losing whatever output was already rendered

**UI / Design Notes**
- References `US-LOG-01`'s virtualized `ConsoleLogViewer`, reused
  unmodified for rendering — only the fetch/diff strategy above it differs.

**Non-Functional Notes**
- `NFR-PERF-03` (log rendering stays performant at scale, same virtualized
  list requirement as Jenkins/GitHub logs).

### US-GL-LOG-02 — Copy / share a job's trace

**Priority:** Should
**Source:** new — GitLab CI initiative
**Dependencies:** US-GL-LOG-01

As a user
I want to copy or share a job's trace output
So that I can send it to a teammate without them needing GitLab access

**Acceptance Criteria**
- Scenario: Copy/share available once loaded
  Given a trace has loaded (fully or partially)
  Then the same `share_plus`-based copy/share action from `US-LOG-03`/
  `US-GH-LOG-02` is offered, unmodified

**Non-Functional Notes**
- None.

---

## Epic GL-HIST — Pipeline History

### US-GL-HIST-01 — Per-project pipeline history

**Priority:** Should
**Source:** new — GitLab CI initiative
**Dependencies:** US-GL-PROJ-02

As a user
I want a fuller history view of a project's past pipelines
So that I can review recent activity beyond the live list

**Acceptance Criteria**
- Scenario: Reuses existing history presentation
  Given a project with pipeline history
  Then it's presented reusing `HistoryTile`'s visual pattern (adapted for a
  GitLab pipeline), same as `US-GH-HIST-01` — this is the same data
  `US-GL-PROJ-02` already fetches, just a fuller-page presentation, not new
  data

**Non-Functional Notes**
- None.

### US-GL-HIST-02 — Global cross-project history feed

**Priority:** Could
**Source:** new — GitLab CI initiative
**Dependencies:** US-GL-HIST-01

As a user
I want a single feed of recent pipeline activity across all my projects
So that I don't have to check each project individually

**Acceptance Criteria**
- Scenario: Fans out across accessible projects, capped
  Given the account has access to many projects
  Then this fans out one pipelines-fetch per project, capped to the N
  most-recently-active projects rather than exhausting GitLab's rate limit
  on one screen — same explicit scope-down `US-GH-HIST-02` applied for
  GitHub's tighter 5,000/hr limit; GitLab.com's rate limits differ by plan
  and endpoint, so the exact cap needs re-checking against current limits
  at implementation time rather than assumed from this doc

**Non-Functional Notes**
- Genuinely optional (`Could` priority) — do last, revisit whether it's
  worth the rate-limit cost before starting, same as `US-GH-HIST-02`.
