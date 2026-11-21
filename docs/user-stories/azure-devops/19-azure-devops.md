# Epic: AZ — Azure DevOps Pipelines Integration

A fifth real CI tool alongside Jenkins, GitHub Actions, GitLab CI (docs-only)
and CircleCI (docs-only), proposed 2026-11-14. Azure DevOps is the default
CI/CD platform in a large share of enterprises and banks, which are the
buyers `docs/subscription/docs/pricing.md` targets for Pro. This is a
**BA deliverable, not an implementation plan** (per `CLAUDE.md` §9 and this
story set's own README): no code lands against this epic, no new `CiTool`
value or `isAvailable` flip, until it is separately promoted into an active
phase the way GitHub Actions and SonarQube were.

**Scope flag (`CLAUDE.md` §7):** Azure DevOps is not in the original
feature matrix or `BACKLOG-01`. Writing this epic records the proposal; it
does not approve it. Adding `CiTool.azureDevOps` is itself a change to
shared code (`ci_tool.dart`, tool selection) and needs its own approval.

## Verification status

Checked against Microsoft's REST reference on 2026-11-14:
- `POST https://dev.azure.com/{organization}/{project}/_apis/pipelines/{pipelineId}/runs?api-version=7.1`
  (run a pipeline; body `RunPipelineParameters` with `previewRun`,
  `resources`, `templateParameters`, `variables`).
- `GET .../_apis/pipelines/{pipelineId}/runs/{runId}` — note this one is
  documented at `api-version=7.1-preview.1`, not plain `7.1`.

**Not yet checked** (written from prior knowledge, must be verified before
promotion, unlike epic GL which was fully checked): the Build API endpoints
used for cancel, timeline, logs and stage retry, the approvals endpoints,
and `_apis/connectionData`. Each is marked *(verify)* where it appears.

## Why the shape differs from the other tools

Azure DevOps has a **three-level hierarchy**: organization → project →
pipeline. A credential is scoped to one organization; inside it the user
picks a project, then a pipeline. That is one level deeper than GitLab's
flat project list and much shallower than a Jenkins folder tree, so the
browsing epic is a two-step list, not a tree.

Two API families overlap. The newer **Pipelines API** (`_apis/pipelines`)
lists pipelines and starts runs. The older **Build API** (`_apis/build`)
still owns cancel, the stage/job/task **timeline**, logs and stage retry.
A pipeline run id and its build id are the same number, so the client can
move between them — but the data layer needs two data sources, not one.

**Auth**: HTTP Basic with an **empty username and the PAT as the password**
— the same header mechanism as Jenkins (`Authorization: Basic …`) but a
different credential shape. Self-hosted **Azure DevOps Server** uses a
collection URL (`https://ado.example.com/tfs/DefaultCollection`) instead of
`https://dev.azure.com/{org}`, so the credential stores a full base URL,
like GitLab's.

**Approvals — Azure's real advantage for a phone app**: pipelines that
deploy through environments often wait on a manual approval. Approving a
production deploy from a phone is the single most "mobile" action in this
epic, and it gets its own sub-epic (`AZ-APPR`).

---

## Epic AZ-CRED — Azure DevOps Credential Management

A new `AzureDevOpsCredential` Mongoose model/controller/routes in
`JobTrigger-Backend`, same `userId`-scoped ownership pattern as
`JenkinsCredential`/`GitHubCredential`. Fields: `label`, `baseUrl`
(`https://dev.azure.com/{org}` or a Server collection URL), `token` (PAT),
`defaultProject` (optional), `isDefault`. A fully separate parallel type,
not a modification of an existing credential model.

### US-AZ-CRED-01 — Add an Azure DevOps credential

**Priority:** Must
**Source:** new — Azure DevOps initiative
**Dependencies:** none

As a user
I want to add my Azure DevOps organization URL and a Personal Access Token
So that the app can list and run my pipelines

**Acceptance Criteria**
- [ ] Scenario: Successful add against Azure DevOps Services
  Given I enter `https://dev.azure.com/contoso`, a label and a PAT, and tap
  Save
  Then the credential is created via the new backend endpoint and appears
  in the Azure DevOps section of Settings
- [ ] Scenario: Organization name only
  Given I type just `contoso` in the organization field
  Then the form expands it to `https://dev.azure.com/contoso` before saving
  and shows the expanded URL so I can see what will be called
- [ ] Scenario: Self-hosted Azure DevOps Server
  Given I enter a full collection URL instead
  Then that URL, unchanged, is what every request for this credential
  targets
- [ ] Scenario: Validation before any network call
  Given the URL or token field is empty or the URL is malformed
  Then client-side validation blocks submission with an inline message
  (`NFR-SEC-02`) — PATs have no fixed prefix, so this is a non-empty check
- [ ] Scenario: Token lacks required scopes
  Given the test connection (`US-AZ-CRED-04`) shows the PAT cannot read
  builds
  Then save is still allowed with a warning naming the scopes needed
  (`Build (Read & execute)` at minimum) — a nudge, not a gate, matching
  `US-CRED-02`/`US-GH-CRED-01`
- [ ] Scenario: Save fails
  Given the backend request fails
  Then an `AppFailure`-mapped message is shown and the form keeps its
  values

**Security & Privacy Notes**
- The PAT is never logged; the domain entity's `toString()` is redacted,
  same as `JenkinsServer.secret`.
- The form's help text recommends a PAT scoped to one organization with
  only the scopes above, and an expiry date — not a full-access PAT.
- Microsoft has been tightening PAT policy (org admins can restrict or
  block PAT creation). The add flow must show a clear message when the
  organization rejects PATs, not a generic 401. *(verify the exact error
  shape at promotion)*

**UI / Design Notes**
- References `US-DESIGN-*`; mirrors the GitLab credential sheet (base URL
  + token), labelled "Organization URL".

**Non-Functional Notes**
- `NFR-SEC-01`, `NFR-SEC-02`.

### US-AZ-CRED-02 — Edit / delete an Azure DevOps credential

**Priority:** Must
**Source:** new — Azure DevOps initiative
**Dependencies:** US-AZ-CRED-01

As a user
I want to edit or remove a saved Azure DevOps credential
So that I can rotate an expiring PAT or drop an organization

**Acceptance Criteria**
- [ ] Scenario: Edit never pre-fills the token
  Given I open an existing credential's edit sheet
  Then the PAT field is empty with "leave blank to keep the current token"
  copy, matching `US-CRED-03`
- [ ] Scenario: Delete with confirmation
  Given I swipe-delete a credential
  Then a confirmation dialog appears before the backend delete fires
- [ ] Scenario: Deleting the active credential falls back
  Given the deleted credential was active
  Then the `isDefault` or first remaining credential becomes active, or the
  active state clears if none remain

**Security & Privacy Notes**
- Backend enforces `userId` ownership on every update/delete.

**Non-Functional Notes**
- None beyond `NFR-SEC-*`.

### US-AZ-CRED-03 — Switch the active Azure DevOps credential

**Priority:** Must
**Source:** new — Azure DevOps initiative
**Dependencies:** US-AZ-CRED-01

As a user
I want to switch between saved Azure DevOps organizations
So that I can work in a different organization

**Acceptance Criteria**
- [ ] Scenario: Switching refetches projects
  Given I select a non-active credential in Settings
  Then it becomes active and the project list (`US-AZ-PROJ-01`) refetches
- [ ] Scenario: Independent of other tools
  Given Jenkins, GitHub or SonarQube credentials are also active
  Then their active state is untouched (`NFR-SEC-03`)

**Non-Functional Notes**
- `NFR-SEC-03`.

### US-AZ-CRED-04 — Test an Azure DevOps connection

**Priority:** Should
**Source:** new — Azure DevOps initiative
**Dependencies:** US-AZ-CRED-01

As a user
I want to check a credential works before relying on it
So that I catch a wrong organization or expired PAT early

**Acceptance Criteria**
- [ ] Scenario: Successful test
  Given a valid URL and PAT
  When I tap "Test Connection"
  Then `GET {baseUrl}/_apis/connectionData` *(verify)* — or, if that is
  not suitable, `GET {baseUrl}/_apis/projects?api-version=7.1` — is called
  and the authenticated user's display name (or the project count) is shown
- [ ] Scenario: Expired PAT
  Given the PAT has expired
  Then the message says the token expired, not just "unauthorized", so the
  user knows to rotate it
- [ ] Scenario: Failed test does not block save

**Non-Functional Notes**
- None.

---

## Epic AZ-PROJ — Project & Pipeline Browsing

### US-AZ-PROJ-01 — Browse projects in my organization

**Priority:** Must
**Source:** new — Azure DevOps initiative
**Dependencies:** US-AZ-CRED-03

As a user
I want a searchable list of the projects in my organization
So that I can open the one I work in

**Acceptance Criteria**
- [ ] Scenario: Successful load
  Given an active credential
  Then `GET {baseUrl}/_apis/projects?api-version=7.1` is called and each
  project's `name` and `description` render
- [ ] Scenario: Default project skips the list
  Given the credential has a `defaultProject`
  Then the app opens straight into that project's pipelines, with a way
  back to the full project list
- [ ] Scenario: No active credential
  Then a `NoActiveAzureDevOpsCredentialView` gates the screen
- [ ] Scenario: Client-side search (`NFR-PERF-02`)
- [ ] Scenario: Continuation paging
  Given more projects than one response returns
  Then the app follows Azure's continuation token (returned in the
  `x-ms-continuationtoken` response header) *(verify)* to load more, rather
  than truncating
