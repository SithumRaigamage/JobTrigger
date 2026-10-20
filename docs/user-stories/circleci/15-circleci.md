# Epic: CC — CircleCI Integration

Promoted out of `10-out-of-scope-backlog.md`'s `BACKLOG-01`, filling in the
`CiTool.circleci` card that's existed as a disabled placeholder since
`ToolSelectionScreen` was built (`US-TOOL-02`). This is a **BA deliverable,
not an implementation plan** (per `CLAUDE.md` §9 and this story set's own
README): no code lands against this epic, no `CiTool.isAvailable` flip,
until it's separately promoted into an active phase the way GitHub Actions
was on 2026-09-14.

Endpoint paths and response shapes below are verified against CircleCI's
real REST API v2 docs (`circleci.com/docs/api/v2`) before writing these
stories, not guessed — same discipline epic GH used, including one real,
somewhat obscure limitation this epic is deliberately built around rather
than glossing over (see `US-CC-PROJ-01`).

**Scope note**: this epic covers **CircleCI Cloud** (`circleci.com`) only.
CircleCI also ships a self-hosted **Server** edition with a different base
URL and some API differences not verified here — explicitly deferred, not
silently assumed to work the same way, the same way epic GH scoped itself
to GitHub.com and not GitHub Enterprise Server.

## Why the shape differs from Jenkins/GitHub/GitLab

CircleCI's model is the closest of the three new tools to GitHub Actions
(project → run → job, not a folder tree), but with one extra layer and one
real API gap neither GitHub nor GitLab has:

- **An extra layer**: project → **pipeline** → one or more **workflows** →
  jobs. A single pipeline trigger (one push, or one manual API trigger) can
  fan out into *multiple parallel workflows* (e.g. a "build-and-test"
  workflow and a separately-gated "deploy" workflow both defined in the
  same `.circleci/config.yml` and started by the same pipeline) — GitHub
  Actions has no equivalent extra level between a run and its jobs.
- **Project identification is VCS-provider-scoped**: every CircleCI project
  is addressed by a slug of the form `{vcs-type}/{org-name}/{repo-name}`
  (e.g. `gh/octocat/hello-world` or `bb/octocat/hello-world`) — a CircleCI
  project is inherently tied to *which VCS host* it's connected through,
  unlike Jenkins/GitHub/GitLab credentials, which are each self-contained.
- **No project-listing endpoint exists in API v2** — a genuine, documented
  gap (CircleCI's v1 API had `GET /projects`; v2 never got a direct
  equivalent). `US-CC-PROJ-01` is built around the real, current
  workaround: `GET api/v2/me` returns the authenticated user's `projects`
  property, which this app filters client-side rather than pretending a
  proper search/list endpoint exists.
- **No dedicated log endpoint** — a job's `steps[].actions[].output_url`
  field (from the job-detail response) is a signed URL to that step's
  output, fetched as a separate request per step/action rather than one
  log endpoint for the whole job. Structurally closer to GitHub's
  redirect-based log fetch (`US-GH-LOG-01`) than GitLab's poll-anytime
  trace endpoint, but per-step rather than per-job.

**Auth**: CircleCI's REST API uses a `Circle-Token: <token>` header — a
fifth distinct auth header shape this app now speaks, alongside Jenkins'
Basic Auth, GitHub's Bearer token, GitLab's `PRIVATE-TOKEN`, and
SonarQube's Bearer-with-different-token-semantics (`NFR-SEC-03`'s
independent-auth-domains count keeps growing).

---

## Epic CC-CRED — CircleCI Credential Management

Mirrors `03-credential-management.md`'s shape for a fifth credential type.
Backend: a new `CircleCiCredential` Mongoose model/controller/routes in
`JobTrigger-Backend`, same `userId`-scoped ownership pattern as the other
four — fields: `label`, `token` (the Personal API Token — CircleCI Cloud
only, fixed `https://circleci.com` base, no configurable instance URL
unlike Jenkins/GitLab/SonarQube, per this epic's Cloud-only scope),
`isDefault`. **Not** a modification to any existing credential
model/controller — a fully separate parallel type.

### US-CC-CRED-01 — Add a CircleCI credential

**Priority:** Must
**Source:** new — CircleCI initiative
**Dependencies:** none

As a user
I want to add a CircleCI Personal API Token
So that the app can list and act on my projects' pipelines

**Acceptance Criteria**
- Scenario: Successful add
  Given I enter a label and the Personal API Token, and tap Save
  Then the credential is created via the new backend endpoint and appears
  in the CircleCI server list
- Scenario: Token validation
  Given the token field is empty
  Then client-side validation blocks submission with an inline message,
  before any network call (`NFR-SEC-02`) — like GitLab, CircleCI tokens
  have no single stable prefix to pattern-match, so this is a non-empty
  check only
- Scenario: Save fails
  Given the backend request fails
  Then an `AppFailure`-mapped message is shown and the form retains
  entered values

**Security & Privacy Notes**
- The token is never logged; `CircleCiCredential`'s domain-side
  `toString()` is redacted, mirroring every other credential type.
- Whether tokens are encrypted at rest is a backend concern, documented not
  assumed (`NFR-SEC-01`).

**UI / Design Notes**
- References `US-DESIGN-*` for the glass-card form treatment; mirrors
  `GitHubCredentialEditBottomSheet`'s shape exactly (both are single-token,
  fixed-base-URL credentials).

