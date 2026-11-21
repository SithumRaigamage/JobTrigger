# Epic: ARGO — Argo CD Integration

A continuous-**delivery** tool, not a build-trigger tool — proposed
2026-11-14. Every other tool in this set (Jenkins, GitHub Actions, GitLab,
CircleCI, Azure DevOps) answers "did my build pass?". Argo CD answers "is
what's running in my cluster what Git says should be running, and is it
healthy?". Adding it lets JobTrigger cover the deploy half of CI/CD. This
is a **BA deliverable, not an implementation plan** (`CLAUDE.md` §9): no
code, no `CiTool` change, until separately promoted.

**Scope flag (`CLAUDE.md` §7):** not in the original feature matrix or
`BACKLOG-01`. Like SonarQube, it is structurally unlike the build tools, so
there is no ARGO-RUN in the Jenkins sense — see below.

## Verification status

Checked on 2026-11-14 against Argo CD API material (the official docs site
was not reachable from this session; checked through secondary references
that quote the API):
- Auth is a JWT in `Authorization: Bearer <token>`.
- `GET /api/v1/applications`, `GET /api/v1/applications/{name}`.
- `POST /api/v1/applications/{name}/sync` (body: `revision`, `prune`,
  `dryRun`, optional resource list).
- `DELETE /api/v1/applications/{name}/operation` (terminate a running sync).
- `POST /api/v1/applications/{name}/rollback` with `{ id }` — the history
  id, from `status.history[]`. (POST, not PUT.)
- RBAC: reading needs `applications, get`; sync needs `applications, sync`;
  rollback needs `applications, action/rollback`.

**Not yet checked:** `GET /api/v1/session/userinfo`,
`GET /api/v1/applications/{name}/resource-tree`, the pod-logs endpoint and
its query parameters, and the `/api/v1/stream/applications` watch stream.
Re-check all endpoints against the official Swagger at
`https://<argocd-server>/swagger-ui` on a real server before promotion.

## Why the shape differs

The unit is an **Application**, not a job or pipeline. Each Application
has two independent statuses:
- **Sync**: `Synced` / `OutOfSync` / `Unknown` — does the cluster match Git?
- **Health**: `Healthy` / `Progressing` / `Degraded` / `Suspended` /
  `Missing` / `Unknown` — is it working?

The actions are **sync** (apply Git to the cluster), **terminate** (stop a
sync in progress) and **rollback** (go back to an earlier synced revision).
There is no "trigger a build" and no build log; the logs worth showing are
the **pod logs** of the deployed workload.

**Reachability is the hard part.** Argo CD usually runs inside a
Kubernetes cluster, often not exposed to the internet. The phone must
reach the Argo CD server URL directly (no backend proxy, per
`docs/architecture.md`). Setup help text must point to
`docs/remote-access.md` (VPN / Tailscale / ingress) rather than implying
it will "just work".

**Self-signed certificates are common** on internal Argo CD installs. The
app must not silently disable TLS verification. See `US-ARGO-CRED-01`.

---

## Epic ARGO-CRED — Argo CD Credential Management

A new `ArgoCdCredential` backend model (`label`, `baseUrl`, `token`,
`defaultProject` optional, `isDefault`), `userId`-scoped, separate from
every existing credential type.

### US-ARGO-CRED-01 — Add an Argo CD server

**Priority:** Must
**Source:** new — Argo CD initiative
**Dependencies:** none

As a user
I want to add my Argo CD server URL and an API token
So that the app can show and act on my Applications

**Acceptance Criteria**
- [ ] Scenario: Successful add
  Given I enter a label, `https://argocd.example.com` and a token, and tap
  Save
  Then the credential is created and appears in the Argo CD section of
  Settings
- [ ] Scenario: Validation before any network call (`NFR-SEC-02`)
- [ ] Scenario: Help for getting a token
  Given I tap "How do I get a token?"
  Then the sheet explains creating a dedicated local account with the
  `apiKey` capability and generating a token for it
  (`argocd account generate-token --account <name>`), and recommends a
  read-plus-sync role, not admin
