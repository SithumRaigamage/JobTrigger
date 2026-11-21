# Epic: HIST — Build History

Built by traversing the already-fetched job tree data (no separate Jenkins
endpoint) — see `docs/architecture.md`. Global history is the top 50 most
recent builds across all jobs; per-job history scopes the same shape to one
job's `builds[]`.

---

### US-HIST-01 — View global build history across all jobs

**Priority:** Must
**Source:** tasks/phase-5-build-execution-logs-history.md (P5-14, P5-15)
**Dependencies:** US-TREE-01

As a user
I want a single timeline of the most recent builds across every job on my
active server
So that I can see at a glance what's been happening without opening each
job individually

**Acceptance Criteria**
- [x] Scenario: History renders from existing tree data
  Given the job tree has already been fetched
  Then the history screen derives its top-50 most-recent-builds timeline
  from that data (no duplicate network fetch), each entry showing job name,
  build number, result/status, and relative time
  Evidence: `test/presentation/features/history/global_history_notifier_test.dart` "derives the cross-job timeline from the job tree, newest first" (no fetch of its own); 50 cap: `test/domain/jenkins/history_entry_test.dart` "caps at the given limit"; each row shows job, number, result and duration under TODAY/YESTERDAY day sections (`test/presentation/features/history/global_history_screen_test.dart` "builds are grouped under the day they started").
- [x] Scenario: Tapping a history entry
  Given I tap an entry
  Then I navigate to that build's detail/log, consistent with reaching it
  via the job tree directly
  Evidence: Fixed 2026-11-21: test added: `test/presentation/features/history/history_navigation_test.dart` "a global history entry opens that build" (the same build detail as from the tree).
- [x] Scenario: Fewer than 50 builds exist
  Given the active server has fewer than 50 total recent builds
  Then the list simply shows what's available, with no placeholder/padding
  entries
  Evidence: `test/domain/jenkins/history_entry_test.dart` (only real builds, newest first); `test/presentation/features/history/global_history_notifier_test.dart` "a job tree with no builds yields an empty timeline".
- [x] Scenario: Underlying tree fetch failed
  Given the job tree itself failed to load
  Then the history screen reflects the same `AppFailure`-mapped error
  (since it depends on that data) rather than showing a misleadingly empty
  history
  Evidence: `test/presentation/features/history/global_history_notifier_test.dart` "a job tree fetch failure surfaces as an AsyncError with the AppFailure"; Fixed 2026-11-21: test added: `test/presentation/features/history/history_navigation_test.dart` "a failed job tree shows the error, not an empty history".

**Security & Privacy Notes**
- None beyond the existing per-server auth handling already covering the
  underlying tree fetch.

**UI / Design Notes**
- Timeline entries in a glass list (US-DESIGN-01), status per US-DESIGN-05;
  flat/translucent rows per US-DESIGN-04 to keep scrolling smooth.

**Non-Functional Notes**
- NFR-TEST-02

---

### US-HIST-02 — View a single job's build history

**Priority:** Must
**Source:** tasks/phase-5-build-execution-logs-history.md (P5-14, P5-16)
**Dependencies:** US-JOB-01

As a user
I want to see the recent build history for one specific job
So that I can spot patterns (e.g. flaky failures) without the noise of
every other job's builds

**Acceptance Criteria**
- [x] Scenario: Per-job history renders
  Given I'm viewing a job's detail screen
  Then its recent builds (`builds[]`) list shows result/status, build
  number, and relative time, most recent first
  Evidence: `test/presentation/features/history/job_history_notifier_test.dart` "fetches and exposes the build history for the given job on success"; `test/presentation/features/history/job_history_pages_notifier_test.dart` "loads page after page…" (newest first) and "filter chips narrow the list"; each row shows number, result and "started <relative time>" (`history_tile.dart`).
- [x] Scenario: Tapping a past build
  Given I tap an older (non-latest) build in the list
  Then I can view that specific build's log (US-LOG-01), not only the
  latest build's
  Evidence: Fixed 2026-11-21: test added: `test/presentation/features/history/history_navigation_test.dart` "a job with one build lists it and opens it" (opens that build's detail, which has its log).
- [x] Scenario: Job with a single build
  Given the job has exactly one build in its history
  Then the list still renders correctly (no off-by-one or "history" section
  that looks broken for a list of one)
  Evidence: Fixed 2026-11-21: the footer read "End of history · 1 builds"; now "1 build". Test `test/presentation/features/history/history_navigation_test.dart` "a job with one build lists it and opens it".

**Security & Privacy Notes**
- None specific.

**UI / Design Notes**
- Reuses the same glass list-row pattern as US-HIST-01 for visual
  consistency between global and per-job history.

**Non-Functional Notes**
- NFR-TEST-02
