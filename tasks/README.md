# Tasks

Each `phase-N-*.md` file is an ordered checklist for one migration phase
(see `docs/migration-strategy.md` for what each phase means). Task ids look
like `P3-04` (phase 3, task 4) and should be referenced in commits/PRs.

Status values: `todo`, `in-progress`, `blocked`, `done`. Update the table
below whenever a phase's overall status changes — this is the one place to
check "where are we."

**Release 1.0.0:** what is still open between this branch and the tag is
tracked in [`Releases/v1.0.0/workplan.md`](../Releases/v1.0.0/workplan.md)
(87 items across freeze/merge, engineering, design, infrastructure, stores,
website, billing, device checks and docs). This table stays the source of
truth for individual task status.

## Phase status

| Phase | File | Status | Depends on |
|---|---|---|---|
| 0 — Setup | `phase-0-setup.md` | done | — |
| 1 — Core infrastructure | `phase-1-core-infrastructure.md` | done | Phase 0 |
| 2 — Auth + tool selection | `phase-2-auth-tool-selection.md` | done | Phase 1 |
| 3 — Credentials management | `phase-3-credentials-management.md` | done | Phase 2 |
| 4 — Jenkins job tree | `phase-4-jenkins-job-tree.md` | done | Phase 3 |
| 5 — Build execution, logs, history | `phase-5-build-execution-logs-history.md` | done | Phase 4 |
| 6 — Polish + release | `phase-6-polish-release.md` | done | Phase 5 (can start early on some items) |
| Release | `release-checklist.md` | dev-complete; 1.0 ships Jenkins, SonarQube and GitHub Actions (GitLab/CircleCI planned for 1.3). Store upload and device checks are MANUAL (owner), one draft per task in `manually/` | Phase 6 |
| 7 — Pipeline & build insights (epic PIPE) | `phase-7-pipeline-insights.md` | done | none — new scope, not required for parity |
| 8 — GitHub Actions integration (epic GH) | `phase-8-github-actions.md` | in-progress (development-complete; P8-00..25 of 28; P8-26/27: live API half done 2026-11-17 against a real repo; the fine-grained-token and iPhone checks are MANUAL (owner, `manually/` M-06)). Ships in release 1.0. | none — second CI tool, promoted from `backlog.md` |
| 9 — Testing, CI/CD hardening, dev tooling (epic HARDEN) | `phase-9-testing-cicd-hardening.md` | done | none — dev/QA/tooling work, promoted from a direct user request 2026-09-15 |
| 10 — SonarQube integration (epic SQ) | `phase-10-sonarqube.md` | in-progress (development-complete; P10-00..13, P10-16..24 all done; P10-14/15 are the auth-isolation and real-server checks, MANUAL (owner, `manually/` M-03/M-04). Ships in release 1.0.) | none — third CI tool, promoted from `backlog.md` |
| 11 — Jenkins extended capabilities (epic JX) | `phase-11-jenkins-extended.md` | done 2026-09-30 (P11-01..28; P11-27 closed as won't-do by its verification gate). Only P11-03 remains: MANUAL (owner), on hold, no Android device (`MANUAL.md` M-02) | P12-04 (shared repository guard); P11-01 fixture Jenkins for verification |
| 12 — Audit remediation (epic AUDIT) | `phase-12-audit-remediation.md` | done 2026-10-01 (P12-01..11 frontend, P12-20..27 backend). Audit: 41 findings, all fixed; tracker: `docs/audit/2026-09-29-workspace-audit.md`. The `buildUnstable` contrast follow-up was resolved by the Phase 14 redesign (measured 2026-11-08: text 4.52:1, dot 3.56:1 on light) | none; backend-track items need per-item approval; P12-06 needs a product decision on LAN `http://` |
| 13 — Second audit remediation (epic AUDIT-2) | `phase-13-audit-2-remediation.md` | done 2026-10-22, closed 2026-10-23 (P13-01..27 fixed; password reset deferred to `backlog.md` as US-AUTH-08). Audit documents deleted; this phase file is the record | none; AUD-66 (leaked Jenkins token) confirmed revoked by the owner 2026-11-08 |
| 14 — UI redesign (epic UI-2) | `phase-14-ui-redesign.md` | done (P14-01..26). Designs: `UI-UX/` | none — approved by the user 2026-10-23 |
| 15 — Website (epic WEB) | `phase-15-website.md` | done 2026-10-26 (P15-00..23, merged to `develop` via PR #50). Owner actions open: connect Vercel, deploy the backend, fill `site-details.ts`, P15-24 store links | none — new scope, promoted by the owner 2026-10-26. Portal go-live (P15-22) needs the backend deployed at a public `https://` URL |
| 16 — Brand logo (Concept B) | `phase-16-brand-logo.md` | done 2026-10-26 (P16-00..05, merged to `develop` via PR #51) | none — chosen and approved by the owner 2026-10-26 |
| 17 — Cloud database (MongoDB Atlas) | `phase-17-cloud-database.md` | done 2026-10-26 (P17-00..05, P17-02 dropped: no local data; merged to `develop` via PR #53). Production cluster waits for the backend host | none — Atlas dev cluster set up by the owner 2026-10-26 |
| 18 — iPhone testing on the local network | `phase-18-iphone-lan-testing.md` | done 2026-10-26 (P18-01..03; 01..02 merged via PR #54, 03 on `docs/iphone-wireless`). Guide: `IPHONE.md` | none — requested by the owner 2026-10-26 |
| 19 — Bug fixes and improvements (epic FIX) | `phase-19-bug-fixes.md` | done 2026-10-29 (P19-01..07) | none — found testing on a real iPhone 2026-10-29 |
| 20 — Subscriptions (epic SUB) | `phase-20-subscriptions.md` | in-progress — approved 2026-11-12 (P20-00); 52 of 67 checkbox items done, 15 open: backend (plans, limits, RevenueCat and Paddle webhooks, mailer, analytics), app (billing client, paywall, subscription screen, gates, P20-20..27, P20-84) and website plan/pricing/legal (P20-31..34) and web billing with Paddle (P20-83). Owner store and Paddle setup (P20-40..42, P20-85) are open. Plan: `docs/subscription/` | Launch prerequisites: backend deployed (P15-22), store accounts (`release-checklist.md`), P8-26/27 and P10-14/15 |
| Emergency — Pre-release fixes (epic EMERG) | `phase-emergency.md` | in-progress — approved 2026-11-14 (PE-00), decisions recorded in the file. E2 demo mode dev-complete and merged 2026-11-14 (PE-10..18; the iPhone walkthrough was verified by the owner 2026-11-16, the review account is an owner action). E4 PE-32..35 dev-complete 2026-11-14 (PE-30/31 are owner actions). Plan: `docs/implemented/improvement-plan.md` | Before store submission; E5 needs a real GitHub token |
| 21 — Student Plan (epic STU) | `phase-21-student-plan.md` | in-progress — approved by the owner November 2026; SP-1 and SP-2 (backend data, role, email code flow, owner email) done 2026-11-16; SP-3 (document upload, admin routes, 30-day deletion) done 2026-11-16; SP-4 (app) done 2026-11-16; SP-5 (website: verify flow, /admin/students, pricing note, privacy policy) done 2026-11-16; SP-6 (reminder email, in-app banner, expiry job) done 2026-11-16. Left: the owner checks in 'Done when' | Phase 20 (billing); ships dark until billing is on |
| 22 — Next release (improvement plan) | `phase-22-next-release.md` | development-complete 2026-11-16 — NR-01 log folding, NR-02 dashboard, NR-03 QR pairing, NR-04 error copy (verified), NR-05/P20-30 site analytics and NR-06 server-push backend (devices + FCM sender) done. Left: NR-06b (Firebase keys, app SDK + token upload, server-side trigger), Phase 20 store/RevenueCat setup, website go-live | Public release |
| 23 — Suggested first ten (product improvements) | `phase-23-product-improvements.md` | development-complete 2026-11-17: PI-01/02 safety, PI-03/04 connectivity, PI-05/06 freshness/status, PI-07 notifications, PI-08/09/10 first-run/tokens/what's new. Five batches, verified and committed | Public release |
| 24 — SonarQube Overview + Profile version fixes (epic FIX-2) | `phase-24-sonarqube-ui-fixes.md` | done 2026-11-18 (P24-01..06): credential selector chip, Overview design alignment, Profile version footer, dev-only billing preview flag, shared server/credential header on all tool screens, app-wide clamped overscroll | none — P24-05 and P24-06 visual checks are still MANUAL |
| 25 — Support and issue tickets | `phase-25-support-feedback.md` | development-complete 2026-11-18 (P25-01..06): backend tickets + owner triage, in-app Support screen with diagnostics, website copy, tests and docs. iPhone pass open (`manually/M-18`) | Public release |
| Backlog | `backlog.md` | n/a | — |

`done` above means **development-complete**, not "in production." Every
item is either done (ticked, with evidence) or **MANUAL (owner)**: a task only
the owner can do (a physical device, a store or billing account, a token),
with one draft per task in **[`manually/`](../manually/README.md)**. `tasks/MANUAL.md`
is a pointer to it so older links keep working.

## Conventions

- One task = one checkbox line: `- [ ] P3-04 Add "test connection" action to server form`.
- If a task turns out bigger than expected, split it in place rather than
  letting one checkbox silently absorb multiple days of work.
- Non-blocking ideas and nice-to-haves (e.g. GitLab CI and CircleCI, planned
  for 1.3) go in `backlog.md`, not into a phase file — keeps phase files
  focused on what's actually needed for the current release.
