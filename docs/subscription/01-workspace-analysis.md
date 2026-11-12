# Workspace analysis — before subscriptions

**Date:** 2026-11-12 · **Purpose:** a snapshot of the whole JobTrigger
workspace, read end to end, as the starting point for the subscription
plan ([`02-business-model.md`](02-business-model.md),
[`03-technical-design.md`](03-technical-design.md),
[`tasks/phase-20-subscriptions.md`](../../tasks/phase-20-subscriptions.md)).

Status of record stays in [`tasks/README.md`](../../tasks/README.md) (AUD-61).
This file only describes the workspace; it doesn't replace that tracker.

## 1. What JobTrigger is today

A mobile app for DevOps engineers to trigger, watch and inspect CI/CD
work from a phone, plus a website for setting servers up from a laptop.
Three projects in one repo:

| Part | Folder | Stack | Size (approx.) | Role |
|---|---|---|---|---|
| Mobile app | `JobTrigger-Frontend/` | Flutter, Dart 3, Riverpod 3, dio, go_router, freezed | ~283 source files, ~32k lines; ~227 test files | iOS + Android client. Talks to the backend for accounts and saved credentials, and **directly** to Jenkins / GitHub / SonarQube for everything else. |
| Backend | `JobTrigger-Backend/` | Node 24, Express 5, Mongoose 9, MongoDB Atlas | ~4.5k lines; 25 test files (mocha + in-memory Mongo) | Accounts (JWT access 15 min + refresh 30 days), encrypted credential storage for Jenkins, GitHub and SonarQube, app info. |
| Website | `JobTrigger-Web/` | Next.js 16 App Router, TypeScript, Tailwind 4, zod, iron-session | ~144 source files; 43 unit/e2e test files | Marketing pages + signed-in setup portal (BFF: the browser never sees a secret or a token). |

Supporting folders: `docs/` (architecture, API, data models, market
research, user stories by tool), `tasks/` (phases 0–19, backlog, release
checklist — 290 tasks ticked), `tools/jenkins-fixture/` (a Dockerised
Jenkins for testing), `UI-UX/` (Phase 14 designs), `postman/`, `scripts/`,
`.github/workflows/` (Flutter CI, Node tests, security scans, manual CD).

## 2. Feature inventory

| Area | State | Evidence |
|---|---|---|
| Accounts: sign up, log in, refresh, sign out everywhere, change password, delete account | Done | Phases 2, 13; `routes/authRoutes.js` |
| Password reset by email | **Not built** — no email provider | `backlog.md` US-AUTH-08 |
| Jenkins: tree, search, trigger with every parameter type, live status, logs, history, stages, tests, artifacts, replay, input approval, queue, nodes, views, multibranch | Done, frozen (CLAUDE.md §11) | Phases 4, 5, 7, 11 |
| Notifications (local), background watch, pinned jobs, home-screen widget, biometric lock, offline tree | Done | Phase 11 |
| GitHub Actions: accounts, repos, workflows, runs, trigger, cancel, jobs/steps, logs, history | Dev-complete; P8-26/27 need a real token | Phase 8 |
| SonarQube: projects, quality gate, measures, issues, analyses, overview | Dev-complete; P10-14/15 real-server checks | Phase 10 |
| GitLab CI, CircleCI | Stories written, not built | `docs/user-stories/gitlab`, `circleci` |
| Website marketing + setup portal | Done, not deployed | Phase 15 |
| Store release | Blocked: artwork, store accounts, signing | `release-checklist.md` |

## 3. How the pieces talk

```text
 Phone app ──x-auth-token──▶ Backend (Express) ──▶ MongoDB Atlas
    │                            ▲                 users, *Credential (AES at rest)
    │                            │
    │                     Website server (BFF, iron-session cookie)
    │
    └──Basic auth / PAT / Sonar token──▶ Jenkins · GitHub · SonarQube (direct, no proxy)
```

Two facts matter most for a subscription:

