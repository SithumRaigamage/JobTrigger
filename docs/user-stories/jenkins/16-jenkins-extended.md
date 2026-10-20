# Epic: JX — Jenkins Extended Capabilities

This epic is **new scope** added on 2026-09-29 from a coverage review of the
Jenkins integration after Phases 4, 5, and 7 were complete. It has three
parts, implemented in this order (see `tasks/phase-11-jenkins-extended.md`):

1. **Verification** of shipped-but-unproven work (US-PIPE-05 input steps,
   P5-13 log performance). These are tasks, not stories, since the stories
   already exist.
2. **Depth gaps** in features that already exist: parameters, multibranch,
   stage logs, history, console, tests, queue (US-JX-01 … US-JX-09).
3. **New capabilities** (US-JX-10 … US-JX-23).

**Scope change from epic PIPE.** `11-build-insights-pipeline.md`'s intro
explicitly excluded "admin-console territory (job … disable, node/executor
management, … view/tab management)". The product owner reversed that on
2026-09-29 for three narrowly scoped cases: enabling or disabling a job
(US-JX-13), marking a node temporarily offline (US-JX-12), and switching
views (US-JX-17). Everything else in that exclusion still stands: no job
create, rename, or delete, no `config.xml` editing, no plugin management, no
script console, no credential-store management. Every admin-flavoured action
here needs the user's own Jenkins permission, maps a 403 to `AuthFailure`
copy ("You don't have permission to do this on this server"), and requires a
confirmation step.

"Must" in this epic means *needed to use Jenkins correctly from a phone*:
security fixes, and common setups (multibranch) that are broken today.
"Should" means high day-to-day value. "Could" means nice-to-have.

**New dependencies.** Stories that need packages outside `CLAUDE.md` §3 say
so in their Non-Functional Notes. Each must be approved and added to §3 in
the same change that first uses it. In Part 2 only US-JX-02 (`file_picker`) needs one.

---

## Part 2 — Depth gaps in existing features

### US-JX-01 — Password parameters are masked and never pre-filled

**Priority:** Must
**Source:** new — Jenkins coverage review (report item C#4), audit AUD-27
**Dependencies:** US-JOB-03

As a user triggering a job that takes a secret parameter
I want the value masked and not pre-filled from Jenkins' default
So that secrets aren't shown on my screen or captured in screenshots

**Acceptance Criteria**
- Scenario: Masked entry
  Given a job defines a `PasswordParameterDefinition`
  Then its field renders with obscured text, a show/hide toggle, and
  autocorrect, suggestions, and autofill disabled
- Scenario: Default not pre-filled
  Given Jenkins reports a default value for that parameter
  Then the field starts empty with the helper text "Leave blank to use the
  server default". If left blank, the parameter is **omitted** from the
  `buildWithParameters` body so Jenkins applies its own default
- Scenario: Never persisted or echoed
  Then the value is never written to storage, never logged, never shown in
  the trigger confirmation summary (it appears as `••••`), and is excluded
  from "replay with same parameters" (US-PIPE-08). Jenkins itself returns
  password parameters masked
- Scenario: Input steps
  Given a paused input step (US-PIPE-05) asks for a password parameter
  Then the same masking rules apply

**Security & Privacy Notes**
- Masking protects against shoulder-surfing and screen capture. Transport
  confidentiality still depends on the server using HTTPS (AUD-14).

**UI / Design Notes**
- Same glass form field as other parameters, with a trailing eye icon.

**Non-Functional Notes**
- NFR-SEC-01, NFR-SEC-04, NFR-TEST-01, NFR-A11Y-02 (the toggle has a label)

---

### US-JX-02 — Every Jenkins parameter type is handled correctly

**Priority:** Must
**Source:** new — report item C#5
**Dependencies:** US-JOB-03, US-JX-01

As a user triggering a parameterized job
I want each parameter to use an input suited to its type
So that I can't send invalid values or a silently wrong build

**Acceptance Criteria**
- Scenario: Multi-line text
  Given a `TextParameterDefinition`
  Then a multi-line field (3–8 visible lines) is used and newlines are
  preserved in the form-encoded body
- Scenario: Run parameter
  Given a `RunParameterDefinition` (`projectName`)
  Then a picker lists that project's recent builds (reusing per-job history)
  and submits `<job>#<number>`
- Scenario: Credentials parameter
  Given a `CredentialsParameterDefinition`
  Then the field is a free-text credentials-id input pre-filled with the
  default id, with helper text explaining it is an id, not a secret. The app
  never lists or reads Jenkins' credential store
- Scenario: File parameter
  Given a `FileParameterDefinition` (or `StashedFileParameterDefinition`)
  Then I can pick a file from the device, and the trigger is sent as
  `multipart/form-data` to `buildWithParameters`, with the file under the
  parameter's name and other parameters as text parts. A file over 50 MB is
  refused with a clear message before upload
- Scenario: Unknown plugin types
  Given a parameter type the app doesn't recognise (Active Choices, Extended
  Choice, Git Parameter, …)
  Then it renders as a text field labelled "Unsupported type (<type>) —
  value sent as text". If that type declares `choices`, a dropdown is used
  instead
