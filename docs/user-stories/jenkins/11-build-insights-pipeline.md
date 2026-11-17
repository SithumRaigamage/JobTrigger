# Epic: PIPE — Build Insights & Pipeline Interaction

This epic is **new scope, not a port of the original SwiftUI app**. The old
app (`JenkinsAPIService.swift`, confirmed via its last version in git
history before deletion in commit `079188e`) never called any Jenkins
endpoint beyond what's already covered by epics CRED/TREE/JOB/LOG/HIST —
there is no parity gap to close there. These stories instead come from an
audit of what the Jenkins REST API offers that this app's original spec
never covered, scoped down to what fits "trigger/monitor/inspect a build
from a phone" (see `README.md`'s product goal) — deliberately excluding
admin-console territory (job create/rename/delete/disable, node/executor
management, config.xml editing, view/tab management).

As with `US-DESIGN-*` and glassmorphism, this epic is layered onto an
already-complete app, not required to reach the original migration's
definition of done — it does not appear in `README.md`'s parity
traceability table, which stays scoped to the original 13 rows from
`docs/migration-strategy.md`.

One story in this epic (`US-PIPE-05`) and one cross-cutting NFR
(`NFR-SEC-06`, in `09-non-functional-security.md`) are a **correctness
fix**, not new UI: the app's existing `build`/`buildWithParameters`/`stop`
POSTs never attach a CSRF crumb, so any Jenkins instance with CSRF
protection on (the modern default) silently rejects them today.

---

### US-PIPE-01 — See queue status while a build waits for an executor

**Priority:** Should
**Source:** new — feature audit, not in any Phase 0–6 task
**Dependencies:** US-JOB-02, US-JOB-03

As a user who just triggered a build
I want to see that it's queued and waiting for a free executor, not just
silence
So that I don't think my tap didn't work when Jenkins simply hasn't started
the build yet

**Acceptance Criteria**
- Scenario: Build enters the queue
  Given I trigger a build and Jenkins accepts it but no executor is free yet
  Then the job detail screen shows a "queued" state (fetched from
  `GET {jobURL}/queue/api/json` — or the job-level queue item Jenkins
  returns right after a trigger) distinct from both "not building" and
  "building"
- Scenario: Queued build starts
  Given a queued item becomes a running build
  Then the screen transitions from "queued" to the existing "building" state
  (US-JOB-04) automatically, without a manual refresh
- Scenario: Queue reason is shown when available
  Given Jenkins reports why a build is blocked/waiting (e.g. quiet period,
  resource lock, another build of the same job already running)
  Then that reason text is shown alongside the "queued" state when present
- Scenario: Queue fetch fails
  Given the queue-status fetch fails
  Then the screen falls back to the existing last-known state (last build /
  no build) rather than showing a hard error — queue visibility is
  additive, its failure must not block the rest of the job detail screen
- Scenario: Build never queues (executor immediately available)
  Given an executor is free at trigger time
  Then the "queued" state is skipped entirely and the screen goes straight
  to "building" (US-JOB-04) — no artificial queued flash

**Security & Privacy Notes**
- None beyond existing per-server Jenkins auth handling.

**UI / Design Notes**
- Queued state renders on the same glass job-detail card as the last-build
  section (US-DESIGN-01), using an indeterminate progress affordance
  (distinct from US-JOB-04's estimated-duration progress bar) so "queued"
  and "building" are never visually confusable.

**Non-Functional Notes**
- NFR-TEST-02

---

### US-PIPE-02 — See who or what started a build

**Priority:** Should
**Source:** new — feature audit, not in any Phase 0–6 task
**Dependencies:** US-JOB-01

As a user checking a build that appeared without me triggering it
I want to see who or what started it (a person, an upstream job, an SCM
webhook, or a timer)
So that I can understand why a build ran without needing a laptop to check
Jenkins' own UI

**Acceptance Criteria**
- Scenario: Manually triggered build
  Given a build was started by a named Jenkins user
  Then the job detail / build history entry shows that user's display name
  as the cause
- Scenario: Upstream-triggered build
  Given a build was started by another job (an upstream pipeline)
  Then the cause shows the upstream job's name and build number, and is
  tappable through to US-PIPE-09 (upstream/downstream navigation) if that
  story is also implemented
- Scenario: SCM- or timer-triggered build
  Given a build was started by an SCM webhook/poll or a scheduled timer
  Then the cause is labeled accordingly (e.g. "Started by SCM change" /
  "Started by timer"), not left blank or shown as "unknown"
- Scenario: Cause data unavailable
  Given the build's `actions[causes[...]]` data is empty or the server
  doesn't report it
  Then no cause section is shown at all, rather than an empty/awkward
  placeholder

**Security & Privacy Notes**
- Cause data may include another user's Jenkins account display name; this
  is the same class of information already visible on Jenkins' own web UI
  to anyone with read access to the job, not new exposure introduced by
  this app.

**UI / Design Notes**
- Rendered as a small caption line under the last-build header on the job
  detail card (US-DESIGN-01), not a separate section — it's context, not a
  primary focus.

**Non-Functional Notes**
- NFR-TEST-02

---

### US-PIPE-03 — See what changed in a build (SCM changelog)

**Priority:** Could
**Source:** new — feature audit, not in any Phase 0–6 task
**Dependencies:** US-JOB-01, US-PIPE-02

As a user reviewing a build, especially a failed one
I want to see the commit messages/authors included in that build
So that I can connect a build's outcome to what code actually changed,
without opening a laptop to check the SCM history

**Acceptance Criteria**
- Scenario: Build has SCM changes
  Given the build's `changeSet` is non-empty
  Then each change's author and commit message (first line, truncated if
  long) is listed, most-recent-first