- [ ] Scenario: Self-signed certificate
  Given the server presents a certificate the phone doesn't trust
  Then the test connection fails with a message that names the cause
  ("the server's certificate isn't trusted") and links to how to install
  the CA on the phone — there is no "ignore certificate errors" toggle
- [ ] Scenario: Server not reachable
  Given the URL doesn't resolve or times out
  Then the message says the phone can't reach the server and links to the
  remote-access guide, rather than a generic network error

**Security & Privacy Notes**
- Token never logged; redacted `toString()`.
- Argo CD tokens can be issued without expiry. The help text recommends
  setting `--expires-in`.

**Non-Functional Notes**
- `NFR-SEC-01`, `NFR-SEC-02`.

### US-ARGO-CRED-02 — Edit / delete an Argo CD server

**Priority:** Must
**Dependencies:** US-ARGO-CRED-01

Same acceptance criteria as `US-GL-CRED-02`: token never pre-filled,
confirm before delete, active-credential fallback.

### US-ARGO-CRED-03 — Switch the active Argo CD server

**Priority:** Must
**Dependencies:** US-ARGO-CRED-01

Same as `US-GL-CRED-03`; independent of every other tool's active state
(`NFR-SEC-03`).

### US-ARGO-CRED-04 — Test an Argo CD connection

**Priority:** Should
**Dependencies:** US-ARGO-CRED-01

**Acceptance Criteria**
- [ ] Scenario: Successful test
  Then `GET {baseUrl}/api/v1/session/userinfo` *(verify)* is called and the
  logged-in account name is shown
- [ ] Scenario: Token lacks permission
  Given the token can authenticate but cannot list applications
  Then the message names the missing permission (`applications, get`)
- [ ] Scenario: Failed test does not block save

---

## Epic ARGO-APP — Applications

### US-ARGO-APP-01 — See all my Applications and their health

**Priority:** Must
**Source:** new — Argo CD initiative
**Dependencies:** US-ARGO-CRED-03

As a user
I want one list of my Applications showing sync and health
So that I can see at a glance whether anything in production is broken

**Acceptance Criteria**
- [ ] Scenario: Successful load
  Given an active credential
  Then `GET {baseUrl}/api/v1/applications` is called and each Application
  shows `metadata.name`, `spec.project`, destination namespace,
  `status.sync.status` and `status.health.status`
- [ ] Scenario: Two status badges, not one
  Then sync and health render as two separate chips — an app can be
  `Synced` and `Degraded` at the same time, and merging them into one
  colour would hide that
- [ ] Scenario: Problems first
  Then the default sort puts `Degraded`, `Missing` and `OutOfSync` apps at
  the top
- [ ] Scenario: Filter
  Given I pick a project or a health status
  Then the list filters client-side (`NFR-PERF-02`)
- [ ] Scenario: No active credential → `NoActiveArgoCdCredentialView`
- [ ] Scenario: Load fails → `AppFailure` error view with retry

**Non-Functional Notes**
- The list response can be large (it includes full status). If it is too
  heavy on real servers, request only the needed fields with the
  `fields` query parameter *(verify)*.

### US-ARGO-APP-02 — Application detail and resources

**Priority:** Must
**Dependencies:** US-ARGO-APP-01

As a user
I want to see an Application's revision and the resources it manages
So that I can find which part is unhealthy

**Acceptance Criteria**
- [ ] Scenario: Detail
  Given I tap an Application
  Then `GET {baseUrl}/api/v1/applications/{name}` is called and the screen
  shows the target revision, the synced revision (`status.sync.revision`),
  the repo URL and path, and the last operation's phase and message
- [ ] Scenario: Resources grouped by kind
  Then `GET .../applications/{name}/resource-tree` *(verify)* is called and
  resources render grouped by kind (Deployment, Service, Pod …) with each
  one's own health — a list, not the web UI's graph, which doesn't fit a
  phone screen
- [ ] Scenario: Unhealthy resource first
  Given a resource is `Degraded`
  Then its group is expanded and the resource is highlighted

### US-ARGO-APP-03 — Live status while a sync runs

**Priority:** Must
**Dependencies:** US-ARGO-APP-02

**Acceptance Criteria**
- [ ] Scenario: Polls during an operation
  Given `status.operationState.phase` is `Running`
  Then the app polls the Application every 5s and stops when the phase is
  `Succeeded`, `Failed`, `Error` or `Terminated`
