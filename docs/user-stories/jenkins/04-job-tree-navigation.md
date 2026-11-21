# Epic: TREE — Job Tree Navigation

Reads the active Jenkins server's job/folder tree via
`GET {baseURL}/api/json?tree=jobs[name,url,color,jobs[...]]`, recursed to a
bounded depth of 6 levels, with every returned `url` rewritten to the active
credential's configured host (see `docs/api-reference.md`).

---

### US-TREE-01 — View the job/folder tree of the active server

**Priority:** Must
**Source:** tasks/phase-4-jenkins-job-tree.md (P4-03, P4-06, P4-10)
**Dependencies:** US-CRED-05 (an active server must exist)

As a user
I want to see the list of jobs (and folders) on my active Jenkins server as
soon as I open the app
So that I can quickly find the job I care about

**Acceptance Criteria**
- [ ] Scenario: Tree loads successfully
  Given an active server with jobs exists
  When I open the home screen
  Then the recursive tree fetch runs (depth-limited to 6 levels), each job
  shows its name and a status indicator derived from Jenkins' `color` field
  (success/failure/unstable/building/disabled/no-builds-yet), and folders
  are visually distinguished from leaf jobs
  Open: superseded on purpose: Home no longer crawls the tree; it loads one level at a time (AUD-20, `test/presentation/features/home/visible_jobs_provider_test.dart` "Home root is one lazy level, never the recursive crawl (AUD-20)"), and the 6-level crawl now serves search (`test/data/repositories/jenkins_repository_impl_gap_coverage_test.dart` "the recursive crawl reaches the documented 6 levels (AUD-19)"). The rest is proven: status from `color` (`test/presentation/common_widgets/status_indicator_test.dart`), folders distinct (added 2026-11-21, `test/presentation/features/home/home_tree_states_test.dart` "a folder reads differently from a job with a status"). Needs rewording to the lazy design.
- [ ] Scenario: Deeply nested folder truncation
  Given a folder structure exceeds the 6-level recursion depth
  Then deeper levels are not fetched, and the deepest visible folder
  indicates there's more nesting (e.g. an affordance to drill further
  rather than silently truncating with no signal)
  Open: browsing has no depth limit now (each folder loads on entry, AUD-20), but search crawls 6 levels and says nothing when deeper jobs exist. Needs a "deeper folders not searched" note, or rewording.
- [x] Scenario: Empty server
  Given the active server has no jobs at all
  Then an empty state explains this clearly, distinct from an error state
  Evidence: Fixed 2026-11-21: test added: `test/presentation/features/home/home_tree_states_test.dart` "an empty server says "No jobs found", not an error".
- [x] Scenario: Load failure
  Given the request fails
  Then the failure maps to the correct `AppFailure` (per-server
  `AuthFailure` for 401/403, `NetworkFailure` for unreachable,
  `ServerFailure`/`UnknownFailure` otherwise) with a retry action, per
  US-CRED-05's per-server-auth-failure handling
  Evidence: mapping `test/core/error/app_failure_test.dart` (401 → `AuthFailure`, 403 → `PermissionFailure`, timeouts → `NetworkFailure`, other status → `ServerFailure`); screen: added 2026-11-21, `test/presentation/features/home/home_tree_states_test.dart` "a failed load shows why with Retry, and Retry reloads the same folder"; offline: `test/presentation/features/home/offline_tree_test.dart` "offline with nothing cached is still an error, not empty".

**Security & Privacy Notes**
- No new security surface; reuses the active server's existing Basic Auth
  Jenkins client (US-CRED-05).

**UI / Design Notes**
- Job rows sit in a glass list (US-DESIGN-01); per US-DESIGN-04, list rows
  themselves are flat/translucent (not individually blurred) to keep
  scrolling smooth, with only the surrounding app bar/search bar glass-blurred.
  Status indicators follow US-DESIGN-05 (icon/shape + color, never color
  alone).

**Non-Functional Notes**
- NFR-PERF-02, NFR-TEST-02

---

### US-TREE-02 — Drill into folders with breadcrumb navigation

**Priority:** Must
**Source:** tasks/phase-4-jenkins-job-tree.md (P4-06, P4-07)
**Dependencies:** US-TREE-01

As a user browsing a server organized into folders
I want to drill into a folder and see where I am, with an easy way back
So that I can navigate a nested job structure without getting lost

