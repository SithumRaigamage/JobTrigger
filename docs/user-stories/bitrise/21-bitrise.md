# Epic: BR — Bitrise Integration

A mobile-focused CI/CD service, proposed 2026-11-14. JobTrigger is a phone
app for engineers; Bitrise is where many mobile teams build their phone
apps. Its standout feature for this app is **installable artifacts**: a
finished iOS or Android build can be installed on the phone straight from
the build screen. This is a **BA deliverable, not an implementation plan**
(`CLAUDE.md` §9): no code, no `CiTool` change, until separately promoted.

**Scope flag (`CLAUDE.md` §7):** not in the original feature matrix or
`BACKLOG-01`.

## Verification status

Checked against Bitrise's API docs and OpenAPI reference on 2026-11-14:
- Base URL `https://api.bitrise.io/v0.1`.
- Auth header `Authorization: <personal access token>` — the raw token,
  **no `Bearer` prefix**.
- `POST /apps/{app-slug}/builds` with `hook_info: { type: "bitrise" }` and
  `build_params` (`branch`, `tag`, `commit_hash`, `workflow_id`, …) — at
  least one of tag/commit, branch, or workflow/pipeline id is required.
- `POST /apps/{app-slug}/builds/{build-slug}/abort` with `abort_reason`
  and `abort_with_success`.
- `GET /apps/{app-slug}/builds` with `branch`, `workflow` and `status`
  filters; it only returns builds from the **last 200 days** (older ones
  via `GET /apps/{app-slug}/archived-builds`).
- `GET /apps/{app-slug}/builds/{build-slug}/log`.
- Artifacts: list, get one, and `PATCH` an artifact's
  `is_public_page_enabled`.
- Build `status` is an integer: 0 = not finished, 1 = success,
  2 = failed, 3 = aborted (counted as failed), 4 = aborted with success.
- `POST /apps/{app-slug}/pipelines/{pipeline-id}/abort` exists for
  Bitrise pipelines (multi-workflow).

**Not yet checked:** `GET /me`, `GET /apps` paging fields, the exact shape
of the log response while a build is running (log chunks vs a raw-log
URL), and the artifact fields that carry the install-page URL. Marked
*(verify)* below.

## Why the shape differs

