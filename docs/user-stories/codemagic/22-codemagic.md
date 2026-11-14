# Epic: CM — Codemagic Integration

A CI/CD service built for Flutter and mobile, proposed 2026-11-14.
JobTrigger is itself a Flutter app, and Codemagic is one of the most common
places Flutter teams build. This is a **BA deliverable, not an
implementation plan** (`CLAUDE.md` §9): no code, no `CiTool` change, until
separately promoted.

**Scope flag (`CLAUDE.md` §7):** not in the original feature matrix or
`BACKLOG-01`.

## Verification status

Checked against Codemagic's REST API docs on 2026-11-14:
- Base URL `https://api.codemagic.io`.
- Auth header **`x-auth-token: <API token>`**. The token is personal, and
  what it can do depends on the user's team role.
- `GET /apps`.
- `POST /builds` with `appId`, `workflowId`, `branch` (optional:
  `labels`, `environment`, `instanceType`); response `{ "buildId": … }`.
- `GET /builds/:id`.
- `POST /builds/:id/cancel` — returns `208 Already Reported` if the build
  already finished.
- The REST API **does not return workflow information for apps configured
  with `codemagic.yaml`**.
- Codemagic's docs say they are **moving to a new API**. The newer
  endpoints live under `/api/v3/…` (for example
  `GET /api/v3/builds/{buildId}` and `GET /api/v3/builds/{buildId}/actions`
  for per-step build actions).

**Decision needed at promotion:** build against the current REST API or
the new v3 API. This epic is written against the current API, with v3
noted where it is the only way to get something (per-step logs).

**Not yet checked:** the list-builds query parameters, build status
values, per-step log retrieval, and artifact public-URL creation. Marked
*(verify)* below.

## Why the shape differs

A token gives **apps**; each app has **workflows**; each build runs one
workflow on one branch. Builds have string ids.

**Auth — careful here**: `x-auth-token` is **the same header name the
JobTrigger backend uses for its own JWT** (`CLAUDE.md` §1). If one shared
Dio interceptor sets `x-auth-token`, the app could send the user's
JobTrigger session to Codemagic, or the Codemagic token to the backend.
The Codemagic client must be its own Dio instance with its own
interceptor, and a unit test must prove the backend JWT is never attached
to `api.codemagic.io` requests and vice versa.

**Workflow ids**: because the API doesn't list `codemagic.yaml` workflows,
the trigger form can't offer a reliable list. It uses workflows seen in
the app's recent builds plus free text.

---

## Epic CM-CRED — Codemagic Credential Management

New `CodemagicCredential` backend model (`label`, `token`, `isDefault`),
`userId`-scoped. Cloud-only, so no base URL.

### US-CM-CRED-01 — Add a Codemagic credential

**Priority:** Must
**Source:** new — Codemagic initiative
**Dependencies:** none

**Acceptance Criteria**
- Scenario: Successful add → created and shown in Settings
- Scenario: Validation before any network call (`NFR-SEC-02`)
- Scenario: Help text
  Then the sheet says the token is under Account settings → API token in
  Codemagic, and that it carries the user's full team role
- Scenario: Save fails → `AppFailure` message, values kept

**Security & Privacy Notes**
- Token never logged; redacted `toString()`.
- See the header-name collision above: separate Dio instance required.

### US-CM-CRED-02 — Edit / delete — same criteria as `US-GL-CRED-02`
### US-CM-CRED-03 — Switch active — same criteria as `US-GL-CRED-03` (`NFR-SEC-03`)

### US-CM-CRED-04 — Test a Codemagic connection

**Priority:** Should
**Dependencies:** US-CM-CRED-01

**Acceptance Criteria**
- Scenario: Successful test
  Then `GET /apps` is called and the number of apps is shown (no user
  endpoint is relied on until verified)
- Scenario: Failed test does not block save

---

## Epic CM-APP — Apps and builds

### US-CM-APP-01 — Browse my Codemagic apps

**Priority:** Must
**Dependencies:** US-CM-CRED-03

**Acceptance Criteria**
- Scenario: Successful load
  Then `GET /apps` is called and each app shows its name and repository
