# JobTrigger — User Stories

## Product goal

JobTrigger lets a DevOps engineer trigger, monitor, and inspect CI/CD
builds from their phone (iOS + Android), without needing a laptop open to
the CI tool's own web UI. Jenkins was the sole supported tool through the
Flutter rewrite's original scope (files 00–08); GitHub Actions (epic GH,
[12-github-actions.md](12-github-actions.md)) was added as a second real
tool afterward, promoted out of `10-out-of-scope-backlog.md`'s
`BACKLOG-01`. This story set is the complete, security-conscious
specification of that product: every screen a user can reach, every action
they can take, and the visual language (glassmorphism) it must present it
in.

This is a BA deliverable, not an implementation plan. Per `CLAUDE.md` §9,
each story (or group of stories) still needs its own plan/design step and
explicit approval before code is written against it.

## How this set is organized

| File | Epic | Covers |
|---|---|---|
| [00-design-system-glassmorphism.md](00-design-system-glassmorphism.md) | DESIGN | The frosted-glass visual language every screen below must implement |
| [01-authentication.md](01-authentication.md) | AUTH | Sign up, log in, session persistence, logout, session expiry |
| [02-tool-selection.md](02-tool-selection.md) | TOOL | Choosing Jenkins as the active CI tool |
| [03-credential-management.md](03-credential-management.md) | CRED | Add/edit/delete/switch Jenkins servers, test connection |
| [04-job-tree-navigation.md](04-job-tree-navigation.md) | TREE | Browsing, searching, and refreshing the job/folder tree |
| [05-job-detail-build-trigger.md](05-job-detail-build-trigger.md) | JOB | Job detail, parameterized triggering, live status, cancel |
| [06-build-logs.md](06-build-logs.md) | LOG | Streaming console log, copy/share |
| [07-build-history.md](07-build-history.md) | HIST | Global and per-job build history |
| [08-profile-settings-app-info.md](08-profile-settings-app-info.md) | PROF | Profile, appearance, app info, bottom tab navigation |
| [09-non-functional-security.md](09-non-functional-security.md) | NFR | Cross-cutting security/testing/accessibility/performance/platform baselines referenced by ID from every story above |
| [10-out-of-scope-backlog.md](10-out-of-scope-backlog.md) | BACKLOG | Deliberately deferred items, so the set is complete *by exclusion* too |
| [11-build-insights-pipeline.md](11-build-insights-pipeline.md) | PIPE | New-scope Jenkins capabilities beyond the original SwiftUI app — queue status, build cause, SCM changelog, pipeline stage view, input-step approval, test results, artifacts, replay, upstream/downstream navigation |
| [12-github-actions.md](12-github-actions.md) | GH | A second real CI tool (promoted out of `BACKLOG-01`): credential management, repository/workflow browsing, run triggering/status/cancel, job logs, history |

## Story ID convention

`US-<EPIC>-##`, e.g. `US-AUTH-01`. Epic codes: `AUTH`, `TOOL`, `CRED`,
`TREE`, `JOB`, `LOG`, `HIST`, `PROF`, `DESIGN`, `PIPE`, `GH` (with a
sub-epic segment for GH: `GH-CRED`, `GH-REPO`, `GH-RUN`, `GH-LOG`,
`GH-HIST`, e.g. `US-GH-CRED-01`). Cross-cutting baselines use
`NFR-<CATEGORY>-##` (e.g. `NFR-SEC-01`) and are referenced, not repeated.
Deferred items use `BACKLOG-##`.

## Story template

Every story in files 00–08 follows this shape:

```
### US-XXX-## — <Title>

**Priority:** Must / Should / Could (MoSCoW)
**Source:** tasks/phase-N-*.md (task id), or "new — design refresh" for
            glassmorphism-driven changes to an existing screen
**Dependencies:** other story IDs this assumes are done

As a <role>
I want <capability>
So that <benefit>

**Acceptance Criteria**
- Scenario: <happy path>
  Given <context> When <action> Then <outcome>
- Scenario: <validation/edge case>
  ...
- Scenario: <failure/error state — named against the real AppFailure type>
  ...
- Scenario: <security-relevant case, where applicable>
  ...

**Security & Privacy Notes**
- ...

**UI / Design Notes**
- References the surfaces/behavior defined in US-DESIGN-* for this screen.

**Non-Functional Notes**
- References NFR-* IDs that apply.
```

Priority follows the `docs/migration-strategy.md` parity checklist: anything
on that checklist is **Must**; genuine polish (e.g. haptics, copy tone) is
**Should**; nice-to-haves not on the checklist are **Could**.

