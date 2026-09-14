# Phase 8 — GitHub Actions Integration (Epic GH)

Goal: implement `docs/user-stories/12-github-actions.md`'s full-parity
GitHub Actions support — a second real CI tool alongside Jenkins, promoted
out of `tasks/backlog.md`'s deferred GitHub Actions item on 2026-09-14
(decision: full parity, not a read-only MVP; PAT auth, not OAuth; a new
backend `GitHubCredential` model, not client-storage-only; a separate
parallel credential type, not a unified polymorphic `Credential`).

This is comparable in size to Phases 3–5 combined, for a structurally
different API (GitHub's flat repo→workflow→run→job→steps model, not
Jenkins' recursive folder tree — see the epic doc's intro for why there's
no "GH-TREE" section). No Jenkins domain/data code is reused; only the
routing shell, glass UI components (`GlassSurface`, `ResponsiveCenter`),
the `Result`/`AppFailure` pattern, and Riverpod notifier conventions carry
over. Endpoint paths/JSON shapes below are verified against GitHub's real
REST API docs (`docs.github.com`, API version `2022-11-28`), not guessed —
still needs `NFR-TEST-03`'s real-repository verification before any task
here is marked done, same as Jenkins tasks needed `NFR-TEST-02`.

Working order is dependency-driven: backend first (nothing client-side can
work without it), then credentials, then repo/workflow browsing, then run
detail/trigger/status/cancel, then the two things that build on run detail
(step breakdown, logs), then history last (the `Could`-priority global
feed in particular has the least urgency — it's the one story explicitly
scoped down from a Jenkins equivalent due to GitHub's rate limits, see
`US-GH-HIST-02`). Each task needs a plan/design checkpoint before its code
lands, per `CLAUDE.md` §9 — same cadence Phase 7 used.

## Backend