- [ ] Scenario: Load fails → `AppFailure` error view with retry

**Non-Functional Notes**
- `NFR-PERF-02`.

### US-AZ-PROJ-02 — Browse a project's pipelines

**Priority:** Must
**Source:** new — Azure DevOps initiative
**Dependencies:** US-AZ-PROJ-01

As a user
I want to see a project's pipelines and how each last ran
So that I can spot a broken one quickly

**Acceptance Criteria**
- [ ] Scenario: Successful load
  Given I open a project
  Then `GET {baseUrl}/{project}/_apis/pipelines?api-version=7.1` is called
  and each pipeline's `name` and `folder` render, grouped by folder
- [ ] Scenario: Latest run status
  Given a pipeline has runs
  Then its row shows the latest run's `state`/`result` using the shared
  `StatusIndicator`, extended for Azure's vocabulary: `state` is
  `inProgress`, `canceling` or `completed`; `result` is `succeeded`,
  `failed`, `canceled` or `unknown`
- [ ] Scenario: Load fails → `AppFailure` error view with retry

**UI / Design Notes**
- Folder grouping reuses the section-header style from the Jenkins tree,
  but stays a flat list — no drill-down navigation per folder.

**Non-Functional Notes**
- Fetching the latest run per pipeline is one extra call each; cap it to
  the visible rows and load lazily as the user scrolls.