- Scenario: Validation
  Given an empty required-looking value (a choice with no selection, or an
  unpicked run)
  Then Trigger is disabled with an inline reason, never a failed request

**Security & Privacy Notes**
- A file picked for upload is read from the user's own selection only, and
  the app keeps no copy after the request completes.

**UI / Design Notes**
- The file picker row shows the file name and size, with a clear button.

**Non-Functional Notes**
- NFR-SEC-02, NFR-TEST-01, NFR-TEST-02
- **New dependency:** `file_picker` (needs approval)

---

### US-JX-03 — Multibranch pipelines and organization folders

**Priority:** Must
**Source:** new — report item C#6
**Dependencies:** US-TREE-01

As a user whose Jenkins uses multibranch pipelines (the modern default)
I want branches, pull requests, and tags presented as such, with readable
names
So that I can find the build for my branch without decoding URLs

**Acceptance Criteria**
- Scenario: Type detection
  Given the tree query requests `_class` and `displayName`
  Then `…WorkflowMultiBranchProject` and `jenkins.branch.OrganizationFolder`
  render with distinct icons, and folders are detected by class as well as
  by the presence of `jobs`
- Scenario: Readable branch names
  Given a branch job named `feature%2Flogin`
  Then the tile, app bar, breadcrumb, and history show `displayName`
  (`feature/login`), falling back to a URL-decoded `name`
- Scenario: Grouping
  Given I open a multibranch project
  Then its jobs are grouped into "Branches", "Pull Requests", and "Tags"
  sections using the project's `views[name,jobs[url]]` (branch-api views
  `default`, `change-requests`, `tags`). If views are unavailable, one flat
  list is shown
- Scenario: Scan repository now
  Given I tap "Scan now" on a multibranch project or organization folder
  and confirm
  Then `POST {projectUrl}build?delay=0` is sent (CSRF crumb attached), a
  toast confirms it, and the project refreshes when the scan finishes
  (polling `{projectUrl}indexing/api/json` while it runs). I can open the
  scan log at `{projectUrl}indexing/consoleText` in the console viewer
- Scenario: Permission denied
  Given the scan request returns 403
  Then an `AuthFailure` message about permission is shown

**Security & Privacy Notes**
- Scanning is a state-changing POST: confirmation is required, as for
  trigger.

**UI / Design Notes**
- Section headers use the glass list style; PR tiles show the PR number
  badge when `displayName` carries it (`PR-123`).

**Non-Functional Notes**
- NFR-SEC-06, NFR-TEST-02 (needs a real multibranch fixture)

---

### US-JX-04 — Per-stage logs and parallel branches

**Priority:** Should
**Source:** new — report item C#7 (closes the gap flagged in US-PIPE-04's
implementation note)
**Dependencies:** US-PIPE-04, US-LOG-01

As a user investigating a failed pipeline
I want to tap a stage and see only that stage's log
So that I don't scroll thousands of lines to find the failing step

**Acceptance Criteria**
- Scenario: Open stage log
  Given a pipeline build with stages
  When I tap a stage chip
  Then a stage detail sheet lists its steps
  (`GET {build}execution/node/{stageId}/wfapi/describe` →
  `stageFlowNodes[name,status,durationMillis,parameterDescription]`), and
  tapping a step shows its log (`…/execution/node/{nodeId}/wfapi/log` →
  `text`, `hasMore`), live-updating while it runs
- Scenario: Failed step highlighted
  Then the first `FAILED` step is expanded and scrolled into view
  automatically
- Scenario: Parallel branches
  Given a stage runs parallel branches
  Then each branch appears as a sub-row with its own status and log
