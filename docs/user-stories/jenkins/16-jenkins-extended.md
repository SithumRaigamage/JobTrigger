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
- [x] Scenario: Masked entry
  Given a job defines a `PasswordParameterDefinition`
  Then its field renders with obscured text, a show/hide toggle, and
  autocorrect, suggestions, and autofill disabled
  Evidence: `test/presentation/features/job_detail/parameter_form_test.dart` "are masked, start empty, and disable suggestions", "the eye toggle reveals and re-hides the value".
- [x] Scenario: Default not pre-filled
  Given Jenkins reports a default value for that parameter
  Then the field starts empty with the helper text "Leave blank to use the
  server default". If left blank, the parameter is **omitted** from the
  `buildWithParameters` body so Jenkins applies its own default
  Evidence: `test/domain/jenkins/parameter_values_test.dart` "never pre-fills a secret (US-JX-01)", "omits a blank secret so Jenkins keeps its stored default"; `test/presentation/features/job_detail/trigger_build_notifier_test.dart` "a blank password parameter is omitted, not sent empty (US-JX-01)".
- [x] Scenario: Never persisted or echoed
  Then the value is never written to storage, never logged, never shown in
  the trigger confirmation summary (it appears as `••••`), and is excluded
  from "replay with same parameters" (US-PIPE-08). Jenkins itself returns
  password parameters masked
  Evidence: `test/presentation/features/job_detail/job_detail_confirmation_test.dart` "the summary shows parameters with the secret masked"; `test/domain/jenkins/parameter_values_test.dart` "masks secrets and never includes their value"; `test/domain/jenkins/reconcile_replay_parameters_test.dart` "never replays a secret -- it stays blank for the server default"; edits live only in memory (`ParameterEditsNotifier`).
- [x] Scenario: Input steps
  Given a paused input step (US-PIPE-05) asks for a password parameter
  Then the same masking rules apply
  Evidence: input steps use the same `ParameterForm` (`test/presentation/features/job_detail/job_detail_pipeline_test.dart` "an input step with parameters shows the parameter form", 2026-11-21), so the masking tests above apply; `test/data/models/jenkins/pending_input_dto_test.dart` parses the password input.

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
- [x] Scenario: Multi-line text
  Given a `TextParameterDefinition`
  Then a multi-line field (3–8 visible lines) is used and newlines are
  preserved in the form-encoded body
  Evidence: `test/presentation/features/job_detail/parameter_form_types_test.dart` "text parameters are multi-line"; newlines survive encoding: `test/data/repositories/jenkins_repository_impl_trigger_test.dart` "a value with &, =, quotes and shell text reaches Jenkins literally" (2026-11-21).
- [x] Scenario: Run parameter
  Given a `RunParameterDefinition` (`projectName`)
  Then a picker lists that project's recent builds (reusing per-job history)
  and submits `<job>#<number>`
  Evidence: `test/presentation/features/job_detail/parameter_form_types_test.dart` "run parameters pick from the project builds, defaulting to the server"; `test/domain/jenkins/parameter_values_test.dart` "a chosen run value is sent as job#number".
- [x] Scenario: Credentials parameter
  Given a `CredentialsParameterDefinition`
  Then the field is a free-text credentials-id input pre-filled with the
  default id, with helper text explaining it is an id, not a secret. The app
  never lists or reads Jenkins' credential store
  Evidence: `test/presentation/features/job_detail/parameter_form_types_test.dart` "credentials parameters explain they take an ID".
- [x] Scenario: File parameter
  Given a `FileParameterDefinition` (or `StashedFileParameterDefinition`)
  Then I can pick a file from the device, and the trigger is sent as
  `multipart/form-data` to `buildWithParameters`, with the file under the
  parameter's name and other parameters as text parts. A file over 50 MB is
  refused with a clear message before upload
  Evidence: `test/presentation/features/job_detail/parameter_form_types_test.dart` "file parameters show the chosen file and offer replace/remove"; `test/data/repositories/jenkins_repository_impl_trigger_test.dart` "file parameters go as a multipart part named after the parameter"; `test/presentation/features/job_detail/parameter_files_notifier_test.dart` "refuses a file over the limit before it is ever uploaded".
- [x] Scenario: Unknown plugin types
  Given a parameter type the app doesn't recognise (Active Choices, Extended
  Choice, Git Parameter, …)
  Then it renders as a text field labelled "Unsupported type (<type>) —
  value sent as text". If that type declares `choices`, a dropdown is used
  instead
  Evidence: `test/presentation/features/job_detail/parameter_form_types_test.dart` "unknown plugin types are labelled as sent-as-text"; declared choices use a dropdown (`test/presentation/features/job_detail/parameter_form_test.dart` "choice parameters render a dropdown of the declared choices", `parameter_form.dart`).
- [ ] Scenario: Validation
  Given an empty required-looking value (a choice with no selection, or an
  unpicked run)
  Then Trigger is disabled with an inline reason, never a failed request
  Open: not proven: no test shows Trigger disabled with an inline reason for an invalid value (e.g. an unpicked required run).

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
- [ ] Scenario: Type detection
  Given the tree query requests `_class` and `displayName`
  Then `…WorkflowMultiBranchProject` and `jenkins.branch.OrganizationFolder`
  render with distinct icons, and folders are detected by class as well as
  by the presence of `jobs`
  Open: partly: folders are detected by class (`test/presentation/features/home/folder_breadcrumb_notifier_test.dart` "a folder is recognised by class even when its jobs were not fetched"), but no test checks the distinct multibranch / organization-folder icons.
