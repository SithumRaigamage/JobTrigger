# Phase 7 — Pipeline & Build Insights (Epic PIPE)

Goal: implement `docs/user-stories/11-build-insights-pipeline.md`'s 9 new
Jenkins-capability stories. Unlike Phases 0–6, this isn't parity work —
nothing here is required to close the original migration; see that file's
intro and `docs/user-stories/README.md`'s PIPE note for why it's tracked
separately from the parity traceability table.

Working order below is dependency-driven, not priority-driven: shared
plumbing first, then additive read-only cards (cheap, low-risk, no new
write paths), then the two write-path/interactive stories, then the two
stories that depend on other PIPE work landing first. Each task is done
one at a time — plan/design presented and approved before its code lands,
per `CLAUDE.md` §9.

- [x] P7-00 `NFR-SEC-06` — CSRF crumb helper. Implemented entirely inside
      `buildJenkinsDio` (`core/network/jenkins_client_factory.dart`) as a
      new `_crumbInterceptor`, so `jenkins_repository_impl.dart` and every
      trigger/cancel notifier needed zero changes — the header attaches
      transparently for any POST on the shared client. Lazily
      `GET`s `/crumbIssuer/api/json` on first POST, caches the header
      name/value for the client's lifetime (rebuilt on server switch, same
      as Basic Auth); a clean 404 is cached as "no crumb issuer" so further
      POSTs stop re-fetching; any other fetch failure is left unset so the
      next POST retries rather than permanently giving up on a blip. A 403
      triggers exactly one retry with a freshly-fetched crumb, skipped if a
      404 already confirmed no crumb issuer exists (that 403 is then a real
      auth/permission failure, not a stale crumb). 6 new tests in
      `jenkins_client_factory_test.dart` (attach-on-POST, skip-on-GET,
      404-caches-unavailable, retry-then-succeed, give-up-after-one-retry)
      using a new `_ScriptedAdapter` fake — snapshots request headers into
      a fresh map per capture, since Dio mutates/reuses the same
      `RequestOptions` instance across a retry (first attempt at asserting
      on the raw `RequestOptions` list showed every earlier entry
      reflecting the *latest* mutation too). `flutter analyze` clean, full
      suite (94 tests) passing.
- [x] P7-01 `US-PIPE-02` — Build cause. Added `List<String> causes` to
      `JenkinsBuild`/`JenkinsBuildDto` (not a separate `BuildCause` type —
      Jenkins' cause data is just a flat list of description strings once
      unwrapped, no other fields worth modeling), flattened out of the
      polymorphic `actions[causes[shortDescription]]` shape via a custom
      `@JsonKey(fromJson:)` unwrapper (`_causesFromJson`), same pattern as
      `ParameterDefinitionDto`'s existing `defaultParameterValue` unwrap.
      Added to `_detailsTree` only (job detail screen), not
      `_treeFields`/`_historyTree` — home screen tiles and history lists
      don't show it, keeping the change contained. Rendered as a caption
      line under the last-build header in `_LastBuildCard`
      (`job_detail_screen.dart`), multiple causes comma-joined.
      5 new tests in `jenkins_build_dto_test.dart` (single cause, multiple
      causes across multiple action entries, absent actions, no action
      carrying causes, `toDomain()` passthrough). `flutter analyze` clean,
      full suite (99 tests) passing.