A token gives a **flat list of apps** (Bitrise's word for a project),
each with **builds**; a build runs one **workflow** from the app's
`bitrise.yml`. Bitrise **pipelines** group several workflows into stages.
Builds are identified by a string **slug**, not a number.

**Auth**: a fourth header shape — raw token in `Authorization` with no
scheme. The Dio interceptor for Bitrise must not add `Bearer`, and must be
its own client instance so it never sends the backend JWT or a Jenkins
Basic header.

---

## Epic BR-CRED — Bitrise Credential Management

New `BitriseCredential` backend model (`label`, `token`, `isDefault`),
`userId`-scoped. No base URL — Bitrise is cloud-only — so this mirrors
`GitHubCredential`'s shape, not GitLab's.

### US-BR-CRED-01 — Add a Bitrise credential

**Priority:** Must
**Source:** new — Bitrise initiative
**Dependencies:** none

As a user
I want to add a Bitrise personal access token
So that the app can list my apps and builds

**Acceptance Criteria**
- [ ] Scenario: Successful add → credential created, shown in Settings
- [ ] Scenario: Validation before any network call (`NFR-SEC-02`) — non-empty
- [ ] Scenario: Help text
  Then the sheet says where to create a token in Bitrise and recommends
  an expiry
- [ ] Scenario: Save fails → `AppFailure` message, values kept

**Security & Privacy Notes**
- Token never logged; redacted `toString()`.

### US-BR-CRED-02 — Edit / delete — same criteria as `US-GL-CRED-02`
### US-BR-CRED-03 — Switch active — same criteria as `US-GL-CRED-03` (`NFR-SEC-03`)

### US-BR-CRED-04 — Test a Bitrise connection

**Priority:** Should
**Dependencies:** US-BR-CRED-01

**Acceptance Criteria**
- [ ] Scenario: Successful test
  Then `GET /me` *(verify)* is called and the username is shown
- [ ] Scenario: Failed test does not block save

---

## Epic BR-APP — Apps and builds

### US-BR-APP-01 — Browse my Bitrise apps

**Priority:** Must
**Dependencies:** US-BR-CRED-03

**Acceptance Criteria**
- [ ] Scenario: Successful load
  Then `GET /apps` is called and each app shows its title, repo owner and
  project type (iOS, Android, Flutter, React Native…)
- [ ] Scenario: Paging
  Given more apps than one page
  Then the app follows the response's paging cursor *(verify field name)*
- [ ] Scenario: Client-side search (`NFR-PERF-02`)
- [ ] Scenario: No active credential → `NoActiveBitriseCredentialView`

### US-BR-APP-02 — An app's recent builds

**Priority:** Must
**Dependencies:** US-BR-APP-01

**Acceptance Criteria**
- [ ] Scenario: Successful load
  Then `GET /apps/{app-slug}/builds` is called; each build shows build
  number, workflow, branch, triggered-at and status
- [ ] Scenario: Status mapping
  Then status integers map to the shared `StatusIndicator`: 0 running,
  1 success, 2 failed, 3 aborted, 4 aborted (shown as success with an
  "aborted" note)
- [ ] Scenario: Filters
  Then branch and workflow filters use the API's `branch` and `workflow`
  query parameters
- [ ] Scenario: Older builds
  Given I scroll past 200 days
  Then the list explains older builds are archived and offers to load them
  from `archived-builds`, rather than looking empty

---

## Epic BR-RUN — Trigger, status, abort

### US-BR-RUN-01 — Trigger a build

**Priority:** Must
**Dependencies:** US-BR-APP-02

**Acceptance Criteria**
- [ ] Scenario: Trigger
  Given I pick a workflow and branch and confirm
  Then `POST /apps/{app-slug}/builds` is sent with
  `hook_info: { type: "bitrise" }` and `build_params: { branch,
  workflow_id }`, and the returned build slug opens the build detail
- [ ] Scenario: Workflow choices
  Then the workflow picker is filled from the workflows seen in recent
  builds, with free text allowed — the app does not parse `bitrise.yml`
- [ ] Scenario: Environment variables
  Then optional key/value pairs are sent as `build_params.environments`
  *(verify exact shape)*
- [ ] Scenario: Confirm before trigger
- [ ] Scenario: Trigger fails → specific `AppFailure` message

### US-BR-RUN-02 — Live build status

**Priority:** Must
**Dependencies:** US-BR-RUN-01

**Acceptance Criteria**
- [ ] Scenario: Polls every 5s while `status` is 0, stops on any other value
- [ ] Scenario: `429` stops polling with a message
- [ ] Scenario: Timer cleanup on dispose

### US-BR-RUN-03 — Abort a build

**Priority:** Must
**Dependencies:** US-BR-RUN-02

**Acceptance Criteria**
- [ ] Scenario: Abort
  Given a running build
  When I confirm Abort with an optional reason
  Then `POST /apps/{app-slug}/builds/{build-slug}/abort` is sent with
  `abort_reason` (default "Aborted from JobTrigger") and
  `abort_with_success: false`
- [ ] Scenario: Pipeline builds
  Given the build is part of a Bitrise pipeline
  Then the sheet also offers "Abort whole pipeline", which calls the
  pipeline abort endpoint

### US-BR-RUN-04 — Rebuild

**Priority:** Should
**Dependencies:** US-BR-RUN-01

**Acceptance Criteria**
- [ ] Scenario: Rebuild with the same parameters
  Given a finished build
  When I tap Rebuild and confirm
  Then a new trigger is sent using the build's `original_build_params`

---

## Epic BR-LOG — Build log

### US-BR-LOG-01 — View the build log

**Priority:** Must
**Dependencies:** US-BR-RUN-01

**Acceptance Criteria**
- [ ] Scenario: Running build
  Given status 0
  Then `GET /apps/{app-slug}/builds/{build-slug}/log` is polled and new
  log content appended *(verify: whether running builds return chunks
  with a timestamp to continue from)*
- [ ] Scenario: Finished build
  Then the full log is fetched once — if the API returns a short-lived
  raw-log download URL *(verify)*, the app downloads it straight away and
  never stores the URL
- [ ] Scenario: Rendered in `ConsoleLogViewer` (`NFR-PERF-03`)

### US-BR-LOG-02 — Copy / share — same as `US-LOG-03`

---

## Epic BR-ART — Artifacts

### US-BR-ART-01 — List a build's artifacts

**Priority:** Should
**Dependencies:** US-BR-APP-02

**Acceptance Criteria**
- [ ] Scenario: List
  Then the build's artifacts load with title, type (`ios-ipa`,
  `android-apk`, …) and size

### US-BR-ART-02 — Install a build on this phone

**Priority:** Should
**Dependencies:** US-BR-ART-01

As a mobile developer
I want to install the build I just made on my phone
So that I can test it right away

**Acceptance Criteria**
- [ ] Scenario: Install page exists
  Given an installable artifact whose public install page is enabled
  Then "Install on this device" opens that page in the browser
  (`url_launcher`) *(verify field name)*
- [ ] Scenario: Install page disabled
  Given the page is not enabled
  Then the app offers to enable it, with a confirmation explaining that
  anyone with the link can download the build until it is turned off; on
  confirm it sends `PATCH` with `is_public_page_enabled: true`
- [ ] Scenario: Wrong platform
  Given an `.ipa` on Android or an `.apk` on iOS
  Then the action is hidden

**Security & Privacy Notes**
- A public install page exposes a pre-release build to anyone with the
  link. The app never enables it without the explicit confirmation above,
  and offers "Turn off public page" afterwards.
