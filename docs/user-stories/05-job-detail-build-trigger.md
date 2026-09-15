# Epic: JOB — Job Detail & Build Triggering

The core reason JobTrigger exists. Reads job detail via
`GET {jobURL}api/json?tree=property[parameterDefinitions[*]],healthReport[*],
lastBuild[*],builds[...]`, triggers via `POST {jobURL}build` or
`POST {jobURL}buildWithParameters`, polls every 5s while `lastBuild.building`
is true, and cancels via `POST {jobURL}{buildNumber}/stop`.

---

### US-JOB-01 — View job detail

**Priority:** Must
**Source:** tasks/phase-5-build-execution-logs-history.md (P5-01, P5-02, P5-03)
**Dependencies:** US-TREE-01

As a user
I want to open a job and see its description, health, last build status,
and recent build history
So that I have enough context to decide whether/how to trigger it

**Acceptance Criteria**
- Scenario: Detail loads successfully
  Given I tap a job from the tree or search results
  Then its description, health report, last build status, and recent
  builds list render from the job-detail fetch
- Scenario: Job with no build history
  Given the job has never been built
  Then this is shown explicitly ("no builds yet"), not as an error or a
  confusing empty last-build section
- Scenario: Load failure
  Given the job-detail fetch fails
  Then it maps to the correct `AppFailure` (per-server `AuthFailure`,
  `NetworkFailure`, `NotFoundFailure` if the job was deleted since I
  navigated here, or `ServerFailure`/`UnknownFailure`) with a retry action
- Scenario: Job deleted since navigating here
  Given the job no longer exists on the server (404 from Jenkins)
  Then a clear `NotFoundFailure`-mapped "this job no longer exists" message
  is shown rather than a generic error, and I'm offered a way back to the
  tree

**Security & Privacy Notes**
- None beyond the existing per-server auth handling.

**UI / Design Notes**
- Description/health/last-build sit in a glass card (US-DESIGN-01);
  status indicators follow US-DESIGN-05.

**Non-Functional Notes**
- NFR-TEST-02

---

### US-JOB-02 — Trigger a build with no parameters

**Priority:** Must
**Source:** tasks/phase-5-build-execution-logs-history.md (P5-05)
**Dependencies:** US-JOB-01

As a user
I want to trigger a parameterless job with one tap
So that I can kick off a build quickly from my phone

**Acceptance Criteria**
- Scenario: Successful trigger
  Given the job has no parameter definitions
  When I tap "Trigger build" and confirm
  Then `POST {jobURL}build` is called, a success acknowledgment is shown,
  and the job detail refreshes to reflect the new/queued build
- Scenario: Confirmation before triggering
  Given I tap "Trigger build"
  Then a confirmation step is required before the request is sent — this
  action has real side effects on a live system and must not be a single
  accidental tap
- Scenario: Trigger fails
  Given the trigger request fails (auth, network, or server error)
  Then an `AppFailure`-mapped message is shown, clearly distinguishing "the
  request failed to send" from "it was sent but Jenkins rejected it," and
  no false "build started" confirmation is ever shown before the request
  actually succeeds
- Scenario: Double-tap protection
  Given I tap "Trigger build" twice in quick succession
  Then only one build is triggered — the action is disabled/debounced while
  the request is in flight

**Security & Privacy Notes**
- Triggering a build is a state-changing action against a live CI/CD
  system; the confirmation step and double-tap protection above are the
  primary safeguards against unintended production impact from a mobile
  device.

**UI / Design Notes**
- Trigger button uses full accent-color contrast per US-DESIGN-02 (it's the
  primary action on the screen); confirmation dialog is a glass sheet
  consistent with US-AUTH-04/US-CRED-04.

**Non-Functional Notes**
- NFR-SEC-04, NFR-TEST-02

---

### US-JOB-03 — Trigger a build with parameters

**Priority:** Must
**Source:** tasks/phase-5-build-execution-logs-history.md (P5-04, P5-05)
**Dependencies:** US-JOB-01

As a user
I want to fill in a job's parameters (string, choice, boolean) before
triggering
So that I can run the job with the specific inputs I need, the same as I
would from the Jenkins web UI

**Acceptance Criteria**
- Scenario: Parameter form renders correctly per type
  Given the job defines string, choice, and/or boolean parameters
  Then the form renders the correct control per type (text field, dropdown/
  choice selector, toggle), each pre-filled with Jenkins' declared default
  value
- Scenario: Successful trigger with parameters
  Given I fill in (or accept defaults for) all parameters
  When I confirm
  Then all values are serialized to strings (matching Jenkins' expected
  form-encoding regardless of declared type, per `docs/data-models.md`) and
  sent via `POST {jobURL}buildWithParameters`
- Scenario: Required-looking fields left at default
  Given a parameter has no explicit default and I leave it blank
  Then the app still allows submission (Jenkins itself decides whether an
  empty value is valid) but the field visually indicates it's currently
  empty, so a blank submission is a deliberate choice, not an oversight
