# Phase 5 — Build Execution, Log Streaming & History

Goal: the highest-complexity phase — trigger builds (with/without
parameters), watch live status, stream logs, cancel builds, and view
history. Budget the most time here.

## Job detail & triggering

- [ ] P5-01 `data/models/jenkins/parameter_definition_dto.dart` with the
      polymorphic `defaultValue` handling from `docs/data-models.md`.
- [ ] P5-02 `JenkinsRepository.fetchJobDetail(jobUrl)` — GET with the
      `detailsTree` query (params, health, lastBuild, builds).
- [ ] P5-03 `JobDetailNotifier` + `JobDetailScreen` — shows description,
      health report, last build status, parameter form (if any).
- [ ] P5-04 `ParameterForm` widget — switches on `type` per parameter:
      `StringParameterDefinition` → text field, `ChoiceParameterDefinition`
      → dropdown from `choices`, `BooleanParameterDefinition` → switch;
      all values stringified before submission.
- [ ] P5-05 `TriggerBuildNotifier` — POST `build` (no params) or
      `buildWithParameters` (form-urlencoded body) depending on whether the
      job has parameters; on success, trigger a job-detail refresh and show
      a success toast.
- [ ] P5-06 `BuildStatusPollingNotifier` — `Timer.periodic(5s)` while
      `lastBuild.building == true`, invalidating `JobDetailNotifier`;
      cancelled in `ref.onDispose`. **Write the dispose test** — this is the
      #1 place for a leak per the original migration notes.
- [ ] P5-07 Progress bar using `domain/jenkins/build_progress.dart`'s pure
      ratio function (unit test the math independent of any timer/widget).
- [ ] P5-08 `CancelBuildNotifier` — POST `{buildNumber}/stop`, optimistic
      local flip to `ABORTED`, reconciled by the next poll.

## Log streaming

- [ ] P5-09 `JenkinsRepository.streamBuildLog(buildUrl, {start})` — GET
      `logText/progressiveText?start=`, returns text chunk + next offset +
      "more data" flag from `X-Text-Size`/`X-More-Data` headers.
- [ ] P5-10 `BuildLogNotifier` — accumulates text, advances offset, stops
      when `X-More-Data` is false; timer cancelled in `ref.onDispose`.
- [ ] P5-11 `BuildLogScreen` / `ConsoleLogViewer` — `ListView.builder` (not
      a single giant `Text` widget) for performance at thousands of lines;
      auto-scroll-to-bottom with a manual override once the user scrolls up.
- [ ] P5-12 Copy/share log action (`share_plus` + `Clipboard`).
- [ ] P5-13 Perf test: load a multi-thousand-line log fixture, confirm no
      jank scrolling on a mid-range Android device, not just iOS simulator.

## History

- [ ] P5-14 `domain/jenkins/history_entry.dart` + traversal function that
      builds the top-50 cross-job timeline from the already-fetched job
      tree (reuse `JobTreeNotifier`'s data — don't re-fetch from scratch).
- [ ] P5-15 `GlobalHistoryNotifier` + `GlobalHistoryScreen`.
- [ ] P5-16 `JobHistoryNotifier` + per-job history view (reuses the same
      `HistoryTile` widget as global history).

## Cross-cutting

- [ ] P5-17 Unit tests: parameter form serialization for each type, polling
      start/stop lifecycle, log offset accumulation logic.
- [ ] P5-18 Manual test: trigger a real build end-to-end (params and no
      params), watch it go building → success/failure, cancel one mid-run,
      confirm log streaming keeps up and stops cleanly at completion.