**Non-Functional Notes**
- `NFR-SEC-02` (client-side validation before any network call).

### US-CC-CRED-02 — Edit / delete a CircleCI credential

**Priority:** Must
**Source:** new — CircleCI initiative
**Dependencies:** US-CC-CRED-01

As a user
I want to edit or remove a saved CircleCI credential
So that I can rotate a token or remove an account I no longer use

**Acceptance Criteria**
- Scenario: Edit updates label/token
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

### US-CC-CRED-03 — Switch the active CircleCI credential

**Priority:** Must
**Source:** new — CircleCI initiative
**Dependencies:** US-CC-CRED-01

As a user
I want to switch which saved CircleCI credential is active
So that I can work against a different CircleCI account

**Acceptance Criteria**
- Scenario: Switching updates the active credential immediately
  Given I tap a non-active credential's radio indicator in the CircleCI
  section of Settings
  Then it becomes active and the project list (`US-CC-PROJ-01`) refetches
  against it
- Scenario: Independent from every other tool's active state
  Given Jenkins/GitHub/GitLab/SonarQube credentials are also configured
  Then switching the active CircleCI credential does not touch any of
  their active-selection state (`NFR-SEC-03`, now five independent
  auth/active-state domains)

**Security & Privacy Notes**
- References `NFR-SEC-03`.

**UI / Design Notes**
- References `US-DESIGN-*`; mirrors the existing settings sections'
  radio-indicator + switch-active-toast pattern.

**Non-Functional Notes**
- None beyond `NFR-SEC-03`.

### US-CC-CRED-04 — Test a CircleCI connection

**Priority:** Should
**Source:** new — CircleCI initiative
**Dependencies:** US-CC-CRED-01

As a user
I want to verify a CircleCI credential actually works before relying on it
So that I catch a bad or revoked token early

**Acceptance Criteria**
- Scenario: Successful test
  Given a valid token
  When I tap "Test Connection"
  Then `GET api/v2/me` is called (the same endpoint `US-CC-PROJ-01` uses
  for project discovery, so this doubles as a real connectivity check, not
  a throwaway ping) and the authenticated account's `login`/name is shown
  on success
- Scenario: Failed test
  Given an invalid or revoked token
  Then a clear `AppFailure`-mapped message is shown, and save remains
  allowed regardless (this is a nudge, not a gate)

**Security & Privacy Notes**
- None beyond the token-redaction notes above.

**UI / Design Notes**
- References `US-DESIGN-*`.

**Non-Functional Notes**
- None.

---

## Epic CC-PROJ — Project & Pipeline Browsing

### US-CC-PROJ-01 — Browse my CircleCI projects

**Priority:** Must
**Source:** new — CircleCI initiative
**Dependencies:** US-CC-CRED-03 (an active credential must exist)

As a user
I want to see a flat, searchable list of my CircleCI projects
So that I can find the one I want to check on

**Acceptance Criteria**
- Scenario: Successful load, via the real available workaround
  Given an active CircleCI credential
  Then `GET api/v2/me` is called and its `projects` property (a map of
  project slug → basic project info) is read to build the list — **there
  is no `GET`-a-list-of-projects endpoint in CircleCI's API v2** (a real,
  documented gap; v1's `GET /projects` was never replaced), so this is the
  actual, current mechanism, not a placeholder for a "real" endpoint that
  doesn't exist
- Scenario: A followed project with no recent activity
  Given a project slug present in `/me`'s `projects` map but with no
  pipeline data readily available
  Then it still appears in the list (from the `/me` data alone), and its
  pipeline history is fetched only once tapped (`US-CC-PROJ-02`), not
  eagerly for every project up front