- Scenario: Build has no SCM changes
  Given `changeSet` is empty (e.g. a manually-triggered rebuild with no new
  commits)
  Then no changelog section is shown, rather than an empty list
- Scenario: Non-Git SCM or unsupported changelog shape
  Given the job uses an SCM type whose changelog entries don't match the
  expected shape
  Then the section is simply omitted rather than crashing or rendering
  malformed text
- Scenario: Fetch/parse failure
  Given the changelog portion of the build data fails to parse
  Then the rest of the job detail screen still renders normally — this is
  additive, non-critical information

**Security & Privacy Notes**
- Commit author names/emails and messages are already visible to anyone
  with Jenkins read access via its own UI; no new exposure. Commit messages
  are not sanitized/redacted by this app, same posture as console log
  content under NFR-SEC-05/US-LOG-01.

**UI / Design Notes**
- Sits directly below US-PIPE-02's cause line on the job detail card, as a
  collapsible list if more than ~3 changes are present, to avoid pushing
  the trigger button off-screen on jobs with large commit batches.

**Non-Functional Notes**
- NFR-TEST-02

---

### US-PIPE-04 — See a stage-by-stage breakdown for pipeline builds

**Priority:** Should
**Source:** new — feature audit, not in any Phase 0–6 task
**Dependencies:** US-JOB-01, US-LOG-01

As a user checking a Jenkinsfile-based (multi-stage) pipeline build
I want to see which stage passed, failed, or is currently running
So that I can tell what broke without scrolling a multi-thousand-line raw
console log looking for it

**Acceptance Criteria**
- Scenario: Pipeline build with stages
  Given the build is a pipeline job (has a `wfapi` stage graph available)
  Then a stage list renders with each stage's name, status (success/
  failed/running/not-yet-run), and duration
- Scenario: Non-pipeline (freestyle) job
  Given the job is a classic freestyle job with no stage data
  Then no stage view is shown and the screen behaves exactly as it does
  today (console log only, US-LOG-01) — this story doesn't change anything
  for non-pipeline jobs
- Scenario: Tap a stage to jump to its log
  Given I tap a stage in the list
  Then the console log view (US-LOG-01) opens scrolled to that stage's
  first log line, where Jenkins' stage log-range data makes this possible
- Scenario: Live-updating during a running build
  Given the pipeline is still executing
  Then the stage list updates on the same polling cadence as US-JOB-04
  (every 5s) to reflect stages completing/starting
- Scenario: Stage data fetch fails
  Given the `wfapi` stage fetch fails or 404s (older Jenkins without the
  Pipeline plugin's REST API, or a job type that doesn't support it)
  Then the screen falls back to the existing console-log-only view with no
  error shown for this specific gap — stage view is additive, not a
  replacement for or blocker to US-LOG-01

**Security & Privacy Notes**
- None beyond existing per-server Jenkins auth handling.

