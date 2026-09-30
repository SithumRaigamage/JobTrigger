# Phase 11 — Jenkins Extended Capabilities (Epic JX)

Goal: implement `docs/user-stories/jenkins/16-jenkins-extended.md`, which was
promoted on 2026-09-29 from the Jenkins coverage review. The product owner
asked for everything in that review to be finished, in this order:

1. **Part B — Verification** of shipped-but-unproven work
2. **Part C — Depth gaps** in existing features (US-JX-01 … 09)
3. **Part D — New capabilities** (US-JX-10 … 23)

Several audit findings (`docs/audit/2026-09-29-workspace-audit.md`) live in
the same code as these stories, so they're fixed here rather than twice.
Each task names the `AUD-##` ids it closes.

## Rules for every task in this phase

- **Plan and design first, then approval, then code, then review**, per
  `CLAUDE.md` §9. One task at a time.
- **Definition of done:**
  1. The approved plan is implemented within the layers (`CLAUDE.md` §4).
  2. Every new or changed repository method returns `Result<T, AppFailure>`
     through the shared guard (P12-04), and never throws.
  3. Unit tests for the repository, DTO, and notifier, plus widget tests for
     new interactive UI (`NFR-TEST-01`).
  4. `dart format`, `flutter analyze` (clean), and `flutter test` (green).
  5. Jenkins-facing behaviour is verified against the fixture Jenkins
     (P11-01, `NFR-TEST-02`), or explicitly marked **UNVERIFIED** with the
     reason, the way P7-07 was.
  6. Docs are updated in the same change: the `api-reference.md` row status,
     plus `data-models.md`, `state-management.md`, and `architecture.md`
     where touched. Any new dependency is added to `CLAUDE.md` §3 with a
     rationale line.
  7. A Conventional Commit referencing the task, e.g.
     `feat(jenkins): mask password parameters [P11-04]`.
- **New dependencies** (`file_picker`, `flutter_local_notifications`,
  `workmanager`, `local_auth`, `home_widget`, and `path_provider` as a
  direct dependency) each need explicit approval at their task's plan step.
  They were listed for approval up front with the phase plan; a "no" moves
  the story to `backlog.md` rather than substituting another package.

## Part B — Verification

- [x] P11-01 **Local Jenkins fixture.** Add an opt-in
      `docker-compose.jenkins.yml` (Jenkins LTS, JDK 21) seeded with
      Configuration-as-Code and Job DSL. Seed an admin user and API token,
      CSRF on, plugins `workflow-aggregator`, `pipeline-stage-view`,
      `pipeline-rest-api`, `junit`, `timestamper`, `ansicolor`,
      `workflow-multibranch`, `cloudbees-folder`, `parameterized-trigger`,
      and `job-dsl`. Seed jobs covering every scenario in this epic:
      - nested folders 7 levels deep
      - a freestyle job with every parameter type (string, text, boolean,
        choice, password, file, run, credentials)
      - a pipeline with stages, parallel branches, and a failing step
      - input-step pipelines, with and without parameters
      - a 50k-line ANSI-colored log job
      - a JUnit report with failures and regressions
      - large-artifact and many-artifact jobs
      - an upstream → downstream chain
      - a multibranch project over a seeded local git repo with branches, a
        tag, and a `PR-` branch
      - a disabled job and a second agent node
      Document it in `docs/integration-testing.md` ("Fixture Jenkins"). No
      credentials committed: the admin password and token are generated on
      first boot and printed once. **Needs:** the Docker daemon running
      locally.
      **Done 2026-09-29:** `tools/jenkins-fixture/`, pinned to Jenkins
      2.568.3 LTS, documented in `docs/integration-testing.md`. Deviations
      from the plan above:
      - The compose file lives at `tools/jenkins-fixture/docker-compose.yml`.
      - Pipelines are Jenkinsfiles in the seeded git repo (`pipelines/`),
        not inline in `casc.yaml`, to avoid three layers of escaping (YAML,
        CasC substitution, Groovy).
      - Seeding needs no extra plugins beyond the list. `parameterized-trigger`
        was dropped because core's `BuildTrigger` covers downstream links.
      - PR branches can't be simulated with a plain git source (they need a
        GitHub or GitLab branch source), so the `change-requests` grouping
        in US-JX-03 stays unit-tested only.

      Verified by `test/fixture/jenkins_smoke_fixture_test.dart`:
      - tree fetch with URL rewriting from `jenkins.internal:8080`
      - a real trigger with the CSRF crumb and session cookie
      - `viewer` getting `AuthFailure`

      Real payloads confirmed: multibranch views `default`/`tags`, branch
      `name` `feature%2Flogin` with `displayName` `feature/login`, and all
      8 parameter `type` strings.
