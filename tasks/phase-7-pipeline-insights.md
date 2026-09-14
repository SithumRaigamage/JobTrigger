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
- [ ] P7-02 `US-PIPE-01` — Queue status. New repository method hitting
      `{jobURL}/queue/api/json` (called right after a successful trigger,
      and once on job-detail load); new `QueueItem` domain type; job-detail
      UI gets a "queued" state distinct from building/not-building.
- [ ] P7-03 `US-PIPE-03` — SCM changelog. Extend the job-detail `tree`
      query with `changeSet[items[msg,author[fullName]]]`; render under
      the P7-01 cause line, collapsible past ~3 entries.
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