- [x] P7-02 `US-PIPE-01` — Queue status. Scoped down with the user before
      implementing: tracks only builds triggered from this app session via
      the trigger response's `Location` header (`GET {location}api/json`
      polled every 2s), not a full `GET /queue/api/json` scan — an
      already-queued build discovered on a cold job-detail load isn't
      detected, a known and documented gap, not a silent one. New
      `QueueItem`/`QueueExecutable` domain types + `QueueItemDto`;
      `triggerBuild`'s return type changed from `Result<void, AppFailure>`
      to `Result<String?, AppFailure>` (the rewritten queue-item URL, or
      `null` if Jenkins sent no `Location` header — triggering still
      succeeded either way). New `QueueStatusNotifier` (family by job URL,
      imperative `track()` entry point, same timer/`ref.onDispose` shape as
      `BuildStatusPollingNotifier`) started from `TriggerBuildNotifier` on
      success; stops and invalidates `JobDetailNotifier` once the item
      becomes an executable build, so `US-JOB-04`'s existing 5s poll picks
      up from there. New `_QueuedCard` in `job_detail_screen.dart`, shown
      between trigger and the existing building state.

      Exposed `rewriteUrl()` (a new public function) from
      `jenkins_url_rewriter.dart` for the `Location` header, reusing the
      existing scheme/host/port substitution instead of duplicating it.

      **Found and fixed two real bugs along the way, unrelated to this
      story's own scope but surfaced by it**: `jenkins_url_rewriter.dart`'s
      `_rewriteBuild` and `job_detail_notifier.dart`'s
      `applyOptimisticCancel` both reconstruct `JenkinsBuild` field-by-field
      rather than copying the source build, so P7-01's new `causes` field
      was being silently dropped on every real job-detail fetch and every
      optimistic-cancel UI update. Neither was caught by P7-01's own tests
      since none exercised the rewrite/optimistic-cancel path. Fixed
      separately (own commit) before this task could repeat the same
      mistake for `QueueItem`/`QueueExecutable`, plus regression tests.

      Interface change rippled through 5 fake `JenkinsRepository`
      implementations across the test suite (mechanical: return-type
      update + a `fetchQueueItem` override throwing `UnimplementedError`)
      and `jenkins_repository_impl_trigger_test.dart` (2 new tests: returns
      the rewritten queue-item URL from `Location`, returns `null` when
      absent). New `queue_item_dto_test.dart` (3 tests: queued/executable/
      cancelled shapes) and `queue_status_notifier_test.dart` (3 tests:
      polls-then-refreshes, cancelled-clears-without-refresh, fetch-failure
      clears quietly) — the polling test needed two separate
      `container.listen(...)` keep-alives (`jobDetailNotifierProvider` and
      `queueStatusNotifierProvider` itself, both autoDispose) to actually
      observe the second poll/invalidate, matching the same reasoning
      `build_status_polling_notifier_test.dart` already relies on.
      `flutter analyze` clean, full suite (108 tests) passing.