- [x] P11-02 **Verify US-PIPE-05 (input-step approval)** end-to-end on the
      fixture: detection via `wfapi/pendingInputActions`, and each of
      `proceedEmpty`, `submit` (with parameters, including a password
      parameter), and `abort`. Record the real response shapes as test
      fixtures, fix any mismatch, and remove the **UNVERIFIED** notes from
      `pending_input.dart`, `jenkins_repository.dart`, and P7-07 only if
      everything passes.
      **Done 2026-09-29.** `test/fixture/input_step_fixture_test.dart` runs 7
      real-server tests. Found and fixed three bugs:
      1. **Parameterized approval never worked.** Plain `name=value` fields
         get a 400. The fix POSTs `input/{id}/proceed` with a Stapler
         `json` field. That route was chosen over the advertised
         `wfapi/inputSubmit` because it gives the same 400/404 semantics as
         `proceedEmpty` and `abort`, where `wfapi` returns a bare 500 on
         permission denial.
      2. **Input parameters use a different wire shape**
         (`definition.{defaultVal, choices}`), so choice dropdowns in the
         banner were empty. A new `PendingInputParameterDto` handles it.
      3. **Permission denial is a 400 HTML page**, not a 403. It's now
         mapped to `AuthFailure` via `guardRequest`'s `recover`.
      The real payload is recorded at
      `test/fixtures/jenkins_pending_input_params.json`, and the unit tests
      were rewritten against it. The UNVERIFIED notes were removed.
- [ ] P11-03 **P5-13 on-device log performance.** Blocked on a physical
      Android device or emulator (none in this environment). Re-run after
      P11-11 lands, since that task removes the O(n²) cause (AUD-12). Stays
      tracked in `release-checklist.md`.

## Part C — Depth gaps in existing features

- [x] P11-04 **US-JX-01 password parameters and safe triggering.** Mask
      password parameters with no pre-fill (AUD-27). Lift parameter values
      out of `ParameterForm` state into a `ParameterValuesNotifier` family
      keyed by job URL, so edits survive scrolling (AUD-18). Add a
      confirmation sheet before trigger (with a parameter summary, passwords
      shown as `••••`) and before cancel, meeting the Must criteria of
      US-JOB-02/03/05 (AUD-08). Exclude password values from replay.
      **Done 2026-09-29.** Summary:
      - **Domain:** pure rules in `domain/jenkins/parameter_values.dart`
        (initial, effective, and trigger values, plus the summary), and
        `JenkinsJob.parameterDefinitions`.
      - **State:** `ParameterEditsNotifier` stores only edits, so poll
        refreshes and scrolling can't reset them.
      - **UI:** `ParameterForm` is now stateless. There's a shared
        `showConfirmationDialog` for trigger, cancel, and input steps.
        Values are read at tap time, never captured at build.
      - **Real-server findings:**
        1. Jenkins never returns password defaults or recorded values.
        2. Sending a blank password as `''` **overwrote the stored secret**
           (proved on the fixture, where the logged length went from 22 to
           0). Blank secrets are now omitted.
        3. A duplicate parameterized trigger returns 303. That's a success,
           and it's now handled (AUD-37).
        4. An empty Run parameter returns 500 (AUD-38, handed to P11-06).
      - **Fixture job fix:** `params-all` uses `#!/bin/sh -e`, since
        Jenkins' default `sh -xe` trace echoed the secret.
      - **Tests:** 24 new unit and widget tests, plus 4 fixture tests.
- [x] P11-05 **Tree foundations.** Add `_class`, `displayName`, and
      `buildable` to the job DTO. Replace the depth-limited whole-tree fetch
      with root plus lazy per-folder loading and a per-folder cache
      (AUD-19, AUD-20). Key the breadcrumb by folder URL and resolve it
      against current data. Reset on active-server change (AUD-10).
      Debounce search at 250 ms. Search runs over an index built from loaded
      folders plus a background full crawl, bounded by `NFR-PERF-02`.
      Global history (P5-14) is rebuilt on the new source.
      **Done 2026-09-30.**
      - **Browsing:** `fetchFolder` plus `FolderContentsNotifier` for lazy,
        unlimited-depth browsing.
      - **Cache:** `visibleJobsProvider` keeps the breadcrumb path cached
        with no timers. A timed cache was tried first, and dropped because
        a stray timer outlived its listeners.
      - **Breadcrumb:** holds `FolderRef`s and resets on server switch.
      - **Model and crawl:** `JenkinsJob` gains `jobClass`, `displayName`,
        `buildable`, `label`, and `copyWith`. The crawl is fixed at 6 levels.
        `label` is used in every job-name display site.
      - **Tests:** a shared `test/support/fake_jenkins_repository.dart`
        base; 18 fakes now `extends` it.
      - **Deviations:**
        - **No search debounce:** once the crawl is cached, filtering is an
          in-memory scan, and a debounce would only add lag.
        - **No partial index:** search is the crawl itself, not an index
          built from loaded folders plus a background crawl. It's bounded
          at 6 levels (`NFR-PERF-02`), and lazy browsing covers the rest.
      - **Verified on the fixture:** lazy browsing reaches the 7-level
        `deep-job`; multibranch is a folder, with `feature%2Flogin` shown as
        `feature/login`; the crawl stops at level 6.