**Acceptance Criteria**
- [x] Scenario: Drill into a folder
  Given I tap a folder row
  When the folder opens
  Then I see only that folder's direct children, and a breadcrumb trail
  shows the path from the root down to the current folder
  Evidence: `test/presentation/features/home/visible_jobs_provider_test.dart` "entering a folder fetches just that folder"; `test/presentation/features/home/folder_breadcrumb_notifier_test.dart` "navigateInto pushes a folder reference with its display label"; trail "Home / Projects" asserted in `test/presentation/features/home/home_tree_states_test.dart` (2026-11-21).
- [ ] Scenario: Breadcrumb jump
  Given I am several folders deep
  When I tap an earlier breadcrumb segment
  Then I jump directly to that level, not just one level back
  Open: not built: since the P14 redesign the trail is plain text ("Home / A / B") with one Back button (`home_screen.dart` `_Header`), so a level can't be tapped. Jenkins is frozen: owner decision.
- [x] Scenario: Android system back gesture
  Given I am inside a folder on Android
  When I use the system back gesture
  Then it navigates up one folder level (consistent with the breadcrumb),
  not out of the app entirely, until I'm back at the root
  Evidence: `test/presentation/features/home/home_screen_test.dart` "system back navigates up one breadcrumb level instead of popping the route", "system back at the root pops the route normally".
- [x] Scenario: Folder becomes empty/removed mid-browse
  Given a folder I'm viewing had its jobs removed or renamed on the Jenkins
  server since I opened it
  When I pull to refresh at that level
  Then it reflects the new (possibly empty) state without crashing or
  showing stale entries indefinitely
  Evidence: `test/presentation/features/home/visible_jobs_provider_test.dart` "refreshing inside a folder shows its new children (AUD-10)"; an empty folder stays pull-to-refreshable (AUD-33, `home_screen.dart`).

**Security & Privacy Notes**
- None specific.

**UI / Design Notes**
- Breadcrumb rendered as a compact glass pill row (US-DESIGN-01) pinned
  under the app bar.

**Non-Functional Notes**
- NFR-PLAT-02 (Android back-gesture handling)

---

### US-TREE-03 — Search jobs across the entire tree

**Priority:** Must
**Source:** tasks/phase-4-jenkins-job-tree.md (P4-08, P4-09)
**Dependencies:** US-TREE-01

As a user with many jobs across multiple folders
I want to search by name and see matches from anywhere in the tree, not
just the current folder
So that I can jump straight to a job without manually navigating folders

**Acceptance Criteria**
- [x] Scenario: Live search
  Given the full tree has already been fetched
  When I type into the search field
  Then results filter live (client-side, over the already-flattened tree —
  no new network call per keystroke) across all folders, each result
  showing its folder path for context
  Evidence: `test/presentation/features/home/visible_jobs_provider_test.dart` "search crawls the whole tree once, ignoring the breadcrumb", "search matches the display label and is case-insensitive"; folder path on each result: added 2026-11-21, `test/presentation/features/home/home_tree_states_test.dart` "a search result shows its folder and opens the job".
- [x] Scenario: No matches
  Given my search term matches nothing
  Then an explicit "no jobs match" state is shown, not an empty list
  indistinguishable from a loading state
  Evidence: Fixed 2026-11-21: test added: `test/presentation/features/home/home_tree_states_test.dart` "a search with no matches says so" ("No results for …").
- [x] Scenario: Clearing search
  Given I clear the search field
  Then I return to my previous folder view (not forced back to root)
  Evidence: Fixed 2026-11-21: test added: `test/presentation/features/home/home_tree_states_test.dart` "clearing a search returns to the folder you were in".
- [ ] Scenario: Selecting a search result
  Given I tap a result from a different folder than the one I'm in
  Then I navigate to that job's detail directly, and the breadcrumb updates
  to reflect the result's actual folder path
  Open: partly: a result opens its job directly (`test/presentation/features/home/home_tree_states_test.dart` "a search result shows its folder and opens the job"), but the breadcrumb does not move to the result's folder. Owner decision (Jenkins frozen).

**Security & Privacy Notes**
- None specific.

**UI / Design Notes**
- Search bar is part of the glass app bar (US-DESIGN-01); result rows
  match the flat/translucent list-row treatment from US-TREE-01.

