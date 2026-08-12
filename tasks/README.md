# Tasks

Each `phase-N-*.md` file is an ordered checklist for one migration phase
(see `docs/migration-strategy.md` for what each phase means). Task ids look
like `P3-04` (phase 3, task 4) and should be referenced in commits/PRs.

Status values: `todo`, `in-progress`, `blocked`, `done`. Update the table
below whenever a phase's overall status changes — this is the one place to
check "where are we."

## Phase status

| Phase | File | Status | Depends on |
|---|---|---|---|
| 0 — Setup | `phase-0-setup.md` | done | — |
| 1 — Core infrastructure | `phase-1-core-infrastructure.md` | done | Phase 0 |
| 2 — Auth + tool selection | `phase-2-auth-tool-selection.md` | blocked | Phase 1 |
| 3 — Credentials management | `phase-3-credentials-management.md` | done | Phase 2 |
| 4 — Jenkins job tree | `phase-4-jenkins-job-tree.md` | done | Phase 3 |
| 5 — Build execution, logs, history | `phase-5-build-execution-logs-history.md` | done | Phase 4 |
| 6 — Polish + release | `phase-6-polish-release.md` | blocked | Phase 5 (can start early on some items) |
| Backlog | `backlog.md` | n/a | — |

## Conventions

- One task = one checkbox line: `- [ ] P3-04 Add "test connection" action to server form`.
- If a task turns out bigger than expected, split it in place rather than
  letting one checkbox silently absorb multiple days of work.
- Non-blocking ideas, nice-to-haves, and explicitly out-of-scope items
  (e.g. GitHub Actions support) go in `backlog.md`, not into a phase file —
  keeps phase files focused on what's actually needed for parity.