- Scenario: Truncated step log
  Given `hasMore` is true for a finished step
  Then a "View full log" action opens the full console (US-LOG-01) instead
- Scenario: Endpoint unavailable
  Given a `wfapi` endpoint returns 404
  Then the chip falls back to opening the full console, as today

**Security & Privacy Notes**
- None beyond existing per-server auth.

**UI / Design Notes**
- A bottom sheet with a step list; logs use the console styling from
  US-LOG-01.

**Non-Functional Notes**
- NFR-PERF-03, NFR-TEST-02

---

### US-JX-05 — Jump to last successful, failed, or stable build

**Priority:** Should
**Source:** new — report item C#8
**Dependencies:** US-JOB-01

As a user
I want one-tap access to the last good build and the last failure
So that I can compare "what broke" without scrolling history

**Acceptance Criteria**
- Scenario: Links shown
  Given the detail tree includes `lastSuccessfulBuild`, `lastFailedBuild`,
  `lastStableBuild`, and `lastUnsuccessfulBuild` (`[number,url,timestamp]`)
  Then the job detail shows compact chips "Last success #N · 2h ago" and
  "Last failure #M" for whichever exist
- Scenario: Open
  When I tap a chip
  Then that build's detail (US-JX-14's build detail screen, or the log if
  that screen isn't built yet) opens
- Scenario: None exist
  Then the chips are omitted, never shown empty

**Security & Privacy Notes**
- None.

**UI / Design Notes**
- Chips sit under the last-build card and are status-coloured, always paired
  with text (NFR-A11Y-03).

**Non-Functional Notes**
- NFR-TEST-01

---

### US-JX-06 — Paged and filterable build history; search with context

**Priority:** Should
**Source:** new — report item C#9, audit AUD-33
**Dependencies:** US-HIST-02, US-TREE-02

As a user
I want to scroll back beyond 20 builds and filter them
So that I can find last week's failed release build

**Acceptance Criteria**
- Scenario: Paging
  Given per-job history shows 20 builds
  When I scroll near the end
  Then the next page loads via `allBuilds[…]{20,40}` (then `{40,60}`, …),
  stopping when a page comes back short
- Scenario: Filters
  Then I can filter by result (All / Failed / Unstable / Success / Aborted /
  Running) and by "started by me" (cause `userId` equals the server
  username). Filters apply to loaded pages, and "load more" continues until
  a page contains matches or history ends
- Scenario: Job search shows the folder path
  Given a job search result
  Then the tile shows its folder path (`team / service`) under the name
- Scenario: Empty state is refreshable
  Given no jobs or no results
  Then pull-to-refresh still works

**Security & Privacy Notes**
- None.

**UI / Design Notes**
- Filter chips use a horizontal glass chip row; paging shows a footer
  spinner.

**Non-Functional Notes**
- NFR-PERF-02, NFR-TEST-01

---

### US-JX-07 — Console log: search, jump to error, colors, timestamps, full download

**Priority:** Should
**Source:** new — report item C#10, audit AUD-12, AUD-13, AUD-34
**Dependencies:** US-LOG-01, US-LOG-02

As a user reading a long console log on a phone
I want to search it, jump to errors, and see it the way Jenkins shows it
So that diagnosing a failure takes seconds, not minutes

**Acceptance Criteria**
- Scenario: Smooth at scale (performance fix)
  Given a 50,000-line log streaming live
  Then only new chunks are sanitized and split (incrementally), scrolling
  stays smooth, and memory is capped (the last 20,000 lines are kept, with
  "Load earlier lines" fetching earlier content via `consoleText` on demand)
- Scenario: Transient error keeps the log
  Given a poll fails mid-stream
  Then the log stays visible with an inline "Reconnecting…" banner, and
  polling resumes from the last offset with backoff (1s, 2s, 4s, max 15s)
- Scenario: Search
  When I search
  Then matches are highlighted with a "3 / 17" counter and next/previous
  buttons; search is case-insensitive
- Scenario: Jump to first error
  Then an action jumps to the first line matching `ERROR`, `FAILURE`,
  `Exception`, or `BUILD FAILED`
- Scenario: ANSI colors
  Given the log contains ANSI SGR color codes (AnsiColor plugin)
  Then foreground and background colors and bold are rendered, not stripped.
  Jenkins console-note payloads are still removed
- Scenario: Timestamps
  Given the Timestamper plugin is installed
  Then a toggle shows per-line timestamps from
  `{build}timestamps/?time=HH:mm:ss&appendLog`. If that returns 404, the
  toggle is hidden