- [x] P7-03 `US-PIPE-03` — SCM changelog. Added `List<ScmChange> changes`
      to `JenkinsBuild`/`JenkinsBuildDto`, same shape as P7-01's `causes`:
      a plain domain type (`ScmChange { author, message }`, no freezed —
      matches `QueueItem`/`QueueExecutable`'s style), a custom
      `@JsonKey(fromJson:)` unwrapper (`_changesFromJson`) for Jenkins'
      nested `changeSet: {items: [{msg, author: {fullName}}]}` shape, and
      `@JsonKey(includeToJson: false)` since `ScmChange` has no `toJson`
      and this DTO is response-only (never re-encoded). Added to
      `_detailsTree` only. Rendered via a new `_ChangesList` (a small
      `StatefulWidget` — needs local expand/collapse state, unlike the
      other read-only additions so far), collapsed to 3 entries with a
      "Show N more" toggle.

      **Closed off the P7-01/P7-02 dropped-field bug class properly**
      instead of risking a third instance: added `JenkinsBuild.copyWith()`
      and refactored both `_rewriteBuild` (`jenkins_url_rewriter.dart`) and
      `applyOptimisticCancel` (`job_detail_notifier.dart`) to use it instead
      of reconstructing the object field-by-field — any future field
      addition now carries through both call sites automatically. New
      `jenkins_build_test.dart` covers `copyWith` directly (preserves
      unspecified fields including `causes`/`changes`, overrides only the
      given ones); `jenkins_url_rewriter_test.dart`'s existing regression
      test extended to also assert `changes` survives the rewrite.

      7 new tests in `jenkins_build_dto_test.dart` (flatten multiple
      items, absent `changeSet`, empty `items`, a malformed item skipped
      without throwing, `toDomain()` passthrough) plus the 2 `copyWith`
      tests above. `flutter analyze` clean, full suite (115 tests)
      passing.
- [x] P7-04 `US-PIPE-06` — Test result summary. New `TestReport` domain
      type + `TestReportDto`, new `fetchTestReport(buildUrl)` repository
      method against `{buildUrl}testReport/api/json` — a genuinely separate
      Jenkins REST resource from the job-detail `tree=` query, so this
      needed its own new `TestReportNotifier` (family by build URL,
      matches `JobHistoryNotifier`'s shape) rather than folding into
      `_detailsTree` like causes/changes did. A 404 (no published test
      report) is handled in the repository as `Ok(null)`, not an `Err` —
      a normal state per the story, not a failure.

      `_JobDetailBody` changed from `StatelessWidget` to `ConsumerWidget`
      (its first need for `ref` — causes/changes/queue status all came
      from data already flowing through `job`/`queueItem` props) so it can
      watch the new provider conditionally on `job.lastBuild` existing.
      New `_TestReportChip`: compact "N passed · N failed · N skipped"
      chip, tap-through to a bottom sheet listing failing test names
      (`ClassName.testName`, FAILED or REGRESSION status) when
      `failCount > 0`. Additive/non-blocking like P7-01/03's fields — a
      fetch error here doesn't touch the rest of the screen, since the UI
      only reads `.value` (null on loading/error) rather than branching on
      the async state.

      Interface change rippled through the same 6 fake `JenkinsRepository`
      implementations as P7-02 (mechanical `fetchTestReport` override).
      9 new tests: 5 in `test_report_dto_test.dart` (counts, multi-suite
      flatten, missing-className fallback, all-defaults, `toDomain()`) +
      3 in a new `jenkins_repository_impl_test_report_test.dart` (real
      parse, 404→`Ok(null)`, other-status→`Err`). `flutter analyze` clean,
      full suite (123 tests) passing.
- [x] P7-05 `US-PIPE-07` — Build artifacts. **Scope change from the
      story's original "list + open via `url_launcher`" text**, caught
      during design before writing code: a bare external-browser link to
      `{buildUrl}artifact/{path}` would either need embedding Basic Auth
      credentials in the URL (unsafe — lands in browser history) or hit
      the browser unauthenticated (401). Implemented what the story's own
      Security & Privacy Notes actually asked for instead: fetch the bytes
      through the already-authenticated Jenkins client, write to a temp
      file, hand off via the OS share sheet (`share_plus`, already a
      dependency, same pattern as `BuildLogScreen`'s existing "Share log"
      button) — no new dependency, no `url_launcher` use here.

      `artifacts[fileName,relativePath]` is a flat, non-polymorphic array
      directly on the build resource — unlike causes/changes, no custom
      `fromJson` unwrapper needed, just a nested `BuildArtifactDto`
      (paired with `JenkinsBuildDto` in the same file, same pattern as
      `QueueItem`/`QueueExecutable`). Added to `_detailsTree`'s
      `lastBuild[...]` bracket alongside causes/changes — `JenkinsBuild
      .copyWith()` (added in P7-03) meant `_rewriteBuild` and
      `applyOptimisticCancel` needed zero changes for this new field, the
      exact payoff that refactor was for.

      New repository method `fetchArtifactBytes(buildUrl, relativePath)`
      (`GET {buildUrl}artifact/{relativePath}`, `ResponseType.bytes`,
      each path segment percent-encoded separately so `/` stays a
      separator). New family-keyed (by `relativePath`) `ArtifactDownload
      Notifier` — fetch bytes → temp file → `SharePlus.instance.share`.
      New `_ArtifactsList`/`_ArtifactRow` (the latter a `ConsumerWidget`,
      needs `ref` for its own per-artifact loading state and the download
      action) on the job-detail card.

      Interface change rippled through the same 6 fake `JenkinsRepository`
      implementations (mechanical `fetchArtifactBytes` override + a
      `dart:typed_data` import two of them were missing). 9 new tests:
      3 in `jenkins_build_dto_test.dart` (parse, absent-defaults,
      `toDomain()`), 3 new in `jenkins_repository_impl_artifact_test.dart`
      (correct URL construction, path-segment percent-encoding preserving
      `/`, non-2xx → `Err`), plus `artifacts` added to the existing
      `copyWith` test (`jenkins_build_test.dart`) — not re-added to
      `jenkins_url_rewriter_test.dart`'s own regression test, since that
      file's whole point was proving `_rewriteBuild`'s delegation to
      `copyWith` is field-agnostic; `copyWith`'s own test is where new
      fields now get covered. No test attempts to assert
      on the actual OS share-sheet invocation (a platform channel call) —
      consistent with `BuildLogScreen`'s existing "Share log" button,
      which also has no such test. `flutter analyze` clean, full suite
      (129 tests) passing.
- [x] P7-06 `US-PIPE-04` — Pipeline stage view. **Scope change from the
      story text**, caught during design: "tap a stage to jump to its
      exact log position" needs Jenkins' separate per-node log endpoint —
      a genuinely different mechanism from the progressive-text log used
      everywhere else in this app. Scoped down to "tap any stage opens the
      full console log" (reuses the existing `onViewLog`/`BuildLogScreen`
      flow), with true log-jumping flagged as a real, deliberate gap.

      New `PipelineStage` domain type + `PipelineDescribeDto`/
      `PipelineStageDto`, new `fetchPipelineStages(buildUrl)` repository
      method against `{buildUrl}wfapi/describe` — a separate Jenkins
      resource, so its own new `PipelineStagesNotifier` (family by build
      URL, same shape as `TestReportNotifier`). A 404 (not a pipeline job
      — freestyle, or no Pipeline: REST API plugin) maps to `Ok(null)`,
      same pattern as P7-04/P7-06's other additive fetches. Placed on the
      job-detail card (not literally "above the console log viewer" as
      first drafted in the story — that widget lives on a separate screen;
      corrected here to match every other PIPE addition's actual
      placement).

      New `_StageChipRow`: horizontally scrollable chips, icon+text pairs
      per stage (not color alone, per NFR-A11Y-03) via new
      `_colorForStageStatus`/`_iconForStageStatus` — Jenkins' stage
      `status` vocabulary (`FAILED`, `IN_PROGRESS`, `PAUSED_PENDING_INPUT`)
      doesn't match `AppColors.forBuildResult`'s classic-build-result
      vocabulary (`FAILURE`), so it needed its own small mapping rather
      than reusing that one.

      **Live-updating while building, per the story's explicit ask**:
      rather than a second independent timer, `BuildStatusPollingNotifier`
      (already polling every 5s for `JobDetailNotifier`) now also
      invalidates `PipelineStagesNotifier` for the current build on the
      same tick — one fewer place a timer leak could hide. New test in
      `build_status_polling_notifier_test.dart` confirms this.

      Interface change rippled through the same 6 fake `JenkinsRepository`
      implementations (mechanical `fetchPipelineStages` override + a
      `pipeline_stage.dart` import). 7 new tests: 3 in
      `pipeline_stage_dto_test.dart`, 3 in
      `jenkins_repository_impl_pipeline_stages_test.dart` (parse, 404→
      `Ok(null)`, other-status→`Err`), 1 in
      `build_status_polling_notifier_test.dart` (piggyback-invalidation).
      `flutter analyze` clean, full suite (136 tests) passing.
- [x] P7-07 `US-PIPE-05` — Input-step approval. **⚠️ UNVERIFIED against a
      real paused pipeline** — confirmed with the user before implementing
      (no live Jenkins instance with an actual paused input step is
      available in this environment, same class of gap `NFR-TEST-02`
      flags elsewhere). Implemented against the documented Pipeline: REST
      API plugin shape: `GET {buildUrl}wfapi/pendingInputActions` (returns
      the first entry as `Ok(PendingInput)`, empty array or 404 as
      `Ok(null)`) for detection, and `POST {buildUrl}input/{id}/
      proceedEmpty|submit|abort` for submission — not `wfapi/inputSubmit`
      as the original story text guessed; corrected to the actual
      documented endpoint shape while implementing. Every uncertain point
      is flagged directly in code (`pending_input.dart`'s class doc
      comment, repeated on the repository interface methods) — **must be
      confirmed against a real server before being trusted in
      production**, called out as the highest-stakes item in this epic.

      New `PendingInput` domain type, reusing the existing
      `ParameterDefinition`/`ParameterDefinitionDto` for the input step's
      requested parameters (assumption: Jenkins serializes them through
      the same class family as job-trigger parameters — also flagged,
      also unverified). New `PendingInputNotifier` (detection, family by
      build URL) and `InputSubmitNotifier` (the action, same
      loading/haptic/toast shape as `TriggerBuildNotifier`/
      `CancelBuildNotifier`), refreshing both `JobDetailNotifier` and
      itself on success. Live-updates via the same
      `BuildStatusPollingNotifier` 5s tick as P7-06's stage view (third
      thing it now invalidates).

      New `_PendingInputBanner`: highest-visibility position in the
      layout (top of the ListView, above description/health report),
      reuses `ParameterForm` when the input requests values, both
      Approve/Reject require a confirm dialog (same `showDialog<bool>`/
      `AlertDialog` pattern as `SettingsScreen`'s existing delete-server
      confirmation — the closest precedent, since trigger/cancel's own
      confirmation requirement from `US-JOB-02`/`05` was never actually
      built despite being in that story's acceptance criteria, a
      pre-existing gap from Phase 5, not introduced here).

      Interface change rippled through the same 6 fake `JenkinsRepository`
      implementations (2 new methods this time). 12 new tests: 4 in
      `pending_input_dto_test.dart`, 7 in
      `jenkins_repository_impl_pending_input_test.dart` (detection ×3,
      submission ×4 — proceed-empty, proceed-with-params, abort, failure),
      1 more in `build_status_polling_notifier_test.dart` (piggyback-
      invalidation). One test bug found and fixed along the way: the
      fake adapter claimed a JSON content-type on responses that echoed
      back a plain request-path string, which made Dio try (and fail) to
      JSON-decode it — fixed by only claiming JSON content-type when
      actually returning JSON. `flutter analyze` clean, full suite
      (148 tests) passing.
