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
- Scenario: Tree loads successfully
  Given an active server with jobs exists
  When I open the home screen
  Then the recursive tree fetch runs (depth-limited to 6 levels), each job
  shows its name and a status indicator derived from Jenkins' `color` field
  (success/failure/unstable/building/disabled/no-builds-yet), and folders
  are visually distinguished from leaf jobs
- Scenario: Deeply nested folder truncation
  Given a folder structure exceeds the 6-level recursion depth
  Then deeper levels are not fetched, and the deepest visible folder
  indicates there's more nesting (e.g. an affordance to drill further
  rather than silently truncating with no signal)
- Scenario: Empty server
  Given the active server has no jobs at all
  Then an empty state explains this clearly, distinct from an error state
- Scenario: Load failure
  Given the request fails
  Then the failure maps to the correct `AppFailure` (per-server
  `AuthFailure` for 401/403, `NetworkFailure` for unreachable,
  `ServerFailure`/`UnknownFailure` otherwise) with a retry action, per
  US-CRED-05's per-server-auth-failure handling

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
- Scenario: Drill into a folder
  Given I tap a folder row
  When the folder opens
  Then I see only that folder's direct children, and a breadcrumb trail
  shows the path from the root down to the current folder
- Scenario: Breadcrumb jump
  Given I am several folders deep
  When I tap an earlier breadcrumb segment
  Then I jump directly to that level, not just one level back
- Scenario: Android system back gesture
  Given I am inside a folder on Android
  When I use the system back gesture
  Then it navigates up one folder level (consistent with the breadcrumb),
  not out of the app entirely, until I'm back at the root
- Scenario: Folder becomes empty/removed mid-browse
  Given a folder I'm viewing had its jobs removed or renamed on the Jenkins
  server since I opened it
  When I pull to refresh at that level
  Then it reflects the new (possibly empty) state without crashing or
  showing stale entries indefinitely

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
- Scenario: Live search
  Given the full tree has already been fetched
  When I type into the search field
  Then results filter live (client-side, over the already-flattened tree —
  no new network call per keystroke) across all folders, each result
  showing its folder path for context
- Scenario: No matches
  Given my search term matches nothing
  Then an explicit "no jobs match" state is shown, not an empty list
  indistinguishable from a loading state
- Scenario: Clearing search
  Given I clear the search field
  Then I return to my previous folder view (not forced back to root)
- Scenario: Selecting a search result
  Given I tap a result from a different folder than the one I'm in
  Then I navigate to that job's detail directly, and the breadcrumb updates
  to reflect the result's actual folder path

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
- Scenario: Successful refresh
  Given I pull down on the job list
  Then a refresh indicator shows, the tree is refetched from the current
  folder level, and statuses update once the response returns
- Scenario: Refresh failure
  Given the refresh request fails
  Then the previously loaded list remains visible (not cleared) with a
  non-blocking `AppFailure`-mapped error indication, so a transient failure
  doesn't wipe out data I could already see
- Scenario: Refresh while offline
  Given there is no network connectivity
  Then the refresh clearly indicates a connectivity failure rather than
  spinning indefinitely

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
- Scenario: Connection lost mid-browse
  Given I lose connectivity while drilling through folders
  Then the current screen shows a clear inline connectivity error with a
  retry action, without discarding my current folder position
- Scenario: Distinguishing "no jobs" from "error"
  Given a folder genuinely has zero jobs vs. a folder whose fetch failed
  Then these two states use visibly different copy/iconography — never the
  same generic "nothing here" treatment
- Scenario: Retry preserves context
  Given I tap retry from an error state
  Then it re-fetches the same folder I was viewing, not the root

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