- Scenario: Wrap and font size
  Then I can toggle line wrap (off means horizontal scroll) and pick a font
  size (3 steps); both preferences persist in `shared_preferences`
- Scenario: Full log download
  Then "Save full log" downloads `{build}consoleText` to a temp file and
  shares it as a `.log` file (not as a giant text payload)

**Security & Privacy Notes**
- Logs can contain secrets that Jenkins failed to mask. Sharing requires an
  explicit user action, and temp files are deleted after sharing.

**UI / Design Notes**
- Search bar and toolbar pinned in the glass app bar; the color palette is
  tuned for the always-dark console.

**Non-Functional Notes**
- NFR-PERF-03 (closes release-checklist P5-13's code-side cause),
  NFR-TEST-01

---

### US-JX-08 — Test failure details

**Priority:** Should
**Source:** new — report item C#11
**Dependencies:** US-PIPE-06

As a user
I want the error message and stack trace of each failing test
So that I know why a test failed without opening the full log

**Acceptance Criteria**
- Scenario: Details
  Given the test-report tree adds `errorDetails,errorStackTrace,duration,age`
  on failing cases
  Then the failing-tests sheet lists each case, expandable to show the error
  message and a monospaced, copyable stack trace
- Scenario: Regressions highlighted
  Then cases with `status == REGRESSION` or `age == 1` are marked "New
  failure"
- Scenario: Very large reports
  Given more than 200 failing cases
  Then the first 200 are shown with a count of the rest (bounded payload:
  the tree request uses `{0,200}` on cases)

**Security & Privacy Notes**
- None.

**UI / Design Notes**
- Expandable tiles inside the existing bottom sheet.

**Non-Functional Notes**
- NFR-PERF-02, NFR-TEST-01

---

### US-JX-09 — Server-wide build queue

**Priority:** Should
**Source:** new — report item C#12
**Dependencies:** US-PIPE-01

As a user wondering why my build hasn't started
I want to see everything waiting in the Jenkins queue and why
So that I can tell a stuck executor from a long queue

**Acceptance Criteria**
- Scenario: Queue list
  When I open "Queue" (reachable from Home's overflow menu)
  Then `GET /queue/api/json?tree=items[id,why,inQueueSince,stuck,blocked,buildable,task[name,url,color]]`
  lists items with job name, time waiting, and reason, refreshing every 5s
  while visible
- Scenario: Cancel a queued item
  When I cancel an item and confirm
  Then `POST /queue/cancelItem?id={id}` is sent (crumb attached), and the
  item disappears on the next refresh
- Scenario: Stuck items
  Given `stuck == true`
  Then the item is flagged "Stuck" in warning style (text plus icon)
- Scenario: Empty queue
  Then "Nothing is waiting" is shown

**Security & Privacy Notes**
- Cancelling another user's queued build is state-changing and requires
  confirmation.

**UI / Design Notes**
- A glass list with relative times ("waiting 4m").

**Non-Functional Notes**
- NFR-SEC-06, NFR-TEST-02

---

## Part 3 — New capabilities

### US-JX-10 — Build completion notifications

**Priority:** Should
**Source:** new — report item D#13; promotes `BACKLOG-02` in part (local
notifications only; server push stays in backlog because it needs a backend
webhook receiver plus FCM/APNs)
**Dependencies:** US-JOB-04

As an engineer who triggered a long build
I want a notification when it finishes
So that I don't have to keep the app open

**Acceptance Criteria**
- Scenario: Opt in
  Given I trigger a build (or tap "Notify me" on a running one)
  Then that build is added to a watch list, and on first use the app
  requests notification permission (Android 13+ `POST_NOTIFICATIONS`, iOS
  alert authorization) with a rationale screen first
- Scenario: Foreground and recently backgrounded
  While the app process is alive, watched builds are polled (reusing the 5s
  cadence while visible, 30s when backgrounded), and on completion a local
  notification shows "✅ api-service #142 succeeded (4m 12s)" or
  "❌ … failed"
- Scenario: Background best-effort
  Given the app is suspended
  Then a periodic background task (≥15 min, OS-scheduled) checks watched
  builds. The UI states clearly that background checks are best-effort and
  may be delayed by the OS
- Scenario: Tap opens the build
  When I tap the notification
  Then the app opens that job's detail screen
- Scenario: Watched jobs
  Given I mark a job as "Watch"
  Then every new build of it notifies on completion until I unwatch it
- Scenario: Credentials unavailable in background
  Given the background task can't obtain the Jenkins credential (logged out,
  or server deleted)
  Then the watch entry is dropped silently. No notification ever includes
  secrets or log content