- Scenario: No active credential
  Given no CircleCI credential is active
  Then a `NoActiveCircleCiCredentialView` gates the screen, mirroring
  `NoActiveGitHubCredentialView`/`NoActiveServerView`
- Scenario: Client-side search
  Given I type into the search field
  Then the list filters by project slug/name, case-insensitive,
  client-side, no per-keystroke network call (`NFR-PERF-02`)
- Scenario: Load fails
  Given the request fails
  Then an `AppFailure`-mapped error view with retry is shown

**UI / Design Notes**
- References `US-DESIGN-*`; mirrors `GitHubRepoScreen`'s glass-card
  list/search/pull-to-refresh structure. Each tile shows the VCS-type icon
  (GitHub/Bitbucket) parsed from the project slug's prefix, since that's
  meaningful context CircleCI's own model surfaces that the other tools
  don't have.

**Non-Functional Notes**
- `NFR-PERF-02` (client-side search, no per-keystroke network call).

### US-CC-PROJ-02 — Browse a project's pipelines

**Priority:** Must
**Source:** new — CircleCI initiative
**Dependencies:** US-CC-PROJ-01

As a user
I want to see a project's recent pipelines
So that I can check their status or drill into one

**Acceptance Criteria**
- Scenario: Successful load
  Given I tap a project
  Then `GET /project/{project-slug}/pipeline` is called and the pipeline
  list renders — `id`, `number`, `state`, `created_at`. `state` here is
  the pipeline-creation state (`created`/`errored`/`pending`), not a
  build-outcome status — the actual pass/fail signal lives one level down,
  on each pipeline's workflow(s) (`US-CC-RUN-01`), so each list row shows
  a summary rollup of its workflows' statuses, not `state` directly
- Scenario: Pagination
  Given more pipelines exist than one page
  Then a "load more" affordance follows the response's `next_page_token`
  via the `page-token` query param — token-based, not GitHub's `Link`
  header or GitLab's `page`/`per_page` numbers, a third distinct
  pagination shape this app now handles
- Scenario: Load fails
  Given the request fails
  Then an `AppFailure`-mapped error view with retry is shown

**UI / Design Notes**
- References `US-DESIGN-*`.

**Non-Functional Notes**
- None beyond standard `AppFailure` mapping.

---

## Epic CC-RUN — Workflows and Jobs: view, trigger, live status, cancel, rerun

### US-CC-RUN-01 — View a pipeline's workflows and jobs

**Priority:** Must
**Source:** new — CircleCI initiative
**Dependencies:** US-CC-PROJ-02

As a user
I want to see a pipeline's workflow(s) and each workflow's jobs
So that I know exactly what ran and what its outcome was

**Acceptance Criteria**
- Scenario: Successful load
  Given I tap a pipeline
  Then `GET /pipeline/{pipeline-id}/workflow` is called, and for each
  workflow returned, `GET /workflow/{id}/job` is called to list its jobs —
  each job's `name`, `status`, `job_number` renders, grouped by workflow.
  Multiple workflows under one pipeline (this epic's "extra layer," see
  the intro) each render as their own section, not flattened together
- Scenario: A single-workflow pipeline
  Given a pipeline with only one workflow (the common case)
  Then the workflow grouping still applies but reads naturally as "this
  pipeline's jobs," not an awkward single-item list-of-lists
- Scenario: Load fails
  Given either request fails
  Then an `AppFailure`-mapped error view with retry is shown