- Scenario: Parameter values are safely encoded
  Given a parameter value contains special characters (e.g. `&`, `=`,
  quotes, or shell-metacharacter-like text a user might paste)
  Then the value is form-encoded via the standard HTTP client encoding path
  (never string-concatenated into a raw URL/body), so it reaches Jenkins as
  the literal value with no injection into the request structure
- Scenario: Trigger fails
  Given the parameterized trigger request fails
  Then the same `AppFailure` handling and no-false-success guarantee from
  US-JOB-02 applies, and my entered parameter values are preserved so I
  don't have to re-enter them

**Security & Privacy Notes**
- Parameter values are user input flowing to an external system (Jenkins);
  correct form-encoding (see scenario above) is the injection-prevention
  control — this is a client-side transport-correctness concern, distinct
  from whatever the specific job script does with the values once Jenkins
  receives them (out of this app's control).
- Confirmation-before-trigger from US-JOB-02 applies here too.

**UI / Design Notes**
- Parameter form fields sit inside the same glass job-detail card; boolean
  toggles and choice selectors use the accent color for their active state.

**Non-Functional Notes**
- NFR-SEC-04, NFR-TEST-02

---

### US-JOB-04 — See live build status while a build is running

**Priority:** Must
**Source:** tasks/phase-5-build-execution-logs-history.md (P5-06, P5-07)
**Dependencies:** US-JOB-02 or US-JOB-03

As a user who just triggered (or is otherwise viewing) a running build
I want to see its status update automatically with a progress indicator
So that I don't have to manually refresh to know when it finishes

**Acceptance Criteria**
- Scenario: Polling starts while building
  Given the job's `lastBuild.building` is true
  Then the job detail screen polls every 5 seconds and updates status,
  duration, and a progress bar (computed from `timestamp`/
  `estimatedDuration`) without manual refresh
- Scenario: Polling stops when build finishes
  Given the build completes (result becomes SUCCESS/FAILURE/UNSTABLE/
  ABORTED)
  Then polling stops automatically and the final result/status color is
  shown
- Scenario: Polling stops on screen exit
  Given I navigate away from the job detail screen while a build is still
  running
  Then the polling timer is cancelled (owned and disposed by its notifier,
  not left running in the background against a screen no longer visible)
- Scenario: Poll request fails transiently
  Given a single poll request fails (e.g. brief network blip)
  Then the last known status remains displayed and polling retries on the
  next interval, rather than immediately showing a hard error for one
  missed poll
- Scenario: Progress bar with no estimated duration
  Given the job has no prior build history to estimate duration from
  Then the progress indicator shows an indeterminate/unknown-duration state
  rather than a misleading fixed percentage

**Security & Privacy Notes**
- None beyond standard per-server auth handling on each poll request.

**UI / Design Notes**
- Progress bar rendered on the glass job-detail card; per US-DESIGN-04, the
  card's blur is not re-computed every poll tick — only the progress value/
  status text repaints, to avoid unnecessary `BackdropFilter` re-renders
  every 5 seconds.

**Non-Functional Notes**
- NFR-PERF-01, NFR-TEST-02

---

### US-JOB-05 — Cancel a running build

**Priority:** Must
**Source:** tasks/phase-5-build-execution-logs-history.md (P5-08)
**Dependencies:** US-JOB-04

As a user who triggered a build by mistake or needs to stop one early
I want to cancel it from my phone
So that I don't have to wait for it to finish or find a laptop to stop it

**Acceptance Criteria**
- Scenario: Successful cancel
  Given a build is currently running
  When I tap "Cancel build" and confirm
  Then `POST {jobURL}{buildNumber}/stop` is called, the UI optimistically
  flips the local status to ABORTED immediately, and the next poll confirms
  (or corrects, if Jenkins didn't actually stop it) the real state
- Scenario: Confirmation required
  Given I tap "Cancel build"
  Then a confirmation step is required — same rationale as triggering: a
  real, disruptive action against a live system
- Scenario: Cancel request fails
  Given the stop request fails
  Then the optimistic ABORTED flip is reverted back to the actual polled
  state, and an `AppFailure`-mapped error explains the cancel didn't take
  effect — the UI never claims a build stopped when it didn't
- Scenario: Cancel a build already finished
  Given the build finishes (naturally) in the moment between me tapping
  cancel and the request completing
  Then the app handles this gracefully (no crash, no misleading "cancelled"
  state) and simply reflects the build's real final result

**Security & Privacy Notes**
- Same destructive-action safeguards as triggering (confirmation,
  no-false-success).

**UI / Design Notes**
- Cancel action uses a distinct (warning-toned, still accent-consistent)
  button styling from "trigger," so the two destructive-vs-constructive
  actions aren't visually confusable at a glance, especially at speed on a
  small screen.

**Non-Functional Notes**
- NFR-SEC-04, NFR-TEST-02