**Security & Privacy Notes**
- The background task reads Jenkins credentials from the same in-memory and
  secure sources as the app, and never persists them elsewhere.
  Notification text contains only job name, build number, result, and
  duration.

**UI / Design Notes**
- Bell toggle on job detail; a "Notifications" section in Settings lists
  watched builds and jobs.

**Non-Functional Notes**
- NFR-PLAT-01, NFR-TEST-01
- **New dependencies:** `flutter_local_notifications`, `workmanager` (need
  approval). Android manifest: `POST_NOTIFICATIONS`,
  `RECEIVE_BOOT_COMPLETED`.

---

### US-JX-11 — Pinned (favorite) jobs

**Priority:** Should
**Source:** new — report item D#14
**Dependencies:** US-TREE-01

As a user of a server with hundreds of jobs
I want to pin the few I use daily
So that they're one tap away from Home

**Acceptance Criteria**
- Scenario: Pin and unpin
  When I long-press a job tile or tap the pin icon on job detail
  Then it's added to or removed from "Pinned" for the active server
- Scenario: Pinned section
  Then Home shows a "Pinned" section above the tree at root level, with live
  status colors from the fetched tree or the job's own lightweight fetch
- Scenario: Per server, persisted
  Then pins are stored per server id in `shared_preferences` (job URLs only,
  no secrets) and survive restarts
- Scenario: Stale pin
  Given a pinned job returns 404
  Then it shows as "Not found" with a remove action

**Security & Privacy Notes**
- Only job URLs are stored, which are non-secret per `CLAUDE.md` §7.

**UI / Design Notes**
- Pinned tiles use the same glass tile with a pin glyph.

**Non-Functional Notes**
- NFR-TEST-01

---

### US-JX-12 — Nodes and executors

**Priority:** Should
**Source:** new — report item D#15 (scope change, see the epic intro)
**Dependencies:** none

As an on-call engineer
I want to see which agents are online and busy
So that I can tell why builds aren't starting

**Acceptance Criteria**
- Scenario: Node list
  When I open "Nodes"
  Then `GET /computer/api/json?tree=computer[displayName,offline,temporarilyOffline,offlineCauseReason,idle,numExecutors,executors[idle,progress,currentExecutable[url,fullDisplayName]],monitorData[*]]`
  lists nodes with online/offline state, busy/total executors, and
  disk-space or response-time warnings from `monitorData` when present
- Scenario: Executor drill-down
  When I open a node
  Then each busy executor shows its running build with progress, tappable to
  that build
- Scenario: Mark temporarily offline or online
  When I toggle a node and confirm (with an optional reason)
  Then `POST /computer/{encodedName}/toggleOffline?offlineMessage=…` is sent.
  The built-in node's path segment is `(built-in)`
- Scenario: No permission
  Given `Computer/Disconnect` is denied (403)
  Then the permission `AuthFailure` copy is shown and the toggle is hidden
  from then on for this session

**Security & Privacy Notes**
- Admin-flavoured and state-changing: confirmation is required, and the
  reason text is sent as typed.

**UI / Design Notes**
- A glass list; offline nodes show text plus icon, never color alone.

**Non-Functional Notes**
- NFR-SEC-06, NFR-A11Y-03, NFR-TEST-02

---

### US-JX-13 — Enable or disable a job

**Priority:** Could
**Source:** new — report item D#16 (scope change, see the epic intro)
**Dependencies:** US-JOB-01

As a job owner
I want to disable a misbehaving job, or re-enable it, from my phone
So that I can stop a runaway trigger during an incident

**Acceptance Criteria**
- Scenario: State shown
  Given the tree and detail queries include `buildable` (and `color ==
  disabled`)
  Then disabled jobs show a "Disabled" badge, and Trigger is disabled with
  the reason shown
- Scenario: Toggle
  When I choose Disable (or Enable) from the job's overflow menu and confirm
  Then `POST {job}disable` (or `enable`) is sent and the detail refreshes
- Scenario: Not supported
  Given the job type doesn't support it (404 or 405)
  Then "This job type can't be disabled" is shown