- [x] Scenario: Readable branch names
  Given a branch job named `feature%2Flogin`
  Then the tile, app bar, breadcrumb, and history show `displayName`
  (`feature/login`), falling back to a URL-decoded `name`
  Evidence: `test/presentation/features/home/visible_jobs_provider_test.dart` "search matches the display label and is case-insensitive"; `test/presentation/features/home/folder_breadcrumb_notifier_test.dart` "navigateInto pushes a folder reference with its display label"; `test/domain/jenkins/jenkins_link_test.dart` "multibranch names stay encoded in the URL, decoded in the label".
- [x] Scenario: Grouping
  Given I open a multibranch project
  Then its jobs are grouped into "Branches", "Pull Requests", and "Tags"
  sections using the project's `views[name,jobs[url]]` (branch-api views
  `default`, `change-requests`, `tags`). If views are unavailable, one flat
  list is shown
  Evidence: `test/domain/jenkins/branch_kind_test.dart` "maps the branch-api view names", "classifies each job, preferring the more specific view"; `test/data/repositories/jenkins_repository_impl_gap_coverage_test.dart` "fetchBranchKinds classifies jobs from the project views"; one list until views load (`home_screen.dart`).
- [x] Scenario: Scan repository now
  Given I tap "Scan now" on a multibranch project or organization folder
  and confirm
  Then `POST {projectUrl}build?delay=0` is sent (CSRF crumb attached), a
  toast confirms it, and the project refreshes when the scan finishes
  (polling `{projectUrl}indexing/api/json` while it runs). I can open the
  scan log at `{projectUrl}indexing/consoleText` in the console viewer
  Evidence: `test/data/repositories/jenkins_repository_impl_gap_coverage_test.dart` "scanMultibranch POSTs build?delay=0 and accepts the 302"; `test/presentation/features/home/multibranch_scan_notifier_test.dart` "polls the indexing log until done, then refreshes the project".
- [x] Scenario: Permission denied
  Given the scan request returns 403
  Then an `AuthFailure` message about permission is shown
  Evidence: `test/presentation/features/home/multibranch_scan_notifier_test.dart` "a refused scan stops and reports the failure".

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
- [x] Scenario: Open stage log
  Given a pipeline build with stages
  When I tap a stage chip
  Then a stage detail sheet lists its steps
  (`GET {build}execution/node/{stageId}/wfapi/describe` →
  `stageFlowNodes[name,status,durationMillis,parameterDescription]`), and
  tapping a step shows its log (`…/execution/node/{nodeId}/wfapi/log` →
  `text`, `hasMore`), live-updating while it runs
  Evidence: `test/presentation/features/job_detail/stage_detail_sheet_test.dart` "the first failed step opens itself and shows its log"; `test/data/repositories/jenkins_repository_impl_gap_coverage_test.dart` "fetchStageSteps reads stageFlowNodes", "fetchStepLog tolerates the missing text key of an empty log".
- [x] Scenario: Failed step highlighted
  Then the first `FAILED` step is expanded and scrolled into view
  automatically
  Evidence: `test/presentation/features/job_detail/stage_detail_sheet_test.dart` "the first failed step opens itself and shows its log".
- [x] Scenario: Parallel branches
  Given a stage runs parallel branches
  Then each branch appears as a sub-row with its own status and log
  Evidence: `test/presentation/features/job_detail/stage_detail_sheet_test.dart` "a parallel stage lists each branch with its own steps".
- [x] Scenario: Truncated step log
  Given `hasMore` is true for a finished step
  Then a "View full log" action opens the full console (US-LOG-01) instead
  Evidence: `test/presentation/features/job_detail/stage_detail_sheet_test.dart` "a truncated step log offers the full console".
- [x] Scenario: Endpoint unavailable
  Given a `wfapi` endpoint returns 404
  Then the chip falls back to opening the full console, as today
  Evidence: `test/presentation/features/job_detail/stage_detail_sheet_test.dart` "without step details it points to the full log"; `test/data/repositories/jenkins_repository_impl_gap_coverage_test.dart` "fetchStageSteps is Ok(null) on 404 (no Pipeline REST API)".

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
- [x] Scenario: Links shown
  Given the detail tree includes `lastSuccessfulBuild`, `lastFailedBuild`,
  `lastStableBuild`, and `lastUnsuccessfulBuild` (`[number,url,timestamp]`)
  Then the job detail shows compact chips "Last success #N · 2h ago" and
  "Last failure #M" for whichever exist
  Evidence: `test/presentation/features/job_detail/build_links_test.dart` "links to the last success and last failure (US-JX-05)".