- [x] P11-06 **US-JX-02 all parameter types.** **Must also close
      AUD-38:** an empty Run parameter is a Jenkins 500, so Run needs a
      real picker and Trigger stays disabled until a build is chosen. Also
      decide Credentials: an empty value was accepted (201) on the fixture,
      but check that the job's own default applies when it's omitted. Text (multi-line), Run
      (build picker), Credentials (id field), File (multipart upload, 50 MB
      guard; **new dependency `file_picker`**), and unknown plugin types
      with a labelled fallback. Validation keeps Trigger disabled until the
      inputs are valid.
      **Done 2026-09-30.**
      - **Omitted when blank:** Run, Credentials, File, and Password
        (`isOmittedWhenBlank`). Verified: an omitted Run uses the latest
        build (AUD-38 fixed), and an omitted Credentials is accepted.
        Omission replaced "disable Trigger until valid".
      - **Inputs:**
        - Run: a picker of the project's recent builds via
          `jobUrlFromFullName`, falling back to free text.
        - Text: multi-line.
        - Credentials: an ID field.
        - File: `ParameterFilesNotifier` plus a `file_picker` provider,
          50 MB refused before upload, multipart `buildWithParameters`.
        - Unknown plugin types: a labelled fallback, or a dropdown when
          they declare choices.
        - Replay and input steps: file re-picked on replay; unavailable
          for input steps.
      - **Test cleanup:** 1,081 lines of redundant fake stubs removed,
        since the base class covers them.
      - **Fixture harness fixes:** tests run `--concurrency=1` (parallel
        suites read each other's builds), `params-all` cleans its uploaded
        file, and readiness ignores stale logs.
      - **Tests:** 20 new unit and widget tests, plus 5 fixture tests. The
        full fixture suite (22) passes.
- [x] P11-07 **US-JX-03 multibranch and organization folders.** Class-based
      icons, `displayName` everywhere, Branches/PRs/Tags grouping from
      `views`, "Scan now" with indexing progress and scan log, and 403 shown
      as a permission message.
      **Done 2026-09-30.**
      - **Grouping:** `BranchKind` plus `fetchBranchKinds`, from views,
        into Branches, Pull requests, and Tags sections. A flat list shows
        until the views load.
      - **Scan:** "Scan now" (with confirmation) through
        `MultibranchScanNotifier`: POST, then poll the indexing log every
        2 s (capped at 5 min), then refresh. The scan log reuses
        `BuildLogScreen`, titled via `displayName`.
      - **Icons:** multibranch and org-folder icons carry semantic labels.
      - **Permissions:** a new `PermissionFailure` for 403 and the Jenkins
        400 permission page, so 401 and 403 are no longer conflated.
      - **Real-server findings:** scan POST returns 302; there's no
        indexing JSON API; X-More-Data signals a running scan.
      - **Not verifiable locally:** PR grouping needs a hosted SCM
        (GitHub/GitLab) branch source. It's covered by unit tests only.
- [x] P11-08 **US-JX-04 stage logs and parallel branches.** Stage sheet →
      steps → step log (live while running), auto-expand of the failed step,
      and fallback to the full console on 404.
      **Done 2026-09-30.**
      - **Stage sheet:** `StageDetailSheet` with steps as expansion tiles.
        The first failed step opens with its log, and the stage's
        `error.message` is shown.
      - **Live updates:** `stageSteps` and `stepLog` providers refresh
        every 2 s only while their stage or step is running.
      - **Parallel stages:** `groupParallelStages` groups by overlapping
        time, since the API flattens branches with no parent link
        (verified). `StageNode.status` shows the worst branch, because
        Jenkins reports the parent as SUCCESS.
      - **Refactor:** stage status style moved to `stage_status_style.dart`.
      - **Tests:** 11 unit and widget tests, plus 1 fixture test.
- [x] P11-09 **US-JX-05 last success, failure, and stable links** on job
      detail. **Done 2026-09-30.** Last-success and last-failure chips
      appear in the detail tree, shown only when they differ from the last
      build, with a relative age from the new pure `relativeTime`. Tapping
      opens that build's log; the build detail screen arrives in P11-18.
      "Last stable" was dropped: on a phone it duplicates "last success"
      in nearly every job. The details-tree unit test now checks sections,
      not one exact string. Tests: 3 unit and widget, plus 1 fixture.
- [x] P11-10 **US-JX-06 history paging and filters, plus search context.**
      `allBuilds{n,m}` paging, result and "started by me" filters, folder
      path on search results, and a refreshable empty state (AUD-33).
      **Done 2026-09-30.**
      - **History paging:** `fetchJobHistory(start, count)` over
        `allBuilds`. `JobHistoryPagesNotifier` auto-loads near the end; a
        failed page keeps the loaded builds and stops paging.
      - **Filters:** `JobHistoryFilterNotifier` plus the pure
        `filterHistory` (result, and "started by me" via the cause
        `userId` matched to the server username). When a filter hides
        every loaded build, the screen offers "Load more" rather than
        looping automatically.
      - **Search (AUD-33):** search tiles show the folder path via
        `folderPathOf`, and the empty state is refreshable.
      - **UX fix found by a widget test:** "Started by me" moved first,
        since it was off-screen in the chip row.
      - **Kept as-is:** `JobHistoryNotifier` is still the Run picker's
        first-page source.
      - **Tests:** 10 unit and widget tests, plus 2 fixture tests.
- [ ] P11-11 **US-JX-07 console rewrite.** Incremental sanitize and split
      with a memory cap (AUD-12), keep the log and back off on poll errors
      (AUD-13), handle CRLF and chunk-split escapes (AUD-34), search with
      highlight and counter, jump to first error, ANSI color rendering, a
      Timestamper toggle, wrap and font-size preferences, and full-log
      download as a `.log` file.
- [ ] P11-12 **US-JX-08 test failure details:** `errorDetails`,
      `errorStackTrace`, and `age`, with regressions badged, capped at 200.
- [ ] P11-13 **US-JX-09 server-wide queue:** list, stuck flag, cancel with
      confirmation, and 5s refresh while visible.

## Part D — New capabilities

Ordered by value to effort. Items with new dependencies are grouped late so
their approvals don't block the rest.

- [ ] P11-14 **US-JX-22 API token hygiene:** a token-shape heuristic warning
      in the server form, a "Uses password" advisory in Settings, and a
      "Create a token" link.
- [ ] P11-15 **US-JX-11 pinned jobs:** per-server pins in
      `shared_preferences`, a Pinned section on Home, and stale-pin
      handling.
- [ ] P11-16 **US-JX-18 server status:** version from the `X-Jenkins`
      header, a quiet-down banner, and an outdated-version note.
- [ ] P11-17 **US-JX-13 enable or disable a job:** `buildable` badge,
      trigger disabled with a reason, and confirmation.
- [ ] P11-18 **US-JX-14 build detail screen:** keep-forever toggle and
      plain-text description editing.
- [ ] P11-19 **US-JX-15 build trends:** a pure stats function and a
      `CustomPaint` sparkline (no new dependency).
- [ ] P11-20 **US-JX-12 nodes and executors:** list, drill-down, and
      temporarily-offline toggle with a reason, with permission handling.
- [ ] P11-21 **US-JX-17 views:** view picker, view-scoped Home, and
      persisted per server.
- [ ] P11-22 **US-JX-19 deep links:** the `jobtrigger://` scheme, an
      Android share intent, iOS paste-to-open, a pure URL→route parser, and
      server matching with a confirmation to switch.
- [ ] P11-23 **US-JX-20 offline job tree:** a per-server cache in app
      documents (backup-excluded), an offline banner, POSTs disabled
      offline, and cleared on logout or server delete. **New dependency:
      `path_provider` (direct).**
- [ ] P11-24 **US-JX-10 build notifications:** a watch list, in-process
      polling, and a best-effort periodic background check, with a
      permission rationale. Notifications open job detail. **New
      dependencies: `flutter_local_notifications`, `workmanager`.**
- [ ] P11-25 **US-JX-21 biometric app lock:** lock on cold start and after a
      resume timeout, a privacy overlay in the app switcher, and optional
      re-prompts for sensitive actions. **New dependency: `local_auth`.**
- [ ] P11-26 **US-JX-23 home-screen widget:** an app-written snapshot of
      pinned jobs (no secrets), an iOS WidgetKit extension, an Android
      AppWidget, and deep-link taps. **New dependency: `home_widget`.**
- [ ] P11-27 **US-JX-16 replay with an edited script.** Verification-gated:
      prove the form contract on the fixture first. If it can't be driven
      without scraping HTML, close as won't-do and record why in the story.

## Close-out

- [ ] P11-28 Final documentation sync: `architecture.md` (lazy tree,
      background task, and widget data flow), `state-management.md` (every
      new notifier), `data-models.md` (every new DTO and entity), and the
      traceability and status notes in `docs/user-stories/README.md`. Then
      mark this phase done in `tasks/README.md`.