**Security & Privacy Notes**
- State-changing; confirmation is required.

**UI / Design Notes**
- Overflow menu item with a destructive-tone confirmation for Disable.

**Non-Functional Notes**
- NFR-SEC-06, NFR-TEST-02

---

### US-JX-14 — Build detail: keep forever and edit description

**Priority:** Could
**Source:** new — report item D#17
**Dependencies:** US-HIST-02

As a release engineer
I want to mark a build "keep forever" and annotate it
So that release builds aren't rotated away and are easy to find

**Acceptance Criteria**
- Scenario: Build detail screen
  When I open any build from history or links
  Then a build detail screen shows result, duration, causes, changes,
  artifacts, tests, stages, and log link (reusing the job-detail cards,
  scoped to that build), plus `description` and `keepLog`
- Scenario: Keep forever
  When I toggle "Keep forever" and confirm
  Then `POST {build}toggleLogKeep` is sent, and the state is re-fetched
  rather than assumed
- Scenario: Description
  When I edit the description and save
  Then `POST {build}submitDescription` with form field `description` is
  sent. The description is rendered as **plain text** (Jenkins descriptions
  can contain HTML, which is never rendered)

**Security & Privacy Notes**
- Rendering descriptions as plain text prevents HTML or markup injection
  from Jenkins content.

**UI / Design Notes**
- Same glass cards as job detail.

**Non-Functional Notes**
- NFR-SEC-04, NFR-SEC-06, NFR-TEST-02

---

### US-JX-15 — Build trends

**Priority:** Could
**Source:** new — report item D#18
**Dependencies:** US-JX-06

As a team lead
I want success rate and duration trends for a job
So that I can spot a degrading pipeline

**Acceptance Criteria**
- Scenario: Trend card
  Given at least 5 finished builds are loaded
  Then job history shows a success rate over the last N (20 or 50,
  selectable), average and p90 duration, and a duration sparkline with
  failed builds marked
- Scenario: Computed locally
  Then all stats are computed by a pure domain function from already-fetched
  history. No new endpoint
- Scenario: Too few builds
  Then "Not enough builds for trends" is shown

**Security & Privacy Notes**
- None.

**UI / Design Notes**
- Chart drawn with `CustomPaint` following the dataviz guidance: single
  hue, failure marks with shape plus text.

**Non-Functional Notes**
- NFR-A11Y-03, NFR-TEST-01. No chart dependency.

---

### US-JX-16 — Replay with an edited pipeline script

> **Status: won't-do (closed by its verification gate, P11-27,
> 2026-09-30).** Verified on the fixture Jenkins (2.568.3): submitting is
> scriptable (`POST {build}replay/run` with `_.mainScript` and the Stapler
> `json` body returns 302 and the run logs "Replayed #N"). But the build's
> original script, which the "Load script" scenario needs, is only
> available as the `_.mainScript` `<textarea>` in the `replay/` HTML page:
> `replay/api/json`, `api/xml`, and the build's `actions` expose nothing.
> The app would have to scrape HTML, which breaks across Jenkins versions
> and themes, so the gate's won't-do branch applies. A secondary problem:
> the 302 points at the job, not the new build, so "taken to the new build"
> could only guess at `lastBuild`. Replay with the *same* parameters
> (US-PIPE-08) is unaffected. Revisit if Jenkins adds a JSON endpoint for
> the replay script.

**Priority:** Could
**Source:** new — report item D#19
**Dependencies:** US-PIPE-08, US-JX-14

As a pipeline author
I want to replay a build with a small script edit
So that I can test a fix without committing

**Acceptance Criteria**
- Scenario: Load script
  When I choose "Replay with edits" on a pipeline build
  Then the original main script is loaded from the build's replay action and
  shown in a monospaced editor
- Scenario: Run
  When I edit and confirm (a second, explicit confirmation stating "This
  runs arbitrary pipeline code on <server>")
  Then the replay is submitted (`POST {build}replay/run` with `mainScript`
  and the Stapler `json` body) and I'm taken to the new build
- Scenario: Not available
  Given the build isn't replayable or the user lacks `Run/Replay` (403 or
  404)
  Then the action is hidden or a permission message is shown
- Scenario: Verification gate
  The exact form contract must be verified against the fixture Jenkins
  (NFR-TEST-02) before this ships. If it can't be driven reliably without
  scraping HTML, the story is closed as won't-do and documented