**Non-Functional Notes**
- NFR-PERF-02

---

### US-TREE-04 — Pull-to-refresh the job tree

**Priority:** Should
**Source:** tasks/phase-4-jenkins-job-tree.md (P4-05)
**Dependencies:** US-TREE-01

As a user
I want to manually refresh the job list
So that I can see up-to-date status without waiting for or relying on
automatic polling on this screen

**Acceptance Criteria**
- [x] Scenario: Successful refresh
  Given I pull down on the job list
  Then a refresh indicator shows, the tree is refetched from the current
  folder level, and statuses update once the response returns
  Evidence: `test/presentation/features/home/visible_jobs_provider_test.dart` "refreshing inside a folder shows its new children (AUD-10)" (refetches the current folder); `test/presentation/features/home/job_tree_notifier_test.dart` "refresh() re-fetches the job tree".
- [x] Scenario: Refresh failure
  Given the refresh request fails
  Then the previously loaded list remains visible (not cleared) with a
  non-blocking `AppFailure`-mapped error indication, so a transient failure
  doesn't wipe out data I could already see
  Evidence: Fixed 2026-11-21: a failed refresh (not offline) replaced the loaded list with the error screen; `home_screen.dart` now keeps the list and shows a "Refresh failed" toast with the reason. Test `test/presentation/features/home/home_tree_states_test.dart` "a failed refresh keeps the list and says why"; offline, the saved listing stays with a banner (`test/presentation/features/home/offline_tree_test.dart` "offline, the last saved listing is served and flagged (US-JX-20)").
- [x] Scenario: Refresh while offline
  Given there is no network connectivity
  Then the refresh clearly indicates a connectivity failure rather than
  spinning indefinitely
  Evidence: `test/presentation/features/home/offline_tree_test.dart` "the job tree fails at once offline instead of retrying", "Home shows the offline banner".

**Security & Privacy Notes**
- None specific.

**UI / Design Notes**
- Standard pull-to-refresh indicator, tinted with the active accent color
  per US-DESIGN-02.

**Non-Functional Notes**
- NFR-TEST-01

---

### US-TREE-05 — Understand empty and error states clearly

**Priority:** Should
**Source:** tasks/phase-4-jenkins-job-tree.md (P4-11)
**Dependencies:** US-TREE-01

As a user encountering a problem while browsing jobs
I want a clear explanation of what went wrong and what I can do about it
So that I'm not left staring at a blank or broken-looking screen

**Acceptance Criteria**
- [x] Scenario: Connection lost mid-browse
  Given I lose connectivity while drilling through folders
  Then the current screen shows a clear inline connectivity error with a
  retry action, without discarding my current folder position
  Evidence: `test/presentation/features/home/offline_tree_test.dart` "recheck flags an outage under a live list, and clears it on return", "Home shows the offline banner"; inline error with Retry inside a folder, position kept: `test/presentation/features/home/home_tree_states_test.dart` "a failed load shows why with Retry, and Retry reloads the same folder" (2026-11-21).
- [x] Scenario: Distinguishing "no jobs" from "error"
  Given a folder genuinely has zero jobs vs. a folder whose fetch failed
  Then these two states use visibly different copy/iconography — never the
  same generic "nothing here" treatment
  Evidence: Fixed 2026-11-21: tests added: `test/presentation/features/home/home_tree_states_test.dart` "an empty server says "No jobs found", not an error" and "a failed load shows why with Retry…" (the error has no empty-state icon or copy).
- [x] Scenario: Retry preserves context
  Given I tap retry from an error state
  Then it re-fetches the same folder I was viewing, not the root
  Evidence: Fixed 2026-11-21: test added: `test/presentation/features/home/home_tree_states_test.dart` "a failed load shows why with Retry, and Retry reloads the same folder".

**Security & Privacy Notes**
- Error messages surface `AppFailure`-mapped copy only — never a raw
  exception message or stack trace that might include the Jenkins URL's
  internal host details beyond what the user already knows.

**UI / Design Notes**
- Error/empty states rendered as centered content within a glass card,
  consistent with the shared "connection-error view" widget referenced in
  `docs/architecture.md`.

**Non-Functional Notes**
- NFR-SEC-04, NFR-TEST-02