- [x] P7-08 `US-PIPE-09` — Upstream/downstream navigation. No new
      repository method — both pieces ride the existing `_detailsTree`
      fetch. Upstream: extended `actions[causes[...]]`'s tree fields to
      also request `upstreamProject,upstreamUrl` and added a second DTO
      field (`upstreamCause`) sourced from the same `actions` JSON key as
      P7-01's `causes` — kept `causes`'s already-shipped `List<String>`
      shape untouched rather than redesigning it into a richer element
      type. Two fields targeting one JSON key needed `includeToJson:
      false` on both to avoid a json_serializable `toJson` conflict
      (retroactively added to `causes`'s existing `@JsonKey` too — it
      didn't need it before since nothing else targeted `actions`).
      Downstream: `downstreamProjects[name,url]` added to `_detailsTree`'s
      top level (a job property, not a build one) — flat,
      non-polymorphic, no custom unwrapper needed, same as artifacts.

      **Extended the `copyWith` bug-prevention pattern to `JenkinsJob`**:
      this is the first PIPE field added directly to `JenkinsJob` (not
      `JenkinsBuild`), and `JobDetailNotifier.applyOptimisticCancel` was
      *still* reconstructing `JenkinsJob` field-by-field — caught and
      fixed (`downstreamProjects` added) before it could repeat the exact
      P7-01 mistake a third time, this time at the job level. Did **not**
      add a general `JenkinsJob.copyWith()` though: `jobs` has
      null-vs-empty-list folder/leaf semantics that a naive `??`-based
      copyWith can't represent (can't distinguish "not overridden" from
      "explicitly set to null" without a sentinel-value pattern) — `_rewriteJob`
      was already complete and correctly recursive for every existing
      field, so extending its explicit field list with `downstreamProjects`
      (with URL rewriting) was the lower-complexity fix for the actual
      risk, versus introducing sentinel-value machinery to solve a problem
      `_rewriteJob` didn't actually have. `_rewriteBuild` did get
      `upstreamCause` added to its explicit override list, since that
      field's absolute URL needs the same scheme/host/port rewrite as
      every other Jenkins-origin URL — `copyWith`'s "preserve what's not
      overridden" doesn't reach into a nested object's own URL field.

      New `UpstreamCause`/`DownstreamProject` domain types. UI: a tappable
      `_UpstreamLink` inline with the cause line, and a `Wrap` of tappable
      downstream chips at the bottom of the card (shown regardless of
      whether the job has ever built, unlike everything else on the card).
      Both navigate via a minimal stub `JenkinsJob(name, url)` passed as
      `extra` to the existing `AppRoutes.jobDetail` route — `JobDetailScreen`
      already treats its `job` param as "possibly stale, filled in by the
      real fetch" (`US-JOB-01`), so no new navigation shape was needed, and
      a deleted/renamed linked job surfaces via that story's existing
      `NotFoundFailure` handling with no new code.

      No repository interface change — the 6 fake `JenkinsRepository`
      implementations needed no updates this time. 8 new tests: 4 in
      `jenkins_build_dto_test.dart` (upstream extraction, null-when-no-
      upstream-fields, null-when-absent, `toDomain()`), 2 in
      `jenkins_job_dto_test.dart` (downstream parse + defaults), 2 in
      `jenkins_url_rewriter_test.dart` (upstream URL actually rewritten,
      downstream URLs actually rewritten — these test real rewriting, not
      just preservation, unlike the earlier causes/changes regression
      test), plus `upstreamCause` added to the existing `copyWith` test.
      `flutter analyze` clean, full suite (156 tests) passing.
- [ ] P7-09 `US-PIPE-08` — Replay with same parameters. Depends on P7-00
      (crumb) and reuses `US-JOB-03`'s `ParameterForm` + `US-HIST-02`'s
      per-job history list. Needs each history build's actual recorded
      parameter values, not just its metadata — extend `_historyTree` (or
      a per-build detail fetch) accordingly.

Each task needs: the domain/DTO/repository changes, the notifier, the UI,
and unit tests per `NFR-TEST-01`, plus manual verification against a real
Jenkins instance per `NFR-TEST-02` before being checked off.