---

## Epic AZ-RUN — Runs: view, trigger, live status, cancel, retry

### US-AZ-RUN-01 — View a run's stages, jobs and tasks

**Priority:** Must
**Source:** new — Azure DevOps initiative
**Dependencies:** US-AZ-PROJ-02

As a user
I want to see a run's stages and jobs with their statuses
So that I know exactly what is running or what failed

**Acceptance Criteria**
- [ ] Scenario: Successful load
  Given I tap a run
  Then `GET {baseUrl}/{project}/_apis/build/builds/{runId}/timeline`
  *(verify)* is called; its `records[]` (types `Stage`, `Phase`, `Job`,
  `Task`) are grouped into stage → job → task, and stages render with the
  shared stage-chip row (`stage_chip_row.dart`)
- [ ] Scenario: Failed task is easy to find
  Given a task has `result: failed`
  Then its stage and job are expanded by default and the task is
  highlighted, with a tap-through to its log (`US-AZ-LOG-01`)
- [ ] Scenario: Load fails → `AppFailure` error view with retry

**Non-Functional Notes**
- None beyond standard `AppFailure` mapping.

### US-AZ-RUN-02 — Run a pipeline

**Priority:** Must
**Source:** new — Azure DevOps initiative
**Dependencies:** US-AZ-PROJ-02

