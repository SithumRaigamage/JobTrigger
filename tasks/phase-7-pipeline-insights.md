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

- [ ] P7-00 `NFR-SEC-06` — CSRF crumb helper. `GET /crumbIssuer/api/json`
      on the active Jenkins client, attach the returned header to every
      state-changing Jenkins POST (`build`, `buildWithParameters`,
      `{buildNumber}/stop`, and later `wfapi/inputSubmit` in P7-06).
      Gracefully no-ops on servers without a crumb issuer (older/CSRF-off
      Jenkins) instead of failing. One retry with a freshly-fetched crumb
      on a 403 that looks crumb-related, before surfacing a real
      `AuthFailure`. Fixes existing `US-JOB-02/03/05` silently, not just
      new PIPE stories.
- [ ] P7-01 `US-PIPE-02` — Build cause. Extend the job-detail `tree` query
      with `actions[causes[shortDescription]]`; new `BuildCause` domain
      field; render as a caption line on the job-detail card.
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