**UI / Design Notes**
- A horizontally scrollable stage chip row (per-stage color from
  US-DESIGN-05's status mapping) above the console log viewer, consistent
  with the job-detail glass card treatment (US-DESIGN-01).

**Non-Functional Notes**
- NFR-TEST-02, NFR-A11Y-03 (stage status must not rely on color alone)

---

### US-PIPE-05 — Approve or abort a paused pipeline input step

**Priority:** Should
**Source:** new — feature audit, not in any Phase 0–6 task
**Dependencies:** US-JOB-01, US-PIPE-04

As a user whose pipeline is paused on a manual approval gate (e.g. "approve
deploy to production")
I want to approve or abort it from my phone
So that I don't have to find a laptop just to unblock a deployment waiting
on my sign-off — this is one of the strongest reasons to check Jenkins from
a phone at all

**Acceptance Criteria**
- Scenario: Pending input step detected
  Given a running pipeline build has a pending `input` step
  (`wfapi/pendingInputActions` non-empty)
  Then the job detail screen shows the input step's message/prompt and any
  parameters it requests, with Approve/Abort actions
- Scenario: Approve
  Given I tap Approve and confirm
  Then `POST .../wfapi/inputSubmit` is called (with the CSRF crumb per
  `NFR-SEC-06`) with `proceed`, the pipeline resumes, and the screen
  reflects the resumed running state on the next poll
- Scenario: Abort
  Given I tap Abort/Reject and confirm
  Then the equivalent reject submission is made, and the build's final
  result reflects the abort — same no-false-success guarantee as US-JOB-05
- Scenario: Confirmation required for both actions
  Given approving or aborting a production-facing pipeline is exactly the
  kind of high-stakes action this story exists for
  Then both Approve and Abort require an explicit confirmation step before
  the request is sent, same rationale as US-JOB-02/05
- Scenario: Input step requests parameters
  Given the paused step also asks for parameter values (not just proceed/
  abort)
  Then a form matching US-JOB-03's parameter-type rendering is shown before
  the Approve action is enabled
- Scenario: Stale crumb / submission fails
  Given the input-submit request fails (expired crumb, network error, or
  the input was already resolved by someone else via the Jenkins web UI)
  Then an `AppFailure`-mapped message is shown and the screen re-fetches the
  current pending-input state rather than assuming the action succeeded

**Security & Privacy Notes**
- This is the highest-stakes action in this epic — it can directly gate a
  production deployment. Confirmation-before-action and no-false-success
  (same posture as US-JOB-02/05) are the primary safeguards; `NFR-SEC-06`
  (CSRF crumb) is a hard prerequisite for this story since the submit call
  will otherwise 403 on any CSRF-protected Jenkins.
- Anyone with the Jenkins credentials stored in this app can approve/abort
  — same trust boundary as every other trigger/cancel action already in
  the app; this story doesn't introduce a new permission model.

**UI / Design Notes**
- Rendered as a distinct, high-visibility banner/card (not buried in the
  regular job-detail layout) when a pending input exists — this state
  should be immediately obvious on opening the screen, per the "why would
  someone open this app right now" scenario.

**Non-Functional Notes**
- NFR-SEC-06, NFR-TEST-02

---

### US-PIPE-06 — See a build's test result summary

**Priority:** Should
**Source:** new — feature audit, not in any Phase 0–6 task
**Dependencies:** US-JOB-01

As a user checking a red (failed/unstable) build
I want a pass/fail/skipped test count at a glance
So that I can tell "build broke" from "tests broke" without opening the
full console log

**Acceptance Criteria**
- Scenario: Build has test results
  Given `{buildURL}/testReport/api/json` returns data
  Then pass/fail/skip counts render on the job detail card, with the
  failed count visually emphasized when non-zero
- Scenario: Build has no test report
  Given the job doesn't publish test results (or none exist for this build)
  Then no test-summary section is shown, rather than a "0/0/0" or error
  state
- Scenario: Tap through to failing test names
  Given there are failing tests
  Then tapping the summary shows the list of failing test names/class names
  (still a summary — not full stack traces/output, which stays in the
  console log per US-LOG-01)
- Scenario: Test report fetch fails
  Given the test-report fetch fails or 404s
  Then the rest of the job detail screen renders normally — additive, non-
  blocking, same pattern as US-PIPE-01/03/04

**Security & Privacy Notes**
- Test names/class names may reveal internal code structure; this is
  already visible to anyone with Jenkins read access via its own UI, no new
  exposure introduced.

**UI / Design Notes**
- A compact chip (e.g. "42 passed · 2 failed · 1 skipped") on the job
  detail card, using the same status-color-plus-text pattern as
  US-DESIGN-05/NFR-A11Y-03.

**Non-Functional Notes**
- NFR-TEST-02, NFR-A11Y-03

---

### US-PIPE-07 — View and open a build's artifacts

**Priority:** Could
**Source:** new — feature audit, not in any Phase 0–6 task
**Dependencies:** US-JOB-01

As a user checking a build that produces an output file (e.g. an APK, a log
bundle, a report)
I want to see what artifacts a build produced and open one
So that I can grab a build's output from my phone without a laptop

**Acceptance Criteria**
- Scenario: Build has artifacts
  Given the build's `api/json` response includes a non-empty `artifacts[]`
  Then each artifact's file name and relative path is listed on the job
  detail card
- Scenario: Open an artifact
  Given I tap an artifact
  Then the app opens `{buildURL}/artifact/{relativePath}` via the system's
  own handling (browser/share sheet), consistent with `url_launcher`'s
  existing use in `US-PROF-03`-style external links — this story is scoped
  to list-and-open, not an in-app file manager or on-device download/
  storage flow, which doesn't fit a mobile "companion app" role
- Scenario: Build has no artifacts
  Given `artifacts[]` is empty
  Then no artifacts section is shown
- Scenario: Artifact list fetch fails
  Given the artifact data fails to load
  Then the rest of the job detail screen renders normally — additive, non-
  blocking, same pattern as the other PIPE stories

**Security & Privacy Notes**
- Opening an artifact sends the same per-server Basic Auth credentials
  already used for every other Jenkins request in this app (via the active
  `jenkinsClientProvider`/system browser with credentials in the URL only
  if the platform's link handler requires it — prefer an authenticated
  in-app fetch-then-hand-off over embedding credentials in a bare URL
  wherever the target platform allows it).

**UI / Design Notes**
- A simple list with a file-type icon per artifact, on the same glass job-
  detail card.

**Non-Functional Notes**
- NFR-TEST-02

---

### US-PIPE-08 — Replay a build with the same parameters

**Priority:** Could
**Source:** new — feature audit, not in any Phase 0–6 task
**Dependencies:** US-JOB-03, US-HIST-02

As a user re-running a previous (often failed) parameterized build
I want to replay it with the exact same parameter values it ran with
So that I don't have to remember and retype what I ran last time

**Acceptance Criteria**
- Scenario: Replay from history
  Given I open a previous build from per-job history (US-HIST-02)
  Then a "Replay with same parameters" action is available, pre-filling
  US-JOB-03's parameter form with that build's actual recorded parameter
  values (not the job's current declared defaults)
- Scenario: Confirm and adjust before replaying
  Given the pre-filled form is shown
  Then I can still edit any value before confirming — this is a
  convenience pre-fill, not a blind one-tap re-run, consistent with
  US-JOB-03's existing confirm-before-trigger flow
- Scenario: Successful replay
  Given I confirm
  Then the same `POST {jobURL}buildWithParameters` path from US-JOB-03 is
  used (including `NFR-SEC-06`'s crumb handling) — replay is not a
  separate Jenkins endpoint, just a pre-filled trigger
- Scenario: Job's parameters changed since that build ran
  Given the job's parameter definitions have changed since the build being
  replayed (a parameter was added, removed, or renamed)
  Then the form reconciles as best it can — known parameter names are
  pre-filled, new parameters fall back to their current declared defaults,
  removed parameters are simply dropped — rather than failing outright
- Scenario: Original build has no recorded parameters
  Given the build being replayed wasn't parameterized
  Then "Replay" behaves identically to US-JOB-02 (plain trigger)

**Security & Privacy Notes**
- Same as US-JOB-03 — replayed parameter values are user-visible/editable
  before submission, no blind resubmission of potentially stale or
  sensitive values.

**UI / Design Notes**
- "Replay" action sits on each build-history entry (US-HIST-02's list
  item), opening the existing parameter form UI rather than a new screen.

**Non-Functional Notes**
- NFR-SEC-06, NFR-TEST-02

---

### US-PIPE-09 — Navigate to upstream/downstream related jobs

**Priority:** Could
**Source:** new — feature audit, not in any Phase 0–6 task
**Dependencies:** US-PIPE-02, US-TREE-01

As a user tracing a failure through a pipeline of jobs
I want to jump from a build to the upstream job that triggered it, or to
the downstream jobs it triggers
So that I can follow a failure's root cause or its blast radius without
manually searching the job tree

**Acceptance Criteria**
- Scenario: Upstream link
  Given a build's cause (US-PIPE-02) identifies an upstream job/build
  Then tapping it navigates directly to that upstream job's detail screen
  (reusing US-JOB-01), not a search or tree drill-down
- Scenario: Downstream links
  Given the job configuration reports downstream jobs it triggers
  Then they're listed (name only, tappable) on the job detail card,
  navigating to each job's detail screen the same way
- Scenario: No upstream/downstream relationships
  Given a job has no configured upstream/downstream relationships
  Then no such section is shown
- Scenario: Linked job no longer exists or moved
  Given an upstream/downstream job referenced was since deleted or renamed
  Then tapping it surfaces the same `NotFoundFailure` handling as US-JOB-01's
  "job deleted since I navigated here" scenario, not a crash

**Security & Privacy Notes**
- None beyond existing per-server Jenkins auth handling; navigation stays
  within jobs on the same active server/credential.

**UI / Design Notes**
- Upstream shown inline with US-PIPE-02's cause line ("Started by upstream
  job X ▸"); downstream shown as a small tappable chip list, both using
  standard link/chip styling, not a new navigation pattern.

**Non-Functional Notes**
- NFR-TEST-02
