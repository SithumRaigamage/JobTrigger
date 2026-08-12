# Phase 4 — Jenkins Job Tree

Goal: browse the active server's full job/folder tree, navigate folders,
and search across it.

- [ ] P4-01 `data/models/jenkins/jenkins_job_dto.dart` and related DTOs
      (`JenkinsServerInfoDto`, `BuildSummaryDto`, `HealthReportDto`,
      `JobPropertyDto`) per `docs/data-models.md`; run codegen and confirm
      recursive `jobs` parsing works against a real multi-folder fixture.
- [ ] P4-02 `domain/jenkins/jenkins_job.dart` entity + DTO→entity mapping.
- [ ] P4-03 `JenkinsRepository.fetchJobTree()` — GET `{baseURL}/api/json`
      with the recursive `tree` query param (depth-limited to 6 per
      `docs/api-reference.md`).
- [ ] P4-04 URL rewriting: implement and unit-test rewriting every job's
      `url` to the active server's scheme/host/port (fixture with mismatched
      internal/external hosts — see `docs/architecture.md §5`).
- [ ] P4-05 `JobTreeNotifier` (`AsyncNotifier<List<JenkinsJob>>`) +
      pull-to-refresh wired to `refresh()`.
- [ ] P4-06 `HomeScreen` — job list tile (name, color/status indicator,
      folder chevron for nested jobs), tap folder → drill in, tap job → job detail.
- [ ] P4-07 `FolderBreadcrumbNotifier` + breadcrumb UI for folder navigation
      history; back button/gesture pops one level.
- [ ] P4-08 Flatten-tree helper (`domain/jenkins/flatten_jobs.dart`, pure
      function, unit-tested) used by search.
- [ ] P4-09 `JobSearchNotifier` + `filteredJobsProvider` — live filter by
      job name across the *entire* tree (not just the current folder),
      matching original behavior.
- [ ] P4-10 Job status color mapping — Jenkins' `color` field (`blue`, `red`,
      `yellow`, `anime` for "building", `notbuilt`, `disabled`, etc.) →
      `AppColors` status indicator; confirm the "building" (`*_anime`) suffix
      is handled distinctly from the static colors.
- [ ] P4-11 Empty/error states: no jobs, connection error mid-browse
      (server went unreachable after initial load).
- [ ] P4-12 Unit tests: recursive parsing at depth, URL rewriting, flatten +
      search filter logic.
- [ ] P4-13 Manual test against a real server with nested folders (3+
      levels) and one with a flat job list, to catch tree-depth assumptions.
