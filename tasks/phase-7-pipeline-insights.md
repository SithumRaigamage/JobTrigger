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
- [ ] P7-04 `US-PIPE-06` — Test result summary. New repository method for
      `{buildURL}/testReport/api/json`; compact pass/fail/skip chip on the
      job-detail card; tap-through to failing test names.
- [ ] P7-05 `US-PIPE-07` — Build artifacts. Extend job-detail fetch with
      `artifacts[fileName,relativePath]`; list + open via `url_launcher`
      (list-and-open only, no on-device download/file management, per the
      story's own scoping).
- [ ] P7-06 `US-PIPE-04` — Pipeline stage view. New repository method for
      `{buildURL}/wfapi/describe`; new `PipelineStage` domain type; stage
      chip row above the console log viewer; falls back to today's
      log-only view on 404 (freestyle jobs / no Pipeline plugin).
- [ ] P7-07 `US-PIPE-05` — Input-step approval. Depends on P7-00 (crumb)
      and reuses P7-06's stage infra for the pending-input signal.
      `wfapi/pendingInputActions` read + `wfapi/inputSubmit` POST; new
      high-visibility banner UI per the story's design notes; reuses
      `ParameterForm` (`US-JOB-03`) when the input step requests values.
- [ ] P7-08 `US-PIPE-09` — Upstream/downstream navigation. Depends on P7-01
      (cause data carries the upstream link). Downstream requires a new
      field off the job-detail tree query (`downstreamProjects[name,url]`
      — verify exact field name against a real Jenkins instance before
      committing to it, per `NFR-TEST-02`).
- [ ] P7-09 `US-PIPE-08` — Replay with same parameters. Depends on P7-00
      (crumb) and reuses `US-JOB-03`'s `ParameterForm` + `US-HIST-02`'s
      per-job history list. Needs each history build's actual recorded
      parameter values, not just its metadata — extend `_historyTree` (or
      a per-build detail fetch) accordingly.

Each task needs: the domain/DTO/repository changes, the notifier, the UI,
and unit tests per `NFR-TEST-01`, plus manual verification against a real
Jenkins instance per `NFR-TEST-02` before being checked off.