- [x] P8-00 New `JobTrigger-Backend` `GitHubCredential` Mongoose model
      (`models/GitHubCredential.js`) + controller
      (`controllers/githubCredentialsController.js`) + routes
      (`routes/githubCredentialRoutes.js`, mounted at
      `/api/github-credentials` in `server.js`) — mirrors
      `JenkinsCredential`'s shape/behavior field-for-field (get/add/update/
      delete + a `switch/:id` active-credential endpoint, same ownership
      checks, same "unset others' `isDefault` first" logic, same
      `{message, error}` 500-error shape), fields renamed for GitHub:
      `label` (was `serverName`), `token` (was `password` — the PAT),
      `defaultOwner` (was `paramToken` positionally, new meaning: an
      optional org/user filter for the repo list, `US-GH-REPO-01`).
      **Not** a modification to `JenkinsCredential`/`credentialsController`
      — fully separate files, per the credential-architecture decision.
      `NFR-SEC-01`'s flagged-risk posture carries over: whether PATs are
      encrypted at rest is a backend concern, documented not assumed —
      same as it already was for Jenkins passwords.

      8 new tests in `test/github_credentials.test.js` (add, get, update,
      delete, switch-active, plus an ownership-and-defaults group mirroring
      `credentials_ownership.test.js`'s two cases) — full backend suite
      (20 tests) passing, zero regressions to the existing 12.

## GH-CRED — Credential management (client)

- [x] P8-01 `data/models/credential/github_credential_dto.dart`,
      `domain/credential/github_credential.dart` — mirrors
      `jenkins_server.dart`'s shape field-for-field (`id`, `label`, PAT
      renamed `secret` domain-side same as `JenkinsServer.secret`,
      `defaultOwner`, `isDefault`), including the redacted `toString()`
      (`NFR-SEC-01`'s concrete mechanism). **Not** a subtype/variant of
      `JenkinsServer` — a fully independent class, per the
      credential-architecture decision.
- [x] P8-02 `GitHubCredentialsRepository` interface + impl — CRUD against
      P8-00's `/api/github-credentials` endpoints via `dioBackendProvider`
      (the JWT-authed backend client — credential storage always goes
      through our own backend regardless of CI tool, this is not the
      GitHub Actions API client itself), `Result<T, AppFailure>`
      throughout, mirrors `CredentialsRepositoryImpl` structurally.

      5 new tests in `github_credentials_repository_impl_test.dart`
      mirroring `credentials_repository_impl_test.dart`'s exact coverage
      (fetchAll → entity mapping incl. `token`→`secret` rename, add →
      wire-body field names incl. `secret`→`token` rename, delete
      succeeds regardless of response body shape, switchActive, a non-2xx
      → `Err`/`ServerFailure`). `flutter analyze` clean, full suite
      (170 tests) passing.
- [x] P8-03 `core/network/github_client_factory.dart` —
      `buildGithubDio({token})` sets `Authorization: Bearer <token>` once
      at construction against a fixed `githubApiBaseUrl` (unlike Jenkins,
      every credential talks to the same `api.github.com` — only the
      token varies per credential, not the base URL); **no** CSRF crumb
      interceptor (`NFR-SEC-06` is Jenkins-only, GitHub's API doesn't use
      one).

      **Refined from the original task note**: rate-limit detection ended
      up in `AppFailure.fromGithubException()` (`core/error/app_failure
      .dart`) rather than a Dio response interceptor — it's passive
      error-*classification* (does this 403 mean "bad token" or "rate
      limited"?), not request-*mutation* like the Jenkins crumb
      interceptor's retry-with-a-fresh-header behavior, so it fits this
      codebase's existing `AppFailure`-mapping layer better than a new
      interceptor. New `RateLimitFailure` added to the `AppFailure` sealed
      hierarchy (had to land in `app_failure.dart` itself — Dart requires
      a sealed class's direct subtypes in the same file) with its own
      user-facing message; `fromGithubException` is a **separate entry
      point** from the existing `fromDioException`, so Jenkins/backend
      403s keep meaning exactly what they already mean — nothing about
      shipped 401/403 handling changed.
- [x] P8-04 `testGithubConnection()` — `GET /user` with a throwaway Dio
      instance (matches `testJenkinsConnection()`'s pattern), surfaces the
      authenticated username on success (`US-GH-CRED-04`). Implemented in
      the same file as P8-03, matching how `jenkins_client_factory.dart`
      already bundles `buildJenkinsDio` + `testJenkinsConnection`.

      **Testability note**: `testGithubConnection` itself has no direct
      test — it always builds its own internal `Dio` (deliberately, never
      the active credential's client) with no seam to inject a fake
      adapter, the exact same shape `testJenkinsConnection` already has in
      this codebase (also untested, for the same reason — confirmed, not
      an oversight introduced here). First attempt at testing it via a
      reimplemented copy of its logic in the test file was caught and
      rejected as bad test hygiene (verifies a copy, not the shipped
      function) before being kept. The logic actually worth testing —
      rate-limited vs. plain 403 — lives in `AppFailure
      .fromGithubException` and is tested there directly instead.

      7 new tests: 5 in `app_failure_test.dart`'s new
      `AppFailure.fromGithubException` group (rate-limited 403 →
      `RateLimitFailure`, non-zero-remaining 403 → plain `AuthFailure`,
      no-header 403 → plain `AuthFailure`, 401/network-error →
      delegates to `fromDioException` unchanged), 2 in
      `github_client_factory_test.dart` (`buildGithubDio` header/base-URL
      construction, per-call token independence). `flutter analyze`
      clean, full suite (177 tests) passing.
- [x] P8-05 `GitHubCredentialsNotifier` (list, mirrors
      `CredentialsNotifier`) + `ActiveGitHubCredentialNotifier` (mirrors
      `ActiveServerNotifier` exactly — rehydrate-from-prefs, set, clear,
      delete-with-fallback), entirely independent state from
      `ActiveServerNotifier`: its own provider, its own
      `SharedPreferences` key (`active_github_credential_id`), zero shared
      code — switching one never touches the other (`US-GH-CRED-03`).

      **Naming consistency fix caught while wiring this up**: earlier P8
      commits had drifted between `Github`/`github`/`GitHub` casing across
      files (`buildGithubDio`, `fromGithubException`, a provider function
      named `githubCredentialsRepository` that riverpod_generator turned
      into `githubCredentialsRepositoryProvider`, while the class-based
      `GitHubCredentialsNotifier` generated `gitHubCredentialsNotifierProvider`
      — two different casings for what should be one consistent scheme).
      Standardized everything to `GitHub`/`gitHub` (matching the brand
      name) across P8-00–P8-04's files before continuing, rather than
      letting the inconsistency compound over the remaining ~20 tasks:
      `buildGitHubDio`, `testGitHubConnection`, `gitHubApiBaseUrl`,
      `AppFailure.fromGitHubException`, `gitHubCredentialsRepository`
      (provider function).

      4 new tests in `active_github_credential_notifier_test.dart`
      mirroring `active_server_notifier_test.dart`'s exact fallback-logic
      coverage (deletes active → falls back to `isDefault`, falls back to
      first when none default, clears when none remain, deleting
      non-active leaves active untouched). `flutter analyze` clean, full
      suite (181 tests) passing.
- [x] P8-06 Settings UI: new `GitHubCredentialFormNotifier` (mirrors
      `ServerFormNotifier`), `TestGitHubConnectionNotifier` (mirrors
      `TestConnectionNotifier`, surfaces the authenticated username on
      success instead of a job count — GitHub's `/user` has no count
      equivalent), `GitHubCredentialEditBottomSheet` (mirrors
      `ServerEditBottomSheet` exactly: same wide/narrow `Dialog`-vs-sheet
      split, same `useRootNavigator: true` fix, PAT field never pre-filled
      when editing, "leave blank to keep the current token" on edit).

      **`SettingsScreen` restructured** from a single `Expanded` Jenkins
      list to one `CustomScrollView` of slivers, so the new "GitHub"
      section (separate from the Jenkins list, not merged into it, per the
      credential-architecture decision) sits below it in one shared scroll
      region rather than two competing `Expanded` panes or a second
      floating `FloatingActionButton`. Each section now has its own inline
      "add" affordance in a `_SectionHeader` instead of one global FAB;
      the Jenkins section's actual widgets/behavior (radio indicator,
      swipe-delete confirm, switch-active toast, delete-failed toast) are
      unchanged, just moved from `_ServerList`/`_ServerTile`-combined into
      a standalone `_ServerTile` feeding a shared `_credentialSlivers<T>`
      helper. New `_GitHubCredentialTile` mirrors `_ServerTile` for
      `GitHubCredential` — deliberately not a shared generic widget, the
      two domain types don't have matching fields.

      **No real device available to visually verify this restructuring**
      (confirmed, same standing limitation as every other UI task in this
      project's history) — added a widget smoke test
      (`settings_screen_test.dart`, 2 tests: empty-both-sections, and
      populated-both-sections) that pumps the real `SettingsScreen` with
      fake repositories and asserts it renders without throwing, which
      **did** catch this being a genuine risk worth testing (a
      `CustomScrollView`/sliver restructuring is exactly the kind of
      change that passes `flutter analyze` cleanly but can still blow up
      at runtime with an unbounded-height or similar `RenderFlex` error) —
      both pass, but this is real-device visual verification's substitute,
      not a replacement for it; flagging the gap rather than claiming full
      confidence.
- [x] P8-07 Unit tests: covered incrementally alongside each task above
      rather than as one separate pass at the end (`GitHubCredentialsRepositoryImpl`
      CRUD in P8-02, active-credential fallback logic in P8-05,
      crumb-free Bearer-auth header construction in P8-03/04, rate-limit-
      header → distinct `AppFailure` mapping in P8-03/04) — no additional
      tests needed here beyond the 2 new `settings_screen_test.dart` smoke
      tests. `flutter analyze` clean, full suite (183 tests) passing.

## GH-REPO — Repository & workflow browsing

- [ ] P8-08 `GitHubRepo`/`GitHubWorkflow` domain types + DTOs (fields per
      the epic doc's verified JSON shapes:
      `id,name,path,state` for workflows;
      `id,name,owner,private` at minimum for repos — confirm the rest
      against a real `GET /user/repos` response during `NFR-TEST-03`
      verification, GitHub's repo object has many more fields than
      needed).
- [ ] P8-09 `GitHubRepository.fetchRepos()` — `GET /user/repos?per_page=
      100&sort=updated`, paginated via GitHub's `Link` header (load-more-
      on-scroll, not all pages upfront, `US-GH-REPO-01`).
- [ ] P8-10 `GitHubRepository.fetchWorkflows(owner, repo)` — `GET
      /repos/{owner}/{repo}/actions/workflows` (`US-GH-REPO-02`).
- [ ] P8-11 `GitHubRepoScreen` + `GitHubWorkflowListScreen` — glass card
      list pattern reused from `HomeScreen`'s job tiles; default-org-filter
      UI; disabled-workflow visual state; client-side search filtering
      (no per-keystroke network call, `NFR-PERF-02`).

## GH-RUN — Workflow runs: view, trigger, live status, cancel, steps

- [ ] P8-12 `GitHubWorkflowRun` domain type + DTO — **two separate
      fields**, `status` and `conclusion` (not one `result` string like
      Jenkins), per the verified API shape.
- [ ] P8-13 `GitHubRepository.fetchRuns(owner, repo, workflowId)` — `GET
      /repos/{owner}/{repo}/actions/workflows/{workflow_id}/runs`
      (`US-GH-RUN-01`).
- [ ] P8-14 `GitHubRepository.triggerRun(owner, repo, workflowId, {ref,
      inputs})` — `POST .../dispatches`; 204 response carries no run ID
      (unlike Jenkins' `Location`-header queue tracking, `US-PIPE-01`) —
      the notifier refreshes the runs list rather than tracking the new
      run directly; a 422 (workflow has no `workflow_dispatch` trigger)
      maps to a specific, clear `AppFailure` message, not a generic
      server error (`US-GH-RUN-02`).
- [ ] P8-15 `GitHubRepository.fetchRun(owner, repo, runId)` +
      `GitHubRunPollingNotifier` — 5s polling while not `completed`, same
      timer/`ref.onDispose` discipline as `BuildStatusPollingNotifier`;
      stops on a rate-limit response with a clear message rather than
      retrying into a worse state (`US-GH-RUN-03`).
- [ ] P8-16 `GitHubRepository.cancelRun(owner, repo, runId)` — `POST
      .../cancel` (202 Accepted, genuinely async — no optimistic
      `cancelled` flip like Jenkins' `US-JOB-05`, a "cancelling…"
      transitional state instead, corrected by the next poll)
      (`US-GH-RUN-04`).
- [ ] P8-17 Workflow-run detail screen: trigger form (ref field defaulting
      to the repo's default branch, untyped key/value inputs list — no
      typed `ParameterForm` equivalent is possible here, GitHub's API
      doesn't expose a workflow's declared input schema, `US-GH-RUN-02`'s
      flagged gap), confirm-before-trigger and confirm-before-cancel
      dialogs, live status display.
- [ ] P8-18 `GitHubJob` domain type + DTO (`id,name,status,conclusion,
      steps[]`) + `GitHubRepository.fetchJobs(owner, repo, runId)` — `GET
      .../runs/{run_id}/jobs` (`US-GH-RUN-05`).
- [ ] P8-19 Promote `_StageChipRow` out of `job_detail_screen.dart` into a
      shared widget (`presentation/common_widgets/stage_chip_row.dart` or
      similar) so both Jenkins pipeline stages (`US-PIPE-04`) and GitHub
      job steps reuse the same rendering — do this as part of P8-18/20's
      UI work, not a separate unrelated refactor commit.
- [ ] P8-20 Unit tests: all new repository methods against mocked
      responses (status/conclusion parsing, 422-on-dispatch mapping,
      pagination via `Link` header, rate-limit mid-poll handling); polling
      notifier timer/dispose tests mirroring
      `build_status_polling_notifier_test.dart`'s coverage.

## GH-LOG — Job log viewing

- [ ] P8-21 `GitHubRepository.fetchJobLog(owner, repo, jobId)` — `GET
      .../jobs/{job_id}/logs`, follows the 302 redirect and fetches the
      plain-text body as one atomic operation (the redirect URL itself
      never reaches the UI or gets cached — it expires in ~1 minute per
      GitHub's docs). Only offered once a job's `status == 'completed'` —
      **no polling/live-tail attempt**, GitHub's API has no offset/tail
      mechanism to poll safely (`US-GH-LOG-01`'s core scope limitation,
      flagged in the epic doc — don't try to work around it with naive
      full-redownload polling, that was explicitly rejected as a design
      option).
- [ ] P8-22 `GitHubJobLogScreen` — reuses `ConsoleLogViewer` unmodified
      for rendering (`US-LOG-01`'s virtualized list); a manual "check now"
      refresh action instead of automatic polling while a job is still
      running; copy/share via the same `share_plus` pattern as
      `BuildLogScreen` (`US-GH-LOG-02`).
- [ ] P8-23 Unit tests: redirect-following log fetch against a mocked
      302 → text sequence; in-progress-job "not available yet" state.

## GH-HIST — Run history

- [ ] P8-24 Per-workflow history screen reusing `HistoryTile`'s visual
      pattern (adapted for `GitHubWorkflowRun`) — this is the same data
      P8-13 already fetches, just a fuller-page presentation
      (`US-GH-HIST-01`).
- [ ] P8-25 Global cross-repo history feed (`Could` priority — genuinely
      optional, do last, revisit whether it's worth the rate-limit cost
      before starting): fans out one runs-fetch per accessible repo,
      capped to the N most-recently-updated repos rather than exhausting
      GitHub's 5,000/hr rate limit on one screen (`US-GH-HIST-02`'s
      explicit scope-down).

## Cross-cutting

- [ ] P8-26 `NFR-SEC-03` verification: a live test confirming a GitHub
      401 never triggers Jenkins' per-server auth handling or the
      backend's global logout, and vice versa — three independent auth
      failure domains, not two.
- [ ] P8-27 Full `NFR-TEST-03` pass: every GH-CRED/REPO/RUN/LOG/HIST task
      above manually verified against a real GitHub repository with real
      Actions workflows (including at least one with `workflow_dispatch`
      inputs, one without, and one disabled workflow) before this phase
      is marked done.