- Scenario: Client-side search (`NFR-PERF-02`)
- Scenario: No active credential → `NoActiveCodemagicCredentialView`

### US-CM-APP-02 — An app's recent builds

**Priority:** Must
**Dependencies:** US-CM-APP-01

**Acceptance Criteria**
- Scenario: Successful load
  Then the builds list endpoint, filtered to this app *(verify:
  `GET /builds?appId=…`)*, loads; each build shows workflow, branch,
  started-at and status
- Scenario: Status mapping
  Then Codemagic's status values *(verify the full set, e.g. queued,
  preparing, building, finishing, finished, failed, canceled, timeout)*
  map to the shared `StatusIndicator`

---

## Epic CM-RUN — Start, status, cancel

### US-CM-RUN-01 — Start a build

**Priority:** Must
**Dependencies:** US-CM-APP-02

**Acceptance Criteria**
- Scenario: Start
  Given I pick a workflow and branch and confirm
  Then `POST /builds` is sent with `appId`, `workflowId`, `branch`, and
  the returned `buildId` opens the build detail
- Scenario: Workflow picker
  Then choices come from workflows seen in recent builds, plus free text,
  with a note that Codemagic doesn't list `codemagic.yaml` workflows
- Scenario: Environment variables
  Then optional key/value pairs go in `environment` *(verify nesting —
  `environment.variables`)*
- Scenario: Confirm before start
- Scenario: Start fails → specific `AppFailure` message

### US-CM-RUN-02 — Live build status

**Priority:** Must
**Dependencies:** US-CM-RUN-01

**Acceptance Criteria**
- Scenario: Polls `GET /builds/:id` every 5s until a terminal status
- Scenario: Timer cleanup on dispose

### US-CM-RUN-03 — Cancel a build

**Priority:** Must
**Dependencies:** US-CM-RUN-02

**Acceptance Criteria**
- Scenario: Cancel
  When I confirm Cancel
  Then `POST /builds/:id/cancel` is called
- Scenario: Already finished
  Given the response is `208`
  Then the app says the build had already finished and refreshes, rather
  than showing an error

### US-CM-RUN-04 — Rebuild

**Priority:** Should
**Dependencies:** US-CM-RUN-01

**Acceptance Criteria**
- Scenario: Same app, workflow and branch are re-sent to `POST /builds`

---

## Epic CM-LOG — Build steps and logs

### US-CM-LOG-01 — See a build's steps

**Priority:** Must
**Dependencies:** US-CM-RUN-01

**Acceptance Criteria**
- Scenario: Steps
  Then the build's actions (steps) load — from the build response's
  actions list, or `GET /api/v3/builds/{buildId}/actions` if only the new
  API has them *(verify)* — and render with the shared stage-chip row

### US-CM-LOG-02 — Read a step's log

**Priority:** Should
**Dependencies:** US-CM-LOG-01

**Acceptance Criteria**
- Scenario: Step log
  Given I tap a step
  Then its log is fetched *(verify the endpoint — may be a per-action log
  URL)* and rendered in `ConsoleLogViewer`
- Scenario: Running step
  Then the log refreshes while the step runs, if the API supports partial
  logs; if it does not, the screen says "log available when this step
  finishes" instead of pretending to stream

### US-CM-LOG-03 — Copy / share — same as `US-LOG-03`

---

## Epic CM-ART — Artifacts

### US-CM-ART-01 — List and open a build's artifacts

**Priority:** Should
**Dependencies:** US-CM-APP-02

**Acceptance Criteria**
- Scenario: List
  Then the build's artifacts (from the build response) show name, type
  and size
- Scenario: Install on this device
  Given an `.ipa`/`.apk` matching the phone's platform
  When I tap "Install on this device"
  Then the app creates a short-lived public link *(verify endpoint, e.g.
  `POST /artifacts/:secureFilename/public-url` with an `expiresAt`)*, with
  expiry set to 1 hour, and opens it

**Security & Privacy Notes**
- Public artifact links let anyone with the URL download the build. Keep
  the expiry short and show it in the confirmation.