- [ ] Scenario: Timer cleanup on dispose
- [ ] Scenario (Could): Watch stream
  Given polling proves too slow or heavy
  Then the server-sent-events stream `/api/v1/stream/applications`
  *(verify)* may replace polling — a separate decision, not default

---

## Epic ARGO-SYNC — Sync, terminate, rollback

### US-ARGO-SYNC-01 — Sync an Application

**Priority:** Must
**Source:** new — Argo CD initiative
**Dependencies:** US-ARGO-APP-02

As a user
I want to sync an OutOfSync Application
So that the cluster matches Git without opening a laptop

**Acceptance Criteria**
- [ ] Scenario: Sync
  Given I tap Sync and confirm
  Then `POST {baseUrl}/api/v1/applications/{name}/sync` is called and the
  screen switches to live status (`US-ARGO-APP-03`)
- [ ] Scenario: Options
  Then the sync sheet offers "Prune" (off by default) and "Dry run";
  enabling Prune shows a warning that resources missing from Git will be
  deleted
- [ ] Scenario: Dry run first (Should)
  Given I tap "Preview" in the sheet
  Then the same call is sent with `dryRun: true` and the result is shown
  without changing the cluster
- [ ] Scenario: Permission denied
  Given the token lacks `applications, sync`
  Then the message names that permission

**Security & Privacy Notes**
- Sync with Prune can delete production resources. Confirm dialog always;
  biometric gate (`US-JX-21`) when app lock is on.

### US-ARGO-SYNC-02 — Terminate a running sync

**Priority:** Should
**Dependencies:** US-ARGO-SYNC-01

**Acceptance Criteria**
- [ ] Scenario: Terminate
  Given an operation in `Running`
  When I confirm Terminate
  Then `DELETE {baseUrl}/api/v1/applications/{name}/operation` is called

### US-ARGO-SYNC-03 — Roll back to an earlier revision

**Priority:** Must
**Dependencies:** US-ARGO-HIST-01

As a user
I want to roll an Application back to a revision that worked
So that I can recover from a bad deploy fast

**Acceptance Criteria**
- [ ] Scenario: Rollback
  Given I pick an entry in the deployment history and confirm
  Then `POST {baseUrl}/api/v1/applications/{name}/rollback` is called with
  that entry's `id`
- [ ] Scenario: Auto-sync is on
  Given the Application has an automated sync policy
  Then the confirm dialog warns that Argo CD will sync forward again unless
  auto-sync is disabled — a rollback under auto-sync doesn't stick
- [ ] Scenario: Permission denied
  Given the token lacks `applications, action/rollback`
  Then the message names that permission

**Security & Privacy Notes**
- Confirm dialog always; biometric gate when app lock is on.

---

## Epic ARGO-LOG — Pod logs

### US-ARGO-LOG-01 — View a pod's logs

**Priority:** Should
**Dependencies:** US-ARGO-APP-02

As a user
I want to read the logs of a pod in an unhealthy Application
So that I can see why it is crashing

**Acceptance Criteria**
- [ ] Scenario: Logs for a pod
  Given I tap a Pod resource and pick a container
  Then the pod-logs endpoint `GET .../applications/{name}/logs`
  *(verify — parameters such as `podName`, `container`, `tailLines`)* is
  called with a tail of the last 500 lines, rendered in `ConsoleLogViewer`
- [ ] Scenario: Follow (Could)
  Then a "Follow" toggle streams new lines while the screen is open

**Security & Privacy Notes**
- Pod logs can contain secrets or customer data. They are shown only,
  never cached to disk; share/copy follows `US-LOG-03` with the same
  warning copy.

---

## Epic ARGO-HIST — Deployment history

### US-ARGO-HIST-01 — An Application's deployment history

**Priority:** Must
**Dependencies:** US-ARGO-APP-02

**Acceptance Criteria**
- [ ] Scenario: History list
  Then `status.history[]` from the Application response renders newest
  first: revision (short SHA), deployed-at time, and the entry `id` used by
  rollback — no extra request needed
- [ ] Scenario: Current revision marked
  Then the entry matching the synced revision is labelled "Current"
