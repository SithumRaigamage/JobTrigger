# Phase 4 — Jenkins Job Tree

Goal: browse the active server's full job/folder tree, navigate folders,
and search across it.

- [x] P4-01 `data/models/jenkins/jenkins_job_dto.dart` and related DTOs
      (`JenkinsServerInfoDto`, `BuildSummaryDto`, `HealthReportDto`,
      `JobPropertyDto`) per `docs/data-models.md`; run codegen and confirm
      recursive `jobs` parsing works against a real multi-folder fixture.
      **Found and fixed a real bug in the docs' own sample**: the literal
      `docs/data-models.md` snippet declares `jobs` as
      `@Default([]) List<JenkinsJobDto>?` — combining a default with a
      nullable field means json_serializable fills in `[]` for a *missing*
      key, not just a `null` one. Since `isFolder` (ported from
      `JenkinsServerInfo.swift`) is `jobs != null`, that combination would
      silently turn every leaf job into an empty folder. Verified against a
      real recursive tree fetch from the live Jenkins instance (saved as
      `test/fixtures/jenkins_tree_fixture.json`) that Jenkins omits the
      `jobs` key entirely for leaf jobs and always includes it (possibly
      `[]`) for folders — `jobs` is left plain-nullable, no default.
      `BuildSummaryDto` unified into the same `JenkinsBuildDto` used for
      `builds[]` (the docs reference an undefined `BuildSummaryDto` type;
      the old Swift app's two structs — `BuildSummary`/`JenkinsBuild` — are
      the same shape, so one DTO covers both). Also added
      `ParameterDefinitionDto` (a structural dependency of `JobPropertyDto`,
      not scope creep — needed for it to compile, and Phase 5 needs it too).
- [x] P4-02 `domain/jenkins/jenkins_job.dart` entity + DTO→entity mapping.
      Also added domain `JenkinsBuild`/`HealthReport`/`JobProperty`/
      `ParameterDefinition` types (architecture.md's domain-purity rule —
      the domain entity shouldn't expose DTO types on its public fields)
      and `toDomain()` extensions on each of their DTOs.
- [x] P4-03 `JenkinsRepository.fetchJobTree()` — GET `{baseURL}/api/json`
      with the recursive `tree` query param (depth-limited to 6 per
      `docs/api-reference.md`). `buildJobTreeQuery()` ported exactly from
      `JenkinsAPIService.fetchJobs`'s field-nesting construction (Swift).
- [x] P4-04 URL rewriting: implement and unit-test rewriting every job's
      `url` to the active server's scheme/host/port (fixture with mismatched
      internal/external hosts — see `docs/architecture.md §5`).
      `rewriteJobTreeUrls()` is a standalone pure function
      (`data/repositories/jenkins_url_rewriter.dart`), not inlined in the
      repository, so it's directly unit-testable. Didn't need a synthetic
      mismatched-host fixture — the real fixture from P4-01 already has one
      (Jenkins' internal root URL is an ngrok tunnel; reached in practice via
      `http://localhost:8080`), which the test uses directly.
- [x] P4-05 `JobTreeNotifier` (`AsyncNotifier<List<JenkinsJob>>`) +
      pull-to-refresh wired to `refresh()`.
- [x] P4-06 `HomeScreen` — job list tile (name, color/status indicator,
      folder chevron for nested jobs), tap folder → drill in, tap job → job detail.
      Ported from `HomeView.swift`. Deliberately skipped the swipe-to-
      trigger-build action and confirm-trigger alert (Phase 5 scope, not
      this phase's task list) and the backend-connectivity check (not in
      any phase task list). Tapping a leaf job pushes `AppRoutes.jobDetail`
      with the `JenkinsJob` via go_router's `extra` — the destination
      screen itself is Phase 5's job.
- [x] P4-07 `FolderBreadcrumbNotifier` + breadcrumb UI for folder navigation
      history; back button/gesture pops one level. Ported from
      `HomeViewModel.navigateInto`/`navigateBack` (Swift), simplified to a
      single `List<JenkinsJob>` breadcrumb trail per
      `docs/state-management.md`'s typing, rather than the Swift version's
      separate parallel stacks of folder names + cached job lists.
- [x] P4-08 Flatten-tree helper (`domain/jenkins/flatten_jobs.dart`, pure
      function, unit-tested) used by search. Confirmed against
      `HomeViewModel.flattenJobs` (Swift) that folders themselves are
      included in the flattened output, not just leaf jobs — a folder whose
      name matches the search query is a valid result.
- [x] P4-09 `JobSearchNotifier` + `filteredJobsProvider` — live filter by
      job name across the *entire* tree (not just the current folder),
      matching original behavior. Ported `HomeViewModel.displayedJobs`'s
      exact logic: empty query shows the current breadcrumb folder's
      contents; non-empty query flattens and filters the whole root tree
      regardless of breadcrumb position.
- [x] P4-10 Job status color mapping — Jenkins' `color` field (`blue`, `red`,
      `yellow`, `anime` for "building", `notbuilt`, `disabled`, etc.) →
      `AppColors` status indicator; confirm the "building" (`*_anime`) suffix
      is handled distinctly from the static colors. Ported from
      `StatusIndicator.swift` exactly, including the "blue means success"
      remap (blue→green) and the pulsing building animation. Distinct from
      Phase 1's `AppColors.forBuildResult` (that maps a build's `result`
      string; this maps the job tree's `color` field — two different old-app
      color schemes that happen to look similar).
- [x] P4-11 Empty/error states: no jobs, connection error mid-browse
      (server went unreachable after initial load). `ConnectionErrorView`
      (Phase 1) for the fetch-failed case with retry;
      "No jobs found"/"No results for "query"" empty states matching the
      old app's copy exactly.
- [x] P4-12 Unit tests: recursive parsing at depth, URL rewriting, flatten +
      search filter logic. Written alongside each piece rather than as a
      separate pass: `jenkins_job_dto_test.dart` (recursive parsing, against
      the real fixture), `jenkins_url_rewriter_test.dart` (rewriting, also
      against the real fixture's genuinely mismatched hosts),
      `flatten_jobs_test.dart`, `filtered_jobs_provider_test.dart` (search).
      43 tests passing total, `flutter analyze`/`dart format` clean.
- [x] P4-13 Manual test against a real server with nested folders (3+
      levels) and one with a flat job list, to catch tree-depth assumptions.
      Used the same live Jenkins instance from P3-11 (still running) —
      its "Projects" folder is 4 levels deep and "TEST" is a flat
      single-job folder, covering both cases without needing a second
      server. Ran the real `JenkinsRepositoryImpl.fetchJobTree()` (not
      mocked) in a throwaway `flutter test` script, deleted after use:
      confirmed the flat case doesn't over-nest, the 4-level case parses
      completely, and every URL at every depth is correctly rewritten to
      `localhost:8080`.