**UI / Design Notes**
- References `US-DESIGN-*`; reuses the shared stage-chip pattern
  (`P8-19`'s `stage_chip_row.dart`) for each workflow's job list, same as
  epics PIPE/GH/GL.

**Non-Functional Notes**
- None beyond standard `AppFailure` mapping.

### US-CC-RUN-02 — Trigger a new pipeline

**Priority:** Must
**Source:** new — CircleCI initiative
**Dependencies:** US-CC-PROJ-02

As a user
I want to trigger a new pipeline on a chosen branch
So that I can kick off a build without a laptop

**Acceptance Criteria**
- Scenario: Successful trigger
  Given I pick a branch and confirm
  Then `POST /project/{project-slug}/pipeline` is called with that
  `branch`, and the response returns the new pipeline's `id`/`number`
  directly — trackable immediately, like GitLab (`US-GL-RUN-02`) and
  unlike GitHub's 204-with-no-body dispatch (`US-GH-RUN-02`)
- Scenario: Optional pipeline parameters
  Given the project's `.circleci/config.yml` declares pipeline parameters
  Then an untyped key/value inputs list is offered (same flagged gap as
  `US-GH-RUN-02`/`US-GL-RUN-02`: CircleCI's trigger API accepts an
  arbitrary `parameters` object but doesn't expose the config's declared
  parameter *schema* for this app to render a typed form from)
- Scenario: Trigger fails
  Given the branch doesn't exist or the token lacks permission
  Then a clear, specific `AppFailure` message is shown, not a generic
  server error
- Scenario: Confirm-before-trigger
  Given I tap the trigger action
  Then a confirmation dialog appears before the request fires

**Security & Privacy Notes**
- None beyond the credential-scoped token permissions already governing
  what it can trigger.

**UI / Design Notes**
- References `US-DESIGN-*`; mirrors the GitHub/GitLab run-detail trigger
  form's layout, swapping in CircleCI's branch/parameters shape.

**Non-Functional Notes**
- None.

### US-CC-RUN-03 — Live workflow status polling

**Priority:** Must
**Source:** new — CircleCI initiative
**Dependencies:** US-CC-RUN-01

As a user
I want a running workflow's status to update live on screen
So that I don't have to manually refresh to see it finish

**Acceptance Criteria**
- Scenario: Polls while running
  Given a workflow in `running`/`on_hold` status
  Then the app polls `GET /workflow/{id}` every 5s, matching
  `BuildStatusPollingNotifier`'s cadence (`US-JOB-04`), stopping once
  `status` reaches a terminal value (`success`, `failed`, `error`,
  `canceled`)
- Scenario: Multiple workflows poll independently
  Given a pipeline with more than one workflow
  Then each workflow's polling starts/stops independently based on its own
  status, not gated on every workflow finishing together
- Scenario: Rate-limited or error response
  Given a `429` or repeated error mid-poll
  Then polling stops with a clear message rather than retrying into a
  worse state, mirroring `US-GH-RUN-03`/`US-GL-RUN-03`'s precaution
- Scenario: Timer cleanup
  Given the screen is disposed while polling is active
  Then all active timers are cancelled — no fetches after disposal, same
  `ref.onDispose` discipline as every other polling notifier in this app

**Non-Functional Notes**
- None beyond the polling cadence above.

### US-CC-RUN-04 — Cancel a running workflow or job

**Priority:** Must
**Source:** new — CircleCI initiative
**Dependencies:** US-CC-RUN-01

As a user
I want to cancel a running workflow, or an individual job within it
So that I can stop a build I triggered by mistake or no longer need

**Acceptance Criteria**
- Scenario: Cancel a whole workflow
  Given a running workflow
  When I confirm cancel
  Then `POST /workflow/{id}/cancel` is called — the response is a bare
  confirmation message with no updated status field, so (like GitHub's
  `US-GH-RUN-04`, unlike GitLab's synchronous response) the UI shows a
  transitional "cancelling…" state corrected by the next poll
- Scenario: Cancel a single job
  Given an individual running job within a still-viewable workflow
  When I confirm cancel on that job
  Then `POST /jobs/{job-id}/cancel` is called instead
- Scenario: Cancel fails
  Given the request fails
  Then an `AppFailure`-mapped message is shown and the displayed status is
  left untouched
- Scenario: Confirm-before-cancel
  Given I tap cancel
  Then a confirmation dialog appears before the request fires

**Non-Functional Notes**
- None.

### US-CC-RUN-05 — Rerun a workflow

**Priority:** Should
**Source:** new — CircleCI initiative
**Dependencies:** US-CC-RUN-01

As a user
I want to rerun a finished workflow, optionally from just its failed jobs
So that I can recover from a flaky failure without re-triggering the whole
pipeline

**Acceptance Criteria**
- Scenario: Rerun the whole workflow
  Given a finished workflow
  When I confirm "Rerun"
  Then `POST /workflow/{id}/rerun` is called with no special flags,
  re-running every job from the start
- Scenario: Rerun from failed jobs only
  Given a workflow with `status: failed`
  When I confirm "Rerun from failed", offered specifically in that state
  Then `POST /workflow/{id}/rerun` is called with `from_failed: true`,
  re-running only the jobs that didn't succeed — the same capability
  GitLab's pipeline retry offers (`US-GL-RUN-05`) and GitHub's dispatch
  model doesn't have
- Scenario: Rerun fails
  Given the request fails
  Then an `AppFailure`-mapped message is shown

**Non-Functional Notes**
- None.

---

## Epic CC-LOG — Job Step Output Viewing

### US-CC-LOG-01 — View a job's step-by-step output

**Priority:** Must
**Source:** new — CircleCI initiative
**Dependencies:** US-CC-RUN-01

As a user
I want to view a job's console output, broken down by step
So that I can see exactly which step failed and why

**Acceptance Criteria**
- Scenario: View a completed job's output
  Given I open a finished job
  Then `GET /project/{project-slug}/job/{job-number}` is called, returning
  a `steps[]` array; each step's `actions[]` entry carries an `output_url`
  — a signed URL fetched separately per step/action to retrieve that
  step's actual log content, rather than one endpoint for the whole job's
  combined output (this app fetches each visible step's `output_url`
  lazily, e.g. as the user expands it, not all of them eagerly up front)
- Scenario: View a running job's output
  Given a job still `running`
  Then already-completed steps' output is fetched and shown the same way;
  the currently-running step's `output_url` is polled the same cadence as
  `US-CC-RUN-03`'s status polling — CircleCI's per-step output URLs do
  update while a step is in progress, unlike GitHub's completed-only log
  download (`US-GH-LOG-01`), though not as simply pollable as GitLab's
  single always-current trace endpoint (`US-GL-LOG-01`)
- Scenario: A failed step is visually distinguished
  Given a step with a non-zero exit status
  Then it's visually flagged (matching this app's existing failed-status
  styling) and auto-expanded, so the failure is immediately visible
  without the user hunting through every step
- Scenario: Output fetch fails
  Given a request for a step's output fails (including an expired
  `output_url`, which CircleCI's signed URLs do)
  Then that step shows a retry action (re-fetching the job detail to get a
  fresh `output_url`, since the URL itself expires) rather than a dead
  error state

**UI / Design Notes**
- References `US-LOG-01`'s virtualized `ConsoleLogViewer` for rendering
  each step's content, composed inside a per-step expandable list rather
  than one flat log the way Jenkins/GitHub/GitLab render — CircleCI's
  step-structured data is the reason for this different presentation, not
  a stylistic choice.

**Non-Functional Notes**
- `NFR-PERF-03` (log rendering stays performant at scale — applies
  per-step here rather than to one combined log).

### US-CC-LOG-02 — Copy / share a step's output

**Priority:** Should
**Source:** new — CircleCI initiative
**Dependencies:** US-CC-LOG-01

As a user
I want to copy or share a specific step's output
So that I can send a teammate exactly the failing step, not the whole job

**Acceptance Criteria**
- Scenario: Copy/share available per step once loaded
  Given a step's output has loaded
  Then the same `share_plus`-based copy/share action from `US-LOG-03`/
  `US-GH-LOG-02`/`US-GL-LOG-02` is offered, scoped to that individual
  step's content — not the whole job, since CircleCI's data is already
  step-segmented and collapsing it back into one blob would lose exactly
  the granularity a teammate needs

**Non-Functional Notes**
- None.

---

## Epic CC-HIST — Pipeline History

### US-CC-HIST-01 — Per-project pipeline history

**Priority:** Should
**Source:** new — CircleCI initiative
**Dependencies:** US-CC-PROJ-02

As a user
I want a fuller history view of a project's past pipelines
So that I can review recent activity beyond the live list

**Acceptance Criteria**
- Scenario: Reuses existing history presentation
  Given a project with pipeline history
  Then it's presented reusing `HistoryTile`'s visual pattern (adapted for
  a CircleCI pipeline, showing its workflow-status rollup), same as
  `US-GH-HIST-01`/`US-GL-HIST-01` — this is the same data `US-CC-PROJ-02`
  already fetches, just a fuller-page presentation, not new data

**Non-Functional Notes**
- None.

### US-CC-HIST-02 — Global cross-project history feed

**Priority:** Could
**Source:** new — CircleCI initiative
**Dependencies:** US-CC-HIST-01

As a user
I want a single feed of recent pipeline activity across all my projects
So that I don't have to check each project individually

**Acceptance Criteria**
- Scenario: Fans out across followed projects, capped
  Given the `/me` project list (`US-CC-PROJ-01`) has many entries
  Then this fans out one pipelines-fetch per project, capped to the N
  most-recently-active projects rather than an unbounded fan-out — same
  explicit scope-down `US-GH-HIST-02`/`US-GL-HIST-02` applied for their
  respective rate limits; CircleCI's own rate limits need checking against
  current published values at implementation time rather than assumed
  from this doc

**Non-Functional Notes**
- Genuinely optional (`Could` priority) — do last, revisit whether it's
  worth the cost before starting, same as the equivalent GH/GL stories.