- [x] Scenario: Open
  When I tap a chip
  Then that build's detail (US-JX-14's build detail screen, or the log if
  that screen isn't built yet) opens
  Evidence: `test/presentation/features/job_detail/build_links_test.dart` "links to the last success and last failure (US-JX-05)" (each opens that build's detail, `job_detail_screen.dart` `_BuildLinks`).
- [x] Scenario: None exist
  Then the chips are omitted, never shown empty
  Evidence: `test/presentation/features/job_detail/job_detail_confirmation_test.dart` "shows last success/failure links only when they differ (US-JX-05)".

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
- [x] Scenario: Paging
  Given per-job history shows 20 builds
  When I scroll near the end
  Then the next page loads via `allBuilds[…]{20,40}` (then `{40,60}`, …),
  stopping when a page comes back short
  Evidence: `test/presentation/features/history/job_history_pages_notifier_test.dart` "loads page after page until a short page ends history"; `test/data/repositories/jenkins_repository_impl_gap_coverage_test.dart` "pages with allBuilds{start,start+count} (US-JX-06)".
- [x] Scenario: Filters
  Then I can filter by result (All / Failed / Unstable / Success / Aborted /
  Running) and by "started by me" (cause `userId` equals the server
  username). Filters apply to loaded pages, and "load more" continues until
  a page contains matches or history ends
  Evidence: `test/domain/jenkins/history_filter_test.dart` "result filters", "started by me combines with the result filter"; `test/presentation/features/history/job_history_pages_notifier_test.dart` "filter chips narrow the list", "when a filter hides every loaded build, offers to dig back".
- [x] Scenario: Job search shows the folder path
  Given a job search result
  Then the tile shows its folder path (`team / service`) under the name
  Evidence: `test/domain/jenkins/history_filter_test.dart` "folderPathOf"; `test/presentation/features/home/home_tree_states_test.dart` "a search result shows its folder and opens the job" (2026-11-21).
- [ ] Scenario: Empty state is refreshable
  Given no jobs or no results
  Then pull-to-refresh still works
  Open: not proven: the empty list sits in a `RefreshIndicator` (AUD-33, `home_screen.dart`), but no test pulls to refresh an empty folder.

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
- [ ] Scenario: Smooth at scale (performance fix)
  Given a 50,000-line log streaming live
  Then only new chunks are sanitized and split (incrementally), scrolling
  stays smooth, and memory is capped (the last 20,000 lines are kept, with
  "Load earlier lines" fetching earlier content via `consoleText` on demand)
  Open: partly: chunks are decoded incrementally and memory is capped (`test/domain/jenkins/console_decoder_test.dart` "decodes a 50,000-line log in one pass quickly (AUD-12)"; `test/presentation/features/build_log/build_log_notifier_test.dart` "keeps at most maxConsoleLines, counting what was dropped", "a huge log opens at its tail and drops the leading fragment"), but there is no "Load earlier lines" action; "Save full log" is the way to get the start.
- [x] Scenario: Transient error keeps the log
  Given a poll fails mid-stream
  Then the log stays visible with an inline "Reconnecting…" banner, and
  polling resumes from the last offset with backoff (1s, 2s, 4s, max 15s)
  Evidence: `test/presentation/features/build_log/build_log_notifier_test.dart` "a failed poll keeps the log and retries with backoff (AUD-13)".
- [x] Scenario: Search
  When I search
  Then matches are highlighted with a "3 / 17" counter and next/previous
  buttons; search is case-insensitive
  Evidence: `test/presentation/features/build_log/build_log_screen_test.dart` "search shows the match counter"; `test/presentation/features/build_log/console_log_viewer_test.dart` "highlights search matches"; `test/presentation/features/build_log/console_notifiers_test.dart` "search finds lines and steps through matches, wrapping".
- [x] Scenario: Jump to first error
  Then an action jumps to the first line matching `ERROR`, `FAILURE`,
  `Exception`, or `BUILD FAILED`
  Evidence: `test/presentation/features/build_log/build_log_screen_test.dart` "a log without errors says so on Jump to first error"; `test/domain/jenkins/console_decoder_test.dart` "isErrorLine and searchLines".
- [x] Scenario: ANSI colors
  Given the log contains ANSI SGR color codes (AnsiColor plugin)
  Then foreground and background colors and bold are rendered, not stripped.
  Jenkins console-note payloads are still removed
  Evidence: `test/domain/jenkins/console_decoder_test.dart` "renders SGR colors and bold instead of stripping them", "drops Jenkins console-note payloads (ESC[8m…ESC[0m)"; `test/presentation/features/build_log/console_log_viewer_test.dart` "renders ANSI colors instead of stripping them".
- [x] Scenario: Timestamps
  Given the Timestamper plugin is installed
  Then a toggle shows per-line timestamps from
  `{build}timestamps/?time=HH:mm:ss&appendLog`. If that returns 404, the
  toggle is hidden
  Evidence: `test/presentation/features/build_log/console_notifiers_test.dart` "timestamps are fetched for exactly the visible lines, by absolute line", "a missing Timestamper plugin is reported, not an error"; `test/presentation/features/build_log/console_log_viewer_test.dart` "shows timestamps in a gutter when enabled".
- [x] Scenario: Wrap and font size
  Then I can toggle line wrap (off means horizontal scroll) and pick a font
  size (3 steps); both preferences persist in `shared_preferences`
  Evidence: `test/presentation/features/build_log/console_notifiers_test.dart` "prefs persist and reload"; `test/presentation/features/build_log/console_log_viewer_test.dart` "no-wrap mode scrolls horizontally with fixed row heights".
- [x] Scenario: Full log download
  Then "Save full log" downloads `{build}consoleText` to a temp file and
  shares it as a `.log` file (not as a giant text payload)
  Evidence: `test/presentation/features/build_log/console_notifiers_test.dart` "save full log downloads, shares, then deletes the temp file".

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
- [x] Scenario: Details
  Given the test-report tree adds `errorDetails,errorStackTrace,duration,age`
  on failing cases
  Then the failing-tests sheet lists each case, expandable to show the error
  message and a monospaced, copyable stack trace
  Evidence: `test/presentation/features/job_detail/failing_tests_sheet_test.dart` "lists failures, new ones first, with expandable details".
- [x] Scenario: Regressions highlighted
  Then cases with `status == REGRESSION` or `age == 1` are marked "New
  failure"
  Evidence: `test/presentation/features/job_detail/failing_tests_sheet_test.dart` "lists failures, new ones first, with expandable details".
- [ ] Scenario: Very large reports
  Given more than 200 failing cases
  Then the first 200 are shown with a count of the rest (bounded payload:
  the tree request uses `{0,200}` on cases)
  Open: partly: the request caps cases at 200 (`jenkins_repository_impl.dart`, checked by path in `test/data/repositories/jenkins_repository_impl_test_report_test.dart`) and the sheet has a "N more not shown" line (`build_sections.dart`), but no test asserts that line.

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
- [x] Scenario: Queue list
  When I open "Queue" (reachable from Home's overflow menu)
  Then `GET /queue/api/json?tree=items[id,why,inQueueSince,stuck,blocked,buildable,task[name,url,color]]`
  lists items with job name, time waiting, and reason, refreshing every 5s
  while visible
  Evidence: `test/presentation/features/queue/queue_screen_test.dart` "lists queued builds with position, reason and stuck flag"; `test/presentation/features/queue/queue_notifier_test.dart` "fetchQueue parses items and rewrites task URLs"; `test/presentation/features/queue/refresh_timing_test.dart` "Queue refreshes 5s later".
- [x] Scenario: Cancel a queued item
  When I cancel an item and confirm
  Then `POST /queue/cancelItem?id={id}` is sent (crumb attached), and the
  item disappears on the next refresh
  Evidence: `test/presentation/features/queue/queue_notifier_test.dart` "cancel POSTs cancelItem?id= and treats 204 as success", "cancel removes the item at once and confirms"; `test/presentation/features/queue/queue_screen_test.dart` "cancel asks first; Remove cancels that item only".
- [x] Scenario: Stuck items
  Given `stuck == true`
  Then the item is flagged "Stuck" in warning style (text plus icon)
  Evidence: `test/presentation/features/queue/queue_screen_test.dart` "lists queued builds with position, reason and stuck flag".
- [x] Scenario: Empty queue
  Then "Nothing is waiting" is shown
  Evidence: `test/presentation/features/queue/queue_screen_test.dart` "an empty queue says so".

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
- [ ] Scenario: Opt in
  Given I trigger a build (or tap "Notify me" on a running one)
  Then that build is added to a watch list, and on first use the app
  requests notification permission (Android 13+ `POST_NOTIFICATIONS`, iOS
  alert authorization) with a rationale screen first
  Open: partly: watching adds to the list and asks for permission (`test/presentation/features/notifications/build_watch_notifier_test.dart` "watching a build persists it and schedules the background check", "a denied permission adds nothing"; `test/presentation/features/job_detail/watch_menu_test.dart` "a denied permission explains where to turn it on"), but there is no rationale screen before the OS prompt.
- [x] Scenario: Foreground and recently backgrounded
  While the app process is alive, watched builds are polled (reusing the 5s
  cadence while visible, 30s when backgrounded), and on completion a local
  notification shows "✅ api-service #142 succeeded (4m 12s)" or
  "❌ … failed"
  Evidence: `test/presentation/features/notifications/watch_runner_test.dart` "notifies for a finished build and drops its watch"; `test/domain/jenkins/build_watch_test.dart` "notifies once when it finishes, then is dropped". The 30-second backgrounded cadence is device behaviour (M-01).
- [ ] Scenario: Background best-effort
  Given the app is suspended
  Then a periodic background task (≥15 min, OS-scheduled) checks watched
  builds. The UI states clearly that background checks are best-effort and
  may be delayed by the OS
  Open: the background task is registered on Android and iOS only (`test/presentation/features/notifications/background_watch_test.dart` "only Android and iOS hosts schedule background checks"), but whether it runs is device-only (M-01), and the Jenkins watch UI does not say checks are best effort (only the SonarQube watch does).
- [x] Scenario: Tap opens the build
  When I tap the notification
  Then the app opens that job's detail screen
  Evidence: `test/presentation/features/open_link/open_link_location_test.dart` "a notification payload opens the open-link screen with its server"; `test/presentation/features/open_link/open_link_screen_test.dart` "a build link on the active server opens that build".
- [x] Scenario: Tap for a build on a server that isn't active (AUD-45)
  Given the notification is for a build on server B while server A is active
  When I tap it
  Then the app asks to switch to B first (as for any Jenkins link,
  US-JX-19), and no request carrying A's credentials is ever sent to B's
  host
  Evidence: `test/presentation/features/open_link/open_link_screen_test.dart` "a link on another saved server asks before switching", "declining the switch goes Home without changing servers".
- [x] Scenario: Watched jobs
  Given I mark a job as "Watch"
  Then every new build of it notifies on completion until I unwatch it
  Evidence: `test/domain/jenkins/build_watch_test.dart` "notifies for the newest finished build only, then advances", "stays quiet until there is a newer finished build".
- [x] Scenario: Credentials unavailable in background
  Given the background task can't obtain the Jenkins credential (logged out,
  or server deleted)
  Then the watch entry is dropped silently. No notification ever includes
  secrets or log content
  Evidence: `test/presentation/features/notifications/watch_runner_test.dart` "drops watches whose server credentials are gone"; `test/domain/jenkins/build_watch_test.dart` "a redacted notification names nothing (AUD-54)".

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
- [x] Scenario: Pin and unpin
  When I long-press a job tile or tap the pin icon on job detail
  Then it's added to or removed from "Pinned" for the active server
  Evidence: `test/presentation/features/home/pinned_jobs_notifier_test.dart` "toggling again unpins".
- [x] Scenario: Pinned section
  Then Home shows a "Pinned" section above the tree at root level, with live
  status colors from the fetched tree or the job's own lightweight fetch
  Evidence: `test/presentation/features/home/pinned_jobs_notifier_test.dart` "Home shows a Pinned section with live status and stale pins".
- [x] Scenario: Per server, persisted
  Then pins are stored per server id in `shared_preferences` (job URLs only,
  no secrets) and survive restarts
  Evidence: `test/presentation/features/home/pinned_jobs_notifier_test.dart` "pins persist per server and reload on server switch", "corrupt stored pins are dropped, not a crash".
- [x] Scenario: Stale pin
  Given a pinned job returns 404
  Then it shows as "Not found" with a remove action
  Evidence: `test/presentation/features/home/pinned_jobs_notifier_test.dart` "Home shows a Pinned section with live status and stale pins".

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
- [x] Scenario: Node list
  When I open "Nodes"
  Then `GET /computer/api/json?tree=computer[displayName,offline,temporarilyOffline,offlineCauseReason,idle,numExecutors,executors[idle,progress,currentExecutable[url,fullDisplayName]],monitorData[*]]`
  lists nodes with online/offline state, busy/total executors, and
  disk-space or response-time warnings from `monitorData` when present
  Evidence: `test/presentation/features/nodes/nodes_test.dart` "parses nodes, executors, and the disk warning", "shows status, load, and running builds"; `test/presentation/features/queue/refresh_timing_test.dart` "Nodes refreshes 10s later".
- [x] Scenario: Executor drill-down
  When I open a node
  Then each busy executor shows its running build with progress, tappable to
  that build
  Evidence: `test/presentation/features/nodes/nodes_test.dart` "shows status, load, and running builds".
- [x] Scenario: Mark temporarily offline or online
  When I toggle a node and confirm (with an optional reason)
  Then `POST /computer/{encodedName}/toggleOffline?offlineMessage=…` is sent.
  The built-in node's path segment is `(built-in)`
  Evidence: `test/presentation/features/nodes/nodes_test.dart` "toggleOffline posts the reason and accepts the 302", "taking a node offline asks for a reason and sends it".
- [x] Scenario: No permission
  Given `Computer/Disconnect` is denied (403)
  Then the permission `AuthFailure` copy is shown and the toggle is hidden
  from then on for this session
  Evidence: `test/presentation/features/nodes/nodes_test.dart` "after a 403 the switches are hidden for the session", "NodesState keeps canToggle through a refresh".

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
- [x] Scenario: State shown
  Given the tree and detail queries include `buildable` (and `color ==
  disabled`)
  Then disabled jobs show a "Disabled" badge, and Trigger is disabled with
  the reason shown
  Evidence: `test/presentation/features/job_detail/job_enabled_test.dart` "a disabled job says so and cannot be triggered; enable works".
- [x] Scenario: Toggle
  When I choose Disable (or Enable) from the job's overflow menu and confirm
  Then `POST {job}disable` (or `enable`) is sent and the detail refreshes
  Evidence: `test/presentation/features/job_detail/job_enabled_test.dart` "disable POSTs {job}disable and accepts the 302", "a disabled job says so and cannot be triggered; enable works".
- [x] Scenario: Not supported
  Given the job type doesn't support it (404 or 405)
  Then "This job type can't be disabled" is shown
  Evidence: `test/presentation/features/job_detail/job_enabled_test.dart` "a refused toggle explains the multibranch case".

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
- [x] Scenario: Build detail screen
  When I open any build from history or links
  Then a build detail screen shows result, duration, causes, changes,
  artifacts, tests, stages, and log link (reusing the job-detail cards,
  scoped to that build), plus `description` and `keepLog`
  Evidence: `test/presentation/features/build_detail/build_detail_screen_test.dart` "shows the build, with the description as plain text"; `test/presentation/features/build_detail/build_detail_sections_test.dart` (2026-11-21: causes, changes, tests, artifacts, stages).
- [x] Scenario: Keep forever
  When I toggle "Keep forever" and confirm
  Then `POST {build}toggleLogKeep` is sent, and the state is re-fetched
  rather than assumed
  Evidence: `test/presentation/features/build_detail/build_detail_screen_test.dart` "keep forever asks, toggles, and re-reads the server".
- [x] Scenario: Description
  When I edit the description and save
  Then `POST {build}submitDescription` with form field `description` is
  sent. The description is rendered as **plain text** (Jenkins descriptions
  can contain HTML, which is never rendered)
  Evidence: `test/presentation/features/build_detail/build_detail_screen_test.dart` "the description can be edited", "shows the build, with the description as plain text".

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
- [x] Scenario: Trend card
  Given at least 5 finished builds are loaded
  Then job history shows a success rate over the last N (20 or 50,
  selectable), average and p90 duration, and a duration sparkline with
  failed builds marked
  Evidence: `test/presentation/features/history/build_trends_card_test.dart` "shows stats, an accessible chart, and switches window".
- [x] Scenario: Computed locally
  Then all stats are computed by a pure domain function from already-fetched
  history. No new endpoint
  Evidence: `test/domain/jenkins/build_trends_test.dart` "success rate, average, p90, and oldest-first points (US-JX-15)", "the window limits the sample to the newest builds".
- [x] Scenario: Too few builds
  Then "Not enough builds for trends" is shown
  Evidence: `test/presentation/features/history/build_trends_card_test.dart` "says when there are too few builds"; `test/domain/jenkins/build_trends_test.dart` "too few finished builds gives no trends".

**Security & Privacy Notes**
- None.

**UI / Design Notes**
- Chart drawn with `CustomPaint` following the dataviz guidance: single
  hue, failure marks with shape plus text.

**Non-Functional Notes**
- NFR-A11Y-03, NFR-TEST-01. No chart dependency.

---

### US-JX-16 — Replay with an edited pipeline script

> **Status: built 2026-11-20 (P11-29), inline-script pipelines only;** all nine criteria ticked against code and tests (`test/data/repositories/replay_script_test.dart`, `test/presentation/features/replay_edit/replay_edit_screen_test.dart`). Live pass on the owner's Jenkins: M-22.
> The 2026-09-30 gate (P11-27) closed it because the *build's* original
> script is only in the `replay/` HTML page. The owner chose the documented
> source instead: the job's `config.xml`, which holds the script of an
> inline ("Pipeline script") job. No HTML is scraped. Jobs whose
> Jenkinsfile comes from SCM are told replay with edits isn't available.
> The Jenkins freeze (CLAUDE.md §11) is lifted for this story only.

**Priority:** Could
**Source:** report item D#19; owner decision 2026-11-20
**Dependencies:** US-PIPE-08 (Replay sheet), US-JX-14, PI-01/PI-02 (read-only, protected jobs)

As a pipeline author
I want to replay a build with a small script edit
So that I can test a fix without committing

**Acceptance Criteria**
- [x] AC1 Entry. The Replay sheet shows "Replay with edits…" only for a
      pipeline job (`org.jenkinsci.plugins.workflow.job.WorkflowJob`); it
      opens a full-screen editor for that build.
- [x] AC2 Load. The editor loads the job's inline script from
      `GET {job}/config.xml` (`CpsFlowDefinition` → `<script>`, XML entities
      decoded) into a monospaced, always-dark editor, and keeps the
      definition's `sandbox` value for display.
- [x] AC3 SCM pipelines. For a `CpsScmFlowDefinition` (Jenkinsfile from a
      repository) the screen says "Replay with edits works for jobs whose
      script is in Jenkins. This job's Jenkinsfile comes from a repository."
      and offers no editor.
- [x] AC4 Replayed builds. When the build's causes include "Replayed #",
      a banner warns that the loaded script is the job's current script and
      may differ from what this build ran.
- [x] AC5 Permissions. A 403 on `config.xml` says the user needs permission
      to read the job's configuration; a 403/404 on submit says the build
      can't be replayed by this user. Nothing else is shown as a crash.
- [x] AC6 Two confirmations. Replay asks twice: "Replay #N with edits?",
      then a second dialog stating "This runs arbitrary pipeline code on
      <server>." that requires typing the job name. The app lock re-prompt
      (US-JX-21) applies when it is on.
- [x] AC7 Submit. `POST {build}replay/run`, form-encoded, with
      `_.mainScript` and the Stapler `json` field `{"mainScript": …}`; the
      CSRF crumb goes through the existing interceptor (NFR-SEC-06); the 302
      is success.
- [x] AC8 New build. After submitting, the app looks for the new build
      (newer than #N, cause "Replayed #N") for up to 10 seconds and opens it;
      if it isn't found yet it opens the job's history with "Replay started".
- [x] AC9 Safety. On a read-only server (PI-01) the Replay button is off
      and reads "Read-only"; in demo mode the screen says the action isn't
      available in the demo.

**Layer impact (CLAUDE.md development rules)**
- **App:** yes — repository methods, notifier, editor screen, route, Replay
  sheet entry, demo repository, What's new line.
- **Website:** yes, copy only — changelog line for 1.0. No portal change: the
  portal stores credentials and never talks to Jenkins.
- **Backend:** none — the app calls Jenkins directly with the user's own
  credentials (CLAUDE.md §1); nothing is stored.

**Tests needed**
- Repository: inline script parsed and entities decoded; SCM definition
  recognised; 403 → `PermissionFailure`; submit sends `_.mainScript` and
  `json` form-encoded to `replay/run` and accepts the 302.
- Notifier: finds the new build by its "Replayed #N" cause; gives up after
  the time limit.
- Widget: entry only for pipelines; editor shows the script; SCM message;
  replayed-build banner; both confirmations, and cancelling either sends
  nothing; submit then opens the new build; read-only blocks; demo message.

**Design note**
- Screen `ReplayEditScreen` (route `/home/job/build/replay-edit`, extra
  `(JenkinsJob, JenkinsBuild)`): header with server, title "Replay #N with
  edits", `sandbox` chip, the editor (`TextField`, monospaced, console
  colours, no autocorrect), and a bottom "Replay" button.
- `ReplayScriptNotifier(jobUrl)` loads the script (`AsyncNotifier`);
  `ReplayEditNotifier` submits and finds the new build. The decision logic
  (confirmations, read-only, finding the build) lives in notifiers, not in
  `build()` (CLAUDE.md §5).
- The 302 after `replay/run` points at the job, not the new build, so AC8
  matches on the cause text Jenkins writes ("Replayed #N").

**Security & Privacy Notes**
- This executes arbitrary code on the CI server: two confirmations, the
  second naming the server and requiring the job name.
- The script is held in memory only; never cached, logged or sent to the
  backend or to crash reports.

**Non-Functional Notes**
- NFR-SEC-06, NFR-TEST-02. Verified against the HTTP contract recorded by
  P11-27 on the fixture Jenkins 2.568.3; a live run on the owner's Jenkins
  is a manual check (M-22).

---

### US-JX-17 — Views

**Priority:** Could
**Source:** new — report item D#20 (scope change, see the epic intro)
**Dependencies:** US-TREE-01

As a user whose team organises Jenkins by views
I want to switch Home to a view
So that I see my team's jobs, not the whole server

**Acceptance Criteria**
- [x] Scenario: View picker
  Given `GET /api/json?tree=views[name,url],primaryView[name]`
  Then Home's title becomes a picker listing views, defaulting to the
  primary view ("All")
  Evidence: `test/presentation/features/home/views_test.dart` "the Home title is a view picker".
- [x] Scenario: View contents
  When I pick a view
  Then `GET {viewUrl}api/json?tree=jobs[…]` supplies Home's root list;
  folder navigation and search work within it
  Evidence: `test/presentation/features/home/views_test.dart` "selecting a view lists it at the root, persisted per server", "switching views resets the folder breadcrumb".
- [x] Scenario: Remembered
  Then the selected view is persisted per server (`shared_preferences`)
  Evidence: `test/presentation/features/home/views_test.dart` "selecting a view lists it at the root, persisted per server".

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
- [ ] Scenario: Info
  Then Settings, under the active server, shows the Jenkins version (the
  `X-Jenkins` response header) and the node mode
  Open: partly: Settings shows the active server's Jenkins version (added 2026-11-21, `test/presentation/features/settings/jenkins_server_list_test.dart` "the active server shows its Jenkins version…"), but not the node mode (`ServerStatus` has no mode field).
- [x] Scenario: Quiet down
  Given `/api/json?tree=quietingDown` is true
  Then Home shows a persistent banner "Jenkins is preparing for shutdown —
  new builds won't start"
  Evidence: Fixed 2026-11-21: tests added: `test/presentation/features/home/home_tree_states_test.dart` "a server preparing for shutdown shows a banner on Home", "a running server shows no shutdown banner".
- [x] Scenario: Outdated version
  Given the version is below the current LTS baseline configured in
  `core/config`
  Then an informational note is shown (not blocking)
  Evidence: `test/domain/jenkins/server_status_test.dart` "outdated is strictly older than the baseline"; Fixed 2026-11-21: tests added: `test/presentation/features/settings/jenkins_server_list_test.dart` ("consider upgrading" for an old version, none for a current one).

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
- [x] Scenario: Custom scheme
  Given a link `jobtrigger://open?url=<encoded Jenkins URL>`
  Then the app opens the matching job or build screen
  Evidence: `test/presentation/features/open_link/open_link_screen_test.dart` "a build link on the active server opens that build", "a console link opens the log".
- [x] Scenario: Share into app
  Given I share a Jenkins URL to JobTrigger (Android share intent; the
  in-app paste action was removed in P19-06, and Home's "Open Jenkins link"
  now opens the active server in the browser)
  Then the URL is matched against configured servers by host and path
  prefix, the matching server is activated after confirmation if it isn't
  active, and the job or build opens
  Evidence: `test/presentation/features/open_link/open_link_screen_test.dart` "a link on another saved server asks before switching"; matching by host and path prefix: `test/domain/jenkins/jenkins_link_test.dart` "the longest matching context path wins".
- [x] Scenario: Any other in-app path from outside (AUD-51)
  Given a link opens `jobtrigger://app/<anything but /open>`
  Then a screen that needs in-app context (job, build, log, history,
  workflows) opens Home instead, and an unknown path shows "This link
  doesn't lead anywhere in JobTrigger" with a way back; the app never
  shows an error screen
  Evidence: `test/presentation/navigation/app_router_test.dart` "an extra-only route opened from outside lands on Home".
- [x] Scenario: Unknown server
  Given no configured server matches
  Then "No saved server matches this link" is shown, with "Add server"
  prefilled with the origin
  Evidence: `test/presentation/features/open_link/open_link_screen_test.dart` "a link to an unknown server is refused", "a link carrying credentials is refused".
- [x] Scenario: Parsing
  Then `/job/a/job/b/123/console` style paths resolve to job `a/b`, build
  123, and screen log, by a pure, unit-tested parser
  Evidence: `test/domain/jenkins/jenkins_link_test.dart` "a nested job, a build, and its console", "view prefixes are skipped; job-level pages open the job".

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
- [x] Scenario: Cache on success
  Given a successful job-tree or folder fetch
  Then the result (names, URLs, colors, last-build numbers; no secrets) is
  written per server id to the app's documents directory
  Evidence: `test/data/cache/job_tree_cache_test.dart` "round-trips a listing with its save time (US-JX-20)", "servers and folders are separate entries".
- [ ] Scenario: Offline fallback
  Given a later fetch fails with `NetworkFailure`
  Then the cached tree is shown with a banner "Offline — showing data from
  14:32", and trigger, cancel, and other POST actions are disabled with the
  reason
  Open: partly: the saved tree shows with "Offline — showing data from HH:MM" (`test/presentation/features/home/offline_tree_test.dart` "offline, the last saved listing is served and flagged (US-JX-20)", "Home shows the offline banner"), but no test shows trigger/cancel disabled with a reason while offline.
- [x] Scenario: Cache hygiene
  Then the cache for a server is deleted when that server is deleted or the
  user logs out
  Evidence: `test/data/cache/job_tree_cache_test.dart` "clearServer and clearAll delete what they should"; deleting a server clears it (`active_server_notifier.dart` `deleteServer`) and logout clears all (`auth_notifier.dart`).

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
- [x] Scenario: Enable
  When I enable "Require biometrics" in Settings
  Then the app authenticates once to confirm, then requires it on cold start
  and on resume after more than 5 minutes in the background (the timeout
  is selectable: immediately, 1, 5, or 15 minutes)
  Evidence: `test/presentation/features/app_lock/app_lock_notifier_test.dart` "enabling authenticates first and persists", "when on, a cold start locks and prompts straight away", "locks on resume only after the timeout".
- [x] Scenario: Fallback
  Given biometrics fail or are unavailable
  Then device passcode fallback is allowed. If no device security is set,
  the setting can't be enabled and the reason is explained
  Evidence: `test/presentation/features/app_lock/app_lock_notifier_test.dart` "can't be enabled without device security"; `test/presentation/features/app_lock/app_lock_settings_section_test.dart` "without device security it explains why it stays off".
- [x] Scenario: Privacy screen
  Then while locked, and in the app switcher snapshot, content is obscured
  Evidence: `test/presentation/features/app_lock/app_lock_gate_test.dart` "a locked app hides its content and unlocks on success (US-JX-21)", "the app switcher sees the privacy screen, not the content".
- [x] Scenario: Sensitive actions (optional)
  Given "Require for trigger/approve" is on
  Then trigger, cancel, input approval, replay, node toggle, and job disable
  each re-prompt
  Evidence: `test/presentation/features/app_lock/app_lock_notifier_test.dart` "sensitive actions re-prompt only when asked to"; `test/presentation/features/job_detail/trigger_build_notifier_test.dart` "with "Require for actions" on, a declined prompt triggers nothing (US-JX-21)".

- [x] Scenario: Weakening the lock (AUD-53)
  When I turn the lock off, turn "Require for actions" off, or choose a
  longer lock timeout
  Then I authenticate first, and a cancelled or failed prompt leaves the
  setting as it was; making the lock stricter needs no prompt
  Evidence: `test/presentation/features/app_lock/app_lock_notifier_test.dart` "turning it off", "a longer timeout, but not a shorter one", "turning the action re-prompt off, but not on".

- [x] Scenario: Outside the app while locked (AUD-54, default decided
  2026-10-20; revisit if users want names back)
  Given the app lock is on
  Then the home-screen widget shows "Pinned job 1", "Pinned job 2", … with
  each status, build notifications read "A watched build finished — Open
  JobTrigger to see which", and on Android every build notification is
  `private` on a secure lock screen ("Contents hidden")
  Evidence: `test/presentation/features/home_widget/home_widget_sync_test.dart` "with the app lock on, the widget shows no job names"; `test/domain/jenkins/build_watch_test.dart` "a redacted notification names nothing (AUD-54)". Android lock-screen visibility is device behaviour (M-01).

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
- [x] Scenario: Detect likely password
  Given the secret doesn't look like a Jenkins API token (legacy 32 hex
  characters, or current `11` plus 32 hex characters)
  Then the server form shows a non-blocking warning: "This looks like a
  password. Jenkins API tokens are safer — they can be revoked without
  changing your password"
  Evidence: `test/presentation/features/settings/server_token_advisory_test.dart` "a password-looking secret shows the token advisory (US-JX-22)", "a real API token shows no advisory".