1. **The backend never sees CI traffic.** Triggers, logs and polling go
   phone → CI tool. The backend only stores accounts and credentials.
   So anything the backend doesn't touch (widget, notifications, log
   viewer) can only be gated **in the app**. What the backend *does* own —
   how many servers and which tools a user can save — can be enforced on
   the server, where it can't be bypassed.
2. **One credential controller serves all three tools**
   (`controllers/credentialControllerFactory.js`, AUD-31). A plan limit
   on "create credential" is one change in one place.

## 4. Strengths to build on

- **Clean layering everywhere.** Flutter: presentation → domain → data,
  `Result<T, AppFailure>`; web: `app/ → features/ → server/`. A new
  `subscription` feature slots in the same way as `github` or `sonarqube`.
- **Security posture already audited twice** (66 findings, all closed):
  encrypted secrets with key ids, rate limits, token versioning, CSP with
  nonces, no secrets in the browser. Billing webhooks can reuse the same
  patterns (central error handler, request ids, structured logs).
- **Strong test culture.** Mandatory unit tests for repositories and
  notifiers; backend tests on in-memory Mongo; Playwright against a fake
  backend. Billing logic is very testable this way (fake webhook events).
- **A clear market gap.** `docs/market/competitive-analysis.md`: no app
  combines Jenkins + GitHub Actions + SonarQube on iOS *and* Android with
  laptop setup. That combination is what a paid tier can sell.
- **A real running cost competitors don't have** (backend, sync, web
  portal) — a fair reason to charge, already noted in that analysis §7.3.

## 5. Gaps that matter for a paid product

Ranked by how much they would hurt paying users.

| # | Gap | Why it matters once people pay | Where it's tracked |
|---|---|---|---|
| G1 | **Backend not deployed** at a public `https://` URL | No production backend → no accounts → nothing to sell. Also blocks the portal (P15-22). | `phase-15-website.md`, `phase-17-cloud-database.md` |
| G2 | **No password reset** | A paying user who forgets their password is locked out of what they paid for, and support can't help. | `backlog.md` US-AUTH-08 |
| G3 | **No crash reporting or product analytics** | No way to see paywall views, trial starts, conversion or churn, or crashes that cause refunds. | `backlog.md` (P6-08) |
| G4 | **Store accounts, signing, artwork** | In-app purchases need App Store Connect + Play Console set up, with agreements, tax and banking. | `release-checklist.md` |
| G5 | **No email provider** | Needed for G2, and useful for trial-ending and billing-issue notices. Stores send receipts themselves. | `backlog.md` |
| G6 | **Terms and privacy pages don't cover billing** | Stores require subscription terms, auto-renew wording and links on the paywall. | `JobTrigger-Web/src/features/marketing/legal/` |
| G7 | **Real-server verification open** for GitHub (P8-26/27) and SonarQube (P10-14/15) | These are the paid tools; they must be verified before charging for them. | Phases 8, 10 |
| G8 | **No feature flags / remote config** | Turning the paywall on, or changing limits, would need a store release. | — |

## 6. Housekeeping noticed during the read

- The checked-out branch is `feat/sonarqube-overview-and-polish`, with
  uncommitted website changes (`reveal-token.tsx` and four modified
  files under `JobTrigger-Web/src/`). Commit or stash them before starting
  Phase 20 on a fresh branch from `develop`.
- About 30 local branches; several look merged (`fix/*`, `feat/github-*`).
  A prune would make the subscription branch easier to find.
- Secrets are correctly git-ignored (`.env`, `.env.bak`, `.env.local`,
  `.fixture-credentials`, `.scannerwork/`, `.next/`). Nothing sensitive is
  tracked.
- `README.md`'s status table is older than `tasks/README.md` (it still
  shows Phases 2 and 6 as blocked). Worth pointing it at the tracker.
- `JobTrigger-Backend/package.json` still names the package
  `lab-trigger-backend` with an empty description.

## 7. Conclusion

Engineering is far ahead of the business side: the product is broad,
tested and audited, but it has no production backend, no store presence,
no analytics and no billing. The subscription work is therefore **two
tracks that must land together**: the billing feature itself (Phase 20),
and the launch prerequisites G1–G7, which a paid launch can't skip.