**Security & Privacy Notes**
- This executes arbitrary code on the CI server, so it gets two
  confirmations and clearly shows the target server.

**UI / Design Notes**
- Full-screen editor with the always-dark console styling.

**Non-Functional Notes**
- NFR-SEC-06, NFR-TEST-02

---

### US-JX-17 — Views

**Priority:** Could
**Source:** new — report item D#20 (scope change, see the epic intro)
**Dependencies:** US-TREE-01

As a user whose team organises Jenkins by views
I want to switch Home to a view
So that I see my team's jobs, not the whole server

**Acceptance Criteria**
- Scenario: View picker
  Given `GET /api/json?tree=views[name,url],primaryView[name]`
  Then Home's title becomes a picker listing views, defaulting to the
  primary view ("All")
- Scenario: View contents
  When I pick a view
  Then `GET {viewUrl}api/json?tree=jobs[…]` supplies Home's root list;
  folder navigation and search work within it
- Scenario: Remembered
  Then the selected view is persisted per server (`shared_preferences`)

**Security & Privacy Notes**
- None.

**UI / Design Notes**
- A dropdown in the glass app bar title.

**Non-Functional Notes**
- NFR-TEST-02

---

### US-JX-18 — Server status

**Priority:** Could
**Source:** new — report item D#21
**Dependencies:** US-CRED-05

As a user
I want to see the Jenkins version and whether it's shutting down
So that I understand why triggers are refused

**Acceptance Criteria**
- Scenario: Info
  Then Settings, under the active server, shows the Jenkins version (the
  `X-Jenkins` response header) and the node mode
- Scenario: Quiet down
  Given `/api/json?tree=quietingDown` is true
  Then Home shows a persistent banner "Jenkins is preparing for shutdown —
  new builds won't start"
- Scenario: Outdated version
  Given the version is below the current LTS baseline configured in
  `core/config`
  Then an informational note is shown (not blocking)

**Security & Privacy Notes**
- None.

**UI / Design Notes**
- Glass banner with a warning tone.

**Non-Functional Notes**
- NFR-TEST-02

---

### US-JX-19 — Open Jenkins links in the app

**Priority:** Could
**Source:** new — report item D#22
**Dependencies:** US-JOB-01

As a user who gets Jenkins links in Slack or email
I want to open them in JobTrigger
So that I land on the job or build screen directly

**Acceptance Criteria**
- Scenario: Custom scheme
  Given a link `jobtrigger://open?url=<encoded Jenkins URL>`
  Then the app opens the matching job or build screen