## Definition of done for this story set

- Every row of the `docs/migration-strategy.md` feature-parity checklist is
  covered by at least one story below (see traceability table).
- Every backend (`JobTrigger-Backend`) and Jenkins REST endpoint listed in
  `docs/api-reference.md` is exercised by at least one story's acceptance
  criteria.
- Every screen-bearing story states how the glassmorphism design system
  applies to it (US-DESIGN-*), including the accessibility and performance
  guardrails — glassmorphism is not treated as "free" visual polish.
- Every story's failure-state acceptance criteria map to a real `AppFailure`
  variant (`NetworkFailure`, `AuthFailure`, `NotFoundFailure`,
  `ServerFailure(statusCode)`, `UnknownFailure`) rather than inventing new
  error shapes.
- No story requires a backend capability that doesn't already exist in
  `docs/api-reference.md`. Anywhere a security best practice would normally
  imply new backend work (e.g. login rate-limiting, server-side log
  redaction), the story calls that out explicitly as a **flagged risk for a
  separate backend track**, per `CLAUDE.md` §7 — it is not silently
  implemented client-side as a substitute.
- Deliberately excluded product surface is listed in
  [10-out-of-scope-backlog.md](10-out-of-scope-backlog.md) rather than
  omitted without comment.

## Traceability — parity checklist → stories

| `migration-strategy.md` parity item | Story IDs |
|---|---|
| Signup, login, session persistence across restarts | US-AUTH-01, US-AUTH-02, US-AUTH-03 |
| Add/edit/delete Jenkins server, switch active server | US-CRED-02, US-CRED-03, US-CRED-04, US-CRED-05 |
| Connection diagnostic (health check) pass/fail | US-CRED-06 |
| Recursive job/folder tree to 6 levels, breadcrumb navigation | US-TREE-01, US-TREE-02 |
| Live job search across full tree | US-TREE-03 |
| Trigger build, with/without parameters | US-JOB-02, US-JOB-03 |
| Real-time build status polling with progress bar | US-JOB-04 |
| Cancel a running build | US-JOB-05 |
| Progressive console log streaming, performant at scale | US-LOG-01, US-LOG-02, NFR-PERF-03 |
| Global cross-job history (top 50) + per-job history | US-HIST-01, US-HIST-02 |
| Theme: system/light/dark | US-PROF-02 |
| Toast/banner notifications for success/error | NFR-SEC-04 (referenced across AUTH/CRED/JOB stories) |
| App info/version screen | US-PROF-03 |
| Copy/share build log | US-LOG-03 |
| Persistent bottom tab bar | US-PROF-04 |
| Cold-start, backgrounding, token-expiry (401 mid-session) | US-AUTH-03, US-AUTH-05, NFR-PLAT-01 |
| Testing against ≥2 differently-configured Jenkins servers | NFR-TEST-02 |

Glassmorphism is not on the original parity checklist — it is a new
requirement layered onto every story above via US-DESIGN-01…05, and tracked
as its own line item precisely because it changes the definition of "done"
for every screen already marked complete in `tasks/`.

Epic PIPE ([11-build-insights-pipeline.md](11-build-insights-pipeline.md))
is layered on the same way, for the same reason glassmorphism is: it is
**not** required to reach the original migration's definition of done and
deliberately does not appear in the traceability table above, which stays
scoped to the original 13 parity rows from `docs/migration-strategy.md`.
Unlike glassmorphism, PIPE didn't come from a design requirement — it came
from auditing what the already-shipped Jenkins integration implements
against what the Jenkins REST API offers, after full parity was reached.
One PIPE story (US-PIPE-05) and its supporting NFR (NFR-SEC-06) are a
correctness fix for the existing trigger/cancel flow (a missing CSRF
crumb), not new scope — everything else in that file is genuinely new
capability, none of it started.

Epic GH ([12-github-actions.md](12-github-actions.md)) is different from
both of the above: it's not layered onto an already-complete app the way
PIPE and glassmorphism are, and it's not new-scope-by-audit either — it's
`10-out-of-scope-backlog.md`'s `BACKLOG-01` (originally deferred with the
reasoning "v1 scope is Jenkins-only... each additional CI tool is its own
integration surface and a separate initiative"), explicitly promoted into
active scope by the user on 2026-09-14. It doesn't appear in the
traceability table above (that table stays scoped to the original 13
Jenkins parity rows) for the same structural reason PIPE doesn't: GH is a
second tool's worth of stories, not a checklist item. Unlike PIPE, none of
GH reuses Jenkins domain/data code — see the epic's own intro for why.