- [x] Scenario: Help link
  Then a "Create a token" link opens `{jenkinsURL}/me/configure` in the
  browser
  Evidence: `test/presentation/features/settings/token_wizard_test.dart` "the Jenkins wizard names the right steps and link".
- [x] Scenario: Existing servers
  Given a saved server matches the password heuristic
  Then its row in Settings shows a small "Uses password" advisory
  Evidence: Fixed 2026-11-21: asserted in `test/presentation/features/settings/jenkins_server_list_test.dart` "the active server shows its Jenkins version…; a password-looking secret is noted" ("Uses a password").

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
- [x] Scenario: Widget data
  Given pinned jobs exist
  Then whenever the app refreshes their status (foreground or background
  task, US-JX-10), it writes a small snapshot (name, color, last build
  number and time; **no credentials**) to the shared widget store and
  requests a widget reload
  Evidence: `test/presentation/features/home_widget/home_widget_sync_test.dart` "signed in, a refreshed pin status reaches the widget (US-JX-23)", "logout clears the widget snapshot".
- [ ] Scenario: Widget
  Then small and medium widgets (iOS WidgetKit, Android AppWidget) show up
  to 2 or 4 pinned jobs with status (icon plus text) and "updated 5m ago".
  Tapping a job deep-links (US-JX-19) into it
  Open: device-only: the iOS WidgetKit and Android AppWidget layouts and their deep links are native code with no Flutter test; check on the iPhone (M-01).
- [ ] Scenario: No data
  Then the widget shows "Pin jobs in JobTrigger"
  Open: device-only: the empty "Pin jobs in JobTrigger" state is drawn by the native widgets (M-01).

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