- Scenario: Share into app / paste
  Given I share a Jenkins URL to JobTrigger (Android share intent, iOS paste
  from Home's "Open link…" action)
  Then the URL is matched against configured servers by host and path
  prefix, the matching server is activated after confirmation if it isn't
  active, and the job or build opens
- Scenario: Unknown server
  Given no configured server matches
  Then "No saved server matches this link" is shown, with "Add server"
  prefilled with the origin
- Scenario: Parsing
  Then `/job/a/job/b/123/console` style paths resolve to job `a/b`, build
  123, and screen log, by a pure, unit-tested parser

**Security & Privacy Notes**
- Links never carry credentials, and URLs containing userinfo
  (`user:pass@`) are rejected. The app only ever talks to servers the user
  saved; a link can't point the app at a new server without the user adding
  it.

**UI / Design Notes**
- Standard confirmation sheet for server switching.

**Non-Functional Notes**
- NFR-SEC-02, NFR-TEST-01. Platform: an Android intent-filter for the
  `jobtrigger` scheme and `SEND text/plain`, and iOS `CFBundleURLTypes`.
  `go_router` already handles deep links. No new dependency.

---

### US-JX-20 — Offline job tree

**Priority:** Could
**Source:** new — report item D#23; promotes `BACKLOG-05`
**Dependencies:** US-TREE-01

As a user on a flaky connection
I want to browse the last-known job list
So that the app isn't blank when the network drops

**Acceptance Criteria**
- Scenario: Cache on success
  Given a successful job-tree or folder fetch
  Then the result (names, URLs, colors, last-build numbers; no secrets) is
  written per server id to the app's documents directory
- Scenario: Offline fallback
  Given a later fetch fails with `NetworkFailure`
  Then the cached tree is shown with a banner "Offline — showing data from
  14:32", and trigger, cancel, and other POST actions are disabled with the
  reason
- Scenario: Cache hygiene
  Then the cache for a server is deleted when that server is deleted or the
  user logs out

**Security & Privacy Notes**
- Job names and URLs can be sensitive: the cache lives in app-private
  storage, is excluded from iCloud and Android auto-backup, and is cleared
  on logout.

**UI / Design Notes**
- Offline banner in the glass warning style.

**Non-Functional Notes**
- NFR-PLAT-01, NFR-TEST-01
- **New dependency:** `path_provider` as a direct dependency (already
  transitive; needs approval)

---

### US-JX-21 — Biometric app lock

**Priority:** Could
**Source:** new — report item D#24; promotes `BACKLOG-06`
**Dependencies:** US-AUTH-03

As a user with production access on my phone
I want the app to require Face ID or fingerprint
So that someone holding my unlocked phone can't trigger deploys

**Acceptance Criteria**
- Scenario: Enable
  When I enable "Require biometrics" in Settings
  Then the app authenticates once to confirm, then requires it on cold start
  and on resume after more than 5 minutes in the background (the timeout
  is selectable: immediately, 1, 5, or 15 minutes)
- Scenario: Fallback
  Given biometrics fail or are unavailable
  Then device passcode fallback is allowed. If no device security is set,
  the setting can't be enabled and the reason is explained
- Scenario: Privacy screen
  Then while locked, and in the app switcher snapshot, content is obscured
- Scenario: Sensitive actions (optional)
  Given "Require for trigger/approve" is on
  Then trigger, cancel, input approval, replay, node toggle, and job disable
  each re-prompt

**Security & Privacy Notes**
- The biometric result gates the UI only. Secrets stay in secure storage
  either way.

**UI / Design Notes**
- A full-screen glass lock view with an unlock button.

**Non-Functional Notes**
- NFR-PLAT-01, NFR-TEST-01
- **New dependency:** `local_auth` (needs approval). iOS
  `NSFaceIDUsageDescription`; Android `USE_BIOMETRIC` and
  `FlutterFragmentActivity`.

---

### US-JX-22 — API token hygiene

**Priority:** Should
**Source:** new — report item D#25
**Dependencies:** US-CRED-01

As a security-conscious user
I want to be warned when I save a real password instead of an API token
So that I use revocable, scoped credentials on my phone

**Acceptance Criteria**
- Scenario: Detect likely password
  Given the secret doesn't look like a Jenkins API token (legacy 32 hex
  characters, or current `11` plus 32 hex characters)
  Then the server form shows a non-blocking warning: "This looks like a
  password. Jenkins API tokens are safer — they can be revoked without
  changing your password"
- Scenario: Help link
  Then a "Create a token" link opens `{jenkinsURL}/me/configure` in the
  browser
- Scenario: Existing servers
  Given a saved server matches the password heuristic
  Then its row in Settings shows a small "Uses password" advisory

**Security & Privacy Notes**
- The heuristic runs locally, and the secret is never sent anywhere
  extra.

**UI / Design Notes**
- Inline warning style under the secret field.

**Non-Functional Notes**
- NFR-SEC-01, NFR-TEST-01

---

### US-JX-23 — Home-screen widget

**Priority:** Could
**Source:** new — report item D#26; promotes `BACKLOG-03`
**Dependencies:** US-JX-11

As a user
I want my pinned jobs' status on my home screen
So that I can see a red build without opening the app

**Acceptance Criteria**
- Scenario: Widget data
  Given pinned jobs exist
  Then whenever the app refreshes their status (foreground or background
  task, US-JX-10), it writes a small snapshot (name, color, last build
  number and time; **no credentials**) to the shared widget store and
  requests a widget reload
- Scenario: Widget
  Then small and medium widgets (iOS WidgetKit, Android AppWidget) show up
  to 2 or 4 pinned jobs with status (icon plus text) and "updated 5m ago".
  Tapping a job deep-links (US-JX-19) into it
- Scenario: No data
  Then the widget shows "Pin jobs in JobTrigger"

**Security & Privacy Notes**
- The widget never fetches from Jenkins itself and holds no secrets. The
  snapshot is cleared on logout.

**UI / Design Notes**
- Native widgets following each platform's widget guidelines, with brand
  accent.

**Non-Functional Notes**
- NFR-A11Y-03, NFR-TEST-01
- **New dependency:** `home_widget` (needs approval), plus a native iOS
  widget extension target (Swift) and an Android `AppWidgetProvider`
  (Kotlin).