As a user
I want to start a pipeline run on a chosen branch with optional parameters
So that I can kick off a build or deploy without a laptop

**Acceptance Criteria**
- [ ] Scenario: Successful run
  Given I pick a branch (default: the repository's default branch) and
  confirm
  Then `POST {baseUrl}/{project}/_apis/pipelines/{pipelineId}/runs?api-version=7.1`
  is called with `resources.repositories.self.refName =
  "refs/heads/{branch}"`, and the response's run `id` and `state` are used
  to open the run detail directly — no "refresh and hope" step
- [ ] Scenario: Template parameters
  Given the pipeline's YAML declares parameters
  Then the app offers key/value inputs sent as `templateParameters`
  — the API does not return a typed parameter schema, so like
  `US-GH-RUN-02` this is an untyped list
- [ ] Scenario: Preview before run (Could)
  Given I tap "Preview"
  Then the same call is sent with `previewRun: true` and the returned final
  YAML is shown read-only, without creating a run
- [ ] Scenario: Confirm before run
  Then a confirmation dialog appears before the request fires
- [ ] Scenario: Run fails
  Given the branch doesn't exist or the PAT lacks "execute"
  Then a specific `AppFailure` message is shown

**Non-Functional Notes**
- None.

### US-AZ-RUN-03 — Live run status

**Priority:** Must
**Source:** new — Azure DevOps initiative
**Dependencies:** US-AZ-RUN-01

As a user
I want a running pipeline's status to update on screen
So that I don't have to refresh manually

**Acceptance Criteria**
- [ ] Scenario: Polls while running
  Given `state: inProgress`
  Then the app polls the run and its timeline every 5s, matching
  `BuildStatusPollingNotifier`, and stops when `state` is `completed`
- [ ] Scenario: Throttled response
  Given Azure returns `429` or a `Retry-After` header
  Then polling waits the stated time, and stops with a message if
  throttling continues — Azure rate-limits by usage, not a fixed count
- [ ] Scenario: Timer cleanup on dispose (`ref.onDispose`)

**Non-Functional Notes**
- None beyond the cadence above.

### US-AZ-RUN-04 — Cancel a run

**Priority:** Must
**Source:** new — Azure DevOps initiative
**Dependencies:** US-AZ-RUN-01

As a user
I want to cancel a run that is still going
So that I can stop a build I started by mistake

**Acceptance Criteria**
- [ ] Scenario: Successful cancel
  Given a run with `state: inProgress`
  When I confirm cancel
  Then `PATCH {baseUrl}/{project}/_apis/build/builds/{runId}` *(verify)*
  is sent with `{ "status": "cancelling" }` and the run shows `canceling`
  until polling reports `completed`/`canceled`
- [ ] Scenario: Cancel fails → `AppFailure` message, status left untouched
- [ ] Scenario: Confirm before cancel

**Non-Functional Notes**
- None.

### US-AZ-RUN-05 — Retry a failed stage

**Priority:** Should
**Source:** new — Azure DevOps initiative
**Dependencies:** US-AZ-RUN-01

As a user
I want to rerun only the stage that failed
So that a flaky test doesn't force a full rebuild

**Acceptance Criteria**
- [ ] Scenario: Retry a stage
  Given a completed run with a failed stage
  When I confirm "Retry stage" on it
  Then `PATCH {baseUrl}/{project}/_apis/build/builds/{runId}/stages/{stageRefName}`
  *(verify)* is sent with `{ "state": "retry" }`
- [ ] Scenario: Retry not offered where unsupported
  Given a classic (non-YAML) pipeline, where stage retry doesn't apply
  Then the action is hidden, not shown and then failed
- [ ] Scenario: Retry fails → `AppFailure` message

**Non-Functional Notes**
- None.

---

## Epic AZ-APPR — Approvals and checks

### US-AZ-APPR-01 — See runs waiting for my approval

**Priority:** Should
**Source:** new — Azure DevOps initiative
**Dependencies:** US-AZ-PROJ-01

As a user
I want one list of deployments waiting for my approval
So that I can unblock a release from my phone

**Acceptance Criteria**
- [ ] Scenario: Pending approvals load
  Given an active credential and project
  Then `GET {baseUrl}/{project}/_apis/pipelines/approvals?state=pending`
  *(verify)* is called and each approval shows the pipeline, run, stage,
  environment and how long it has waited
- [ ] Scenario: Badge on the run detail
  Given a run is waiting on an approval
  Then its stage shows a "Waiting for approval" chip that opens the
  approval

**Non-Functional Notes**
- None.

### US-AZ-APPR-02 — Approve or reject a deployment

**Priority:** Should
**Source:** new — Azure DevOps initiative
**Dependencies:** US-AZ-APPR-01

As an approver
I want to approve or reject a pending deployment with a comment
So that releases don't stall while I'm away from my desk

**Acceptance Criteria**
- [ ] Scenario: Approve
  Given a pending approval assigned to me
  When I tap Approve, add an optional comment and confirm
  Then `PATCH {baseUrl}/{project}/_apis/pipelines/approvals` *(verify)* is
  sent with `[{ approvalId, status: "approved", comment }]`
- [ ] Scenario: Reject requires a comment
  Given I tap Reject
  Then a comment is required before the confirm button enables
- [ ] Scenario: Biometric gate for production
  Given app lock is enabled (`US-JX-21`)
  Then approving asks for Face ID / fingerprint first, every time — an
  approval releases code to production and must not be one stray tap
- [ ] Scenario: Not my approval
  Given the approval is assigned to someone else
  Then the buttons are hidden and the assignee is shown

**Security & Privacy Notes**
- This is the highest-impact write action in the app. Confirm dialog +
  biometric gate are both required, not either/or.

**Non-Functional Notes**
- `NFR-SEC-*`.

---

## Epic AZ-LOG — Task Logs

### US-AZ-LOG-01 — View a task's log, live while running

**Priority:** Must
**Source:** new — Azure DevOps initiative
**Dependencies:** US-AZ-RUN-01

As a user
I want to read a task's log, including while it is running
So that I can follow a build the way I can with Jenkins

**Acceptance Criteria**
- [ ] Scenario: Log for a task
  Given a timeline record with a `log.id`
  Then `GET {baseUrl}/{project}/_apis/build/builds/{runId}/logs/{logId}`
  *(verify)* is called and rendered in the shared virtualized
  `ConsoleLogViewer`
- [ ] Scenario: Incremental fetch while running
  Given the task is still running
  Then the app requests only new lines using `startLine` *(verify)* from
  the last line it already has — closer to Jenkins' `progressiveText` than
  GitLab's full-trace-every-time
- [ ] Scenario: Fetch fails without losing rendered lines

**Non-Functional Notes**
- `NFR-PERF-03`.

### US-AZ-LOG-02 — Copy / share a log

**Priority:** Should
**Source:** new — Azure DevOps initiative
**Dependencies:** US-AZ-LOG-01

**Acceptance Criteria**
- [ ] Scenario: Same `share_plus` action as `US-LOG-03`, unmodified

---

## Epic AZ-HIST — Run History

### US-AZ-HIST-01 — Per-pipeline run history

**Priority:** Should
**Source:** new — Azure DevOps initiative
**Dependencies:** US-AZ-PROJ-02

**Acceptance Criteria**
- [ ] Scenario: History list
  Given I open a pipeline's history
  Then `GET {baseUrl}/{project}/_apis/pipelines/{pipelineId}/runs` is
  called and runs render with `HistoryTile`'s pattern (name, result,
  branch, created/finished time)

### US-AZ-HIST-02 — Project-wide recent runs

**Priority:** Could
**Source:** new — Azure DevOps initiative
**Dependencies:** US-AZ-HIST-01

**Acceptance Criteria**
- [ ] Scenario: One call, not a fan-out
  Given a project
  Then `GET {baseUrl}/{project}/_apis/build/builds?$top=50` *(verify)*
  returns recent runs across all pipelines in one request — unlike
  `US-GH-HIST-02`/`US-GL-HIST-02` there is no per-pipeline fan-out, so this
  is cheaper than its GitHub/GitLab equivalents
