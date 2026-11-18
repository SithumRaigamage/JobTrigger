# JobTrigger 1.0.0 — release workplan

**Created:** 2026-11-18 · **Branch audited:** `future-updates` · **Target:**
`main`, tag `v1.0.0`.

This is the single ordered plan for everything still standing between the
current branch and a public 1.0.0. It was built by reading `docs/`,
`Releases/`, `tasks/`, `manually/`, the CI workflows and the release scripts,
and by diffing what those documents claim against what the code now does.

It does **not** replace the sources of truth:

| Question | Source of truth |
|---|---|
| Is a task done? | `tasks/README.md`, then the phase file |
| What can only the owner do? | `manually/README.md` (M-01…M-17) |
| What ships in 1.0? | `release/tools.json`, `Releases/v1.0.0/release-notes.md` |
| How is a release cut? | `Releases/README.md` |

## How to read this

**Type**

- **DEV** — code, tests or CI in this repository.
- **DESIGN** — a UI/UX or copy decision that needs a mock/word before code.
- **DOCS** — documentation accuracy only.
- **OPS** — accounts, infrastructure, DNS, keys, deploys.
- **OWNER** — a physical device, a store/billing account, a real token, or a
  public action only the owner can take (already drafted in `manually/`).
- **DECISION** — a product/business choice that blocks the item below it.

**Blocks 1.0**

- **YES** — the release cannot ship without it.
- **SOFT** — a feature can ship dark, but a claim in the listing/release notes
  must change if it is skipped.
- **NO** — post-1.0 work, tracked so it is not lost.

Status is left out of the tables on purpose: the task tracker owns status.
Everything below is outstanding unless it appears under **Already done**.

---

## Track 0 — Already done (recorded, don't redo)

These were completed in this workspace and are recorded here so the plan does
not re-open them.

### 2026-11-18, current verification

`future-updates` contains `origin/develop` (merge commit `795258b`) and is 9
commits ahead of it. A1 and A2 are complete. The follow-up commit
`4712eee` is pushed to `origin/future-updates`; A3's PR is still not open
because the configured GitHub CLI credential is invalid and no authenticated
browser session is available.
Flutter analysis is clean; `flutter test` passes (1,713 passed, 29 skipped),
including the 50,000-line log case. Backend tests pass (403); the runtime audit
is clean, with four moderate development-tool findings in `osv-scanner.toml`.
Website `npm run check` passes (467 unit tests and production build); Playwright
e2e passes (202 tests). The default Turbopack build failed to bind a helper
process, so the package build script now selects webpack explicitly. Webpack
emits a non-blocking package-version import warning in
`src/error-reporting/config.ts`.

### 2026-11-18, second pass

| ID | Item | Evidence |
|---|---|---|
| A1 | `origin/develop` merged into `future-updates` (12 commits: go_router 18.1.4, flutter_local_notifications 23.0.2, dotenv, c8 12, action bumps); no conflicts | merge commit on `future-updates` |
| A2 | Full re-run on the merged result: Flutter analyze clean; Flutter tests 1,713 passing / 29 skipped; backend 403 passing; web check 467 tests + production build green; Playwright e2e 202 passing | current verification above |
| B1 | `JobTrigger-Web/package-lock.json` added to the OSV scan | `.github/workflows/security.yml` |
| B2 | Website CI now audits runtime dependencies (`--audit-level=critical`) and prints the rest | `.github/workflows/web-ci.yml` |
| B3 | The `picomatch`/`minimatch`/`glob` advisories are reviewed and suppressed **with reasons and an expiry** in `osv-scanner.toml`; the scan fails again on 2027-01-31 | `osv-scanner.toml`, `docs/deployment.md` |
| B11 | Backend runtime audit is 0 (`npm audit --omit=dev`); the four remaining moderates are c8 test tooling only | `npm audit` |
| C3 | Support → "Your reports" now has pull-to-refresh, with a widget test that proves the status change arrives | `support_screen.dart`, `support_screen_test.dart` |
| I1 | Duplicate M-11 split: the Phase 25 iPhone pass is now `M-18`, indexed in `manually/README.md` | `manually/M-18-support-tickets-iphone.md` |
| I2 | M-05 removed from the active manual table and recorded under "Resolved" | `manually/README.md` |
| — | New finding fixed: `JobTrigger-Web` was red on `develop` at `prettier --check` for 5 files | `JobTrigger-Web` formatting commit |

### 2026-11-18, first pass

| Item | Evidence |
|---|---|
| P24-05 shared server/credential header on 31 tool screens + 8 widget tests | `4a70209` |
| URL-keyed Jenkins screens return Home on server switch (AUD-45 safe) | `5522268` |
| Backend ticket-scrubber fixture no longer trips the secret guard (`npm test` 403 passing) | `dda711a` |
| Pre-release checklist test count refreshed to 1,712 | `df1ad81` |
| `tasks/README.md` Phase 24 marked done with P24-05 | this branch |
| `docs/user-stories/README.md` GH/SQ/WEB/SUB epic statuses corrected | this branch |
| `docs/deployment.md` stale "artwork still open" corrected | this branch |
| `docs/future-tools.md` T-072 "second release" corrected (SonarQube ships in 1.0) | this branch |
| `docs/user-stories/shared/09-non-functional-security.md` NFR-SEC-06 marked implemented | this branch |
| `docs/subscription/04-email-and-analytics.md` status corrected (built, not "waiting for approval") | this branch |
| `docs/subscription/02-business-model.md` website checkout corrected (Paddle, built in Phase 20) | this branch |
| `docs/market/competitive-analysis.md` GH/SQ/web rows refreshed | this branch |

---

## Track A — Freeze, merge and tag (7 items)

| ID | Item | Type | Owner | Blocks |
|---|---|---|---|---|
| A1 | Merge `origin/develop` into `future-updates`; current status: complete (9 commits ahead, 0 behind; merge commit `795258b`) | DEV | agent | YES |
| A2 | Re-run **everything** on the merged result: `flutter analyze`, full `flutter test`, backend `npm test`, web `npm run check` + `vitest`; current status: complete, see current verification above | DEV | agent | YES |
| A3 | Follow-up commit `4712eee` is pushed; open the PR into `develop` when GitHub authentication is restored | DEV | owner approves | YES |
| A4 | Cut `release/v1.0.0` from `develop`; feature freeze (bug fixes only, cherry-picked) | OPS | owner | YES |
| A5 | Bump `pubspec.yaml` to `1.0.0+N` (the store build number, not the P24 footer) | DEV | agent | YES |
| A6 | Fill `JobTrigger-Frontend/config/prod.json`: production `https://` backend URL plus the **public** Sentry/RevenueCat keys (never committed) | OPS | owner | YES |
| A7 | At tag time: refresh `Releases/v1.0.0/deployment-log.md` (base SHA `9b87d10` and the 2026-11-17 dates are stale), then tag and merge `release/v1.0.0` → `main` → back to `develop` | OPS | owner | YES |

---

## Track B — Engineering quality and security (11 items)

| ID | Item | Type | Owner | Blocks |
|---|---|---|---|---|
| B1 | Add `JobTrigger-Web/package-lock.json` to the OSV scan; current status: complete | DEV | agent | YES |
| B2 | Add an npm audit runtime gate to website CI; current status: complete | DEV | agent | YES |
| B3 | Document expiring, reasoned exceptions for the reviewed build/test-tool findings; current status: complete in `osv-scanner.toml` (revisit before 2027-01-31) | DEV | agent | YES |
| B4 | Turn on branch protection for `develop` and `main` with every required check (`analyze-and-test`, `build-android`, `build-ios`, `test`, `secrets`, `dependencies`, web `check`) | OPS | owner | SOFT |
| B5 | Release-diff gitleaks scan: no findings after documenting the existing synthetic test-token fingerprint in `.gitleaksignore`; rerun on the final release branch before tagging | DEV | agent | YES |
| B6 | Confirm the 50,000-line log host test (passed in A2) and the fixture-Jenkins e2e still pass on the release branch | DEV | agent | YES |
| B7 | Reconcile `flutter pub outdated`: 40 packages locked older, 11 constrained older. Schedule the refresh **after** 1.0 (a lockfile churn during freeze is risk without release value) | DEV | agent | NO |
| B8 | Wire the e2e fixture suite into CI (`docs/integration-testing.md` says "not run in CI … future work") — post-1.0, needs Docker on the runner | DEV | agent | NO |
| B9 | Revisit native crash handling (`enableNativeCrashHandling: false`) once a native scrubber exists — deliberately off for 1.0 | DEV | agent | NO |
| B10 | Re-check `workmanager`'s temp `wm_execute_task_marker` file on its next upgrade (open audit note) | DEV | agent | NO |
| B11 | Confirm backend runtime `npm audit --omit=dev` is still 0; full audit reports four moderate development-tool findings documented in `osv-scanner.toml` | DEV | agent | YES |
| B12 | De-flake `JobTrigger-Web/src/features/servers/reveal-token.test.tsx`: it failed once on a cold full-suite run, then passed alone and on a warm re-run | DEV | agent | NO |

---

## Track C — Design and UX (11 items)

| ID | Item | Type | Owner | Blocks |
|---|---|---|---|---|
| C1 | Decision: keep the credential context strip above the back row; shared component documentation now describes that placement | DESIGN | agent | YES |
| C2 | Use the documented Profile decision (`Version 1.0.0`, without build number) consistently; App Info now matches | DESIGN | agent | YES |
| C3 | Add pull-to-refresh to Support → "Your reports"; current status: complete with widget test | DEV | agent | SOFT |
| C4 | Added a one-line explanation of when to use Jenkins, GitHub Actions, or SonarQube on tool selection | DESIGN | agent | SOFT |
| C5 | Accessibility pass NFR-A11Y-01/02/03: semantic labels on icon-only actions, 200% text scale, focus order on the four tab roots | DEV | agent | YES |
| C6 | Re-check contrast in both themes after the P24 work (text ≥4.5:1, non-text ≥3:1) — P6-05 was a visual review, never a tool-assisted audit | DEV | agent | YES |
| C7 | Audit loading/empty/error states on every 1.0 screen for the three tools; the rule is UI maps `AppFailure` to copy, never a raw status code | DEV | agent | YES |
| C8 | Layout check at 320pt width and large text on the new credential chip, subscription cards and build-log toolbar | DEV | agent | YES |
| C9 | Keyboard/safe-area check on server form, token wizard, and support composer (iPhone) | OWNER | owner | YES |
| C10 | Updated in-app 1.0 "What's new" with read-only mode, QR pairing, support reporting and server switching | DESIGN | agent | SOFT |
| C11 | Decide whether 1.0 asks for notification permission at all — push ships dark (NR-06b), so a prompt now would be a dead end | DESIGN | owner | SOFT |

---

## Track D — Production backend and infrastructure (10 items)

| ID | Item | Type | Owner | Blocks |
|---|---|---|---|---|
| D1 | Approve the Render deployment plan (`docs/deployment-render.md` is still "plan only, on hold") and resolve its five `(check)` unknowns: Singapore region, deploy-after-checks, `TRUST_PROXY=1`, port 5001, Render Shell/one-off jobs | DECISION | owner | YES |
| D2 | Create the **separate** `jobtrigger-prod` Atlas project: paid tier with backups matching `backupRetention`, same region as the host, least-privilege DB user, host-IP-only network access | OPS | owner | YES |
| D3 | Deploy the backend; `/healthz` returns 200 over public HTTPS, `NODE_ENV=production`, dev CORS origins removed | OPS | owner | YES |
| D4 | DNS + TLS for `api.jobtrigger.app` (or the chosen hostname) | OPS | owner | YES |
| D5 | Set `CREDENTIALS_ENCRYPTION_KEY` in the host's secret manager, take a backup, then run `npm run encrypt-credentials -- --dry-run` followed by the real run (PE-30/PE-31) | OPS | owner | YES |
| D6 | Seed AppInfo with the real `SITE_URL` so privacy/terms links resolve for store review (PE-01) — a review-blocking blank page otherwise | OPS | owner | YES |
| D7 | Backups + a **restore drill** actually performed and timed, not just configured | OPS | owner | YES |
| D8 | Crash-reporting host decision is already GlitchTip (Sentry-compatible); the existing deployment docs specify the production endpoint still needs configuration | DECISION | agent | SOFT |
| D9 | Put the three DSNs in each `.env` and confirm a scrubbed test crash arrives from the physical iPhone over Wi-Fi (PE-19d/PE-19e, M-07) | OWNER | owner | SOFT |
| D10 | Configure production alerts (`/metrics`, error rate, disk, DB connections) and re-check the rate limits under the proxy (`TRUST_PROXY`) | OPS | owner | SOFT |

---

## Track E — Store submission (10 items)

| ID | Item | Type | Owner | Blocks |
|---|---|---|---|---|
| E1 | Apple Developer account active, iOS Distribution certificate + provisioning profiles created (automatic signing via Fastlane is fine) | OPS | owner | YES |
| E2 | Android upload key + `key.properties` created and kept out of the repo (Play App Signing handles the rest after the first upload) | OPS | owner | YES |
| E3 | M-12: store text, App Store privacy answers, Play Data safety, App Review notes and demo walkthrough, and the **production review account** | OWNER | owner | YES |
| E4 | Re-check `ios/Runner/PrivacyInfo.xcprivacy` against the App Store answers before upload (User Defaults, File Timestamp, System Boot Time reasons) | OWNER | owner | YES |
| E5 | Final screenshot verification: 7 iPhone 6.9" (1320×2868, no alpha) and 7 Android (1080×2160, 2:1), matching what 1.0 actually shows | OWNER | owner | YES |
| E6 | Upload to TestFlight internal testers (M-08) | OPS | owner | YES |
| E7 | Upload to Play internal testing (M-09) | OPS | owner | YES |
| E8 | Dogfood window on real devices with the production backend (M-10); file and fix anything it finds before promotion | OWNER | owner | YES |
| E9 | Public release on both stores (M-11), keeping the SwiftUI app archived for rollback | OWNER | owner | YES |
| E10 | Confirm the listings mention only Jenkins, GitHub Actions and SonarQube — no GitLab CI or CircleCI keywords | OWNER | owner | YES |

---

## Track F — Website go-live (7 items)

| ID | Item | Type | Owner | Blocks |
|---|---|---|---|---|
| F1 | Connect `JobTrigger-Web` to Vercel, set the environment variables (session secret, backend URL, public keys), attach the domain | OPS | owner | SOFT |
| F2 | Fill `site-details.ts` — company name, privacy and security emails, reply days, backup retention, last-updated date; `launch-readiness.test.ts` lists what is missing (PE-03) | OWNER | owner | YES |
| F3 | Point `JOBTRIGGER_BACKEND_URL` at the production backend so the setup portal works for real users | OPS | owner | YES |
| F4 | Set `storeLinks` in `site-links.ts` and add the QR code once both listings are live (P15-24) | OWNER | owner | NO |
| F5 | Re-run `npm run check` and `npm run e2e` on the release branch; there is no GitHub Actions check for the site, so this is the merge gate | DEV | agent | YES |
| F6 | Verify the CSP exception is scoped to `/account/billing` only, and that Paddle's script is loaded nowhere else | DEV | agent | YES |
| F7 | Verify every "Coming soon" state is correct for 1.0 (GitLab CI, CircleCI, billing if it ships off) and that no page promises push notifications | DEV | agent | YES |

---

## Track G — Billing (7 items, only if Pro launches with 1.0)

| ID | Item | Type | Owner | Blocks |
|---|---|---|---|---|
| G1 | Decision: billing ships off in 1.0; matches the existing release notes and dark launch configuration | DECISION | agent | YES |
| G2 | P20-40 App Store Connect: Paid Apps agreement, tax, banking, two subscription products with the 7-day trial, Small Business Program enrolment | OPS | owner | SOFT |
| G3 | P20-41 Play Console payments profile, base plans, trial | OPS | owner | SOFT |
| G4 | P20-42 RevenueCat: project, both apps, entitlement, offering, webhook secret, sandbox testers | OPS | owner | SOFT |
| G5 | P20-85 Paddle sandbox: product, prices, approved domain, webhook, client token | OPS | owner | SOFT |
| G6 | P20-51/52 sandbox purchase pass on iPhone and Android: buy, trial, renew, cancel, restore, cross-store transfer (P20-03) | OWNER | owner | SOFT |
| G7 | Check current App Review rules **before** any iOS screen points at the website checkout; then flip `BILLING_ENABLED`, verify pricing, and add the changelog entry (P20-62) | DECISION | owner | SOFT |

---

## Track H — Device verification matrix (15 items, all `manually/`)

These are the "done-unverified" items. Most are one iPhone pass; group them so
the phone is only set up once.

| ID | Item | Type | Owner | Blocks |
|---|---|---|---|---|
| H1 | M-01: kill-and-relaunch on the physical iPhone, still signed in | OWNER | owner | YES |
| H2 | M-03 / P10-14: a wrong SonarQube token returns a SonarQube 401 and never touches Jenkins or the backend session | OWNER | owner | YES |
| H3 | M-03 / P10-15 + M-04: full SonarQube real-server pass on the iPhone, including a SonarCloud account/org | OWNER | owner | YES |
| H4 | M-06 / P8-26: a GitHub 401 is isolated the same way | OWNER | owner | YES |
| H5 | M-06 / P8-27 + PE-42: full `NFR-TEST-03` pass with a fine-grained PAT | OWNER | owner | YES |
| H6 | PE-41: live proof a GitHub token never reaches Jenkins or the backend | OWNER | owner | YES |
| H7 | NR-01: log folding on the iPhone | OWNER | owner | YES |
| H8 | NR-02: the unified dashboard on the iPhone, with all three tools configured | OWNER | owner | YES |
| H9 | PI-01: read-only mode; PI-02: two-step confirm before a destructive action | OWNER | owner | YES |
| H10 | P24-05: the new header on all three tools, long server names, and switching servers from each drill-down screen | OWNER | owner | YES |
| H11 | M-11 (Phase 25): send a ticket from the iPhone, see "Report sent", see it under "Your reports", open Support from App Info | OWNER | owner | YES |
| H12 | P10-17…P10-24: unverified SonarQube API shapes, `__me__` assignee, CE permission, branch/PR picker (Developer Edition), widget, linked job | OWNER | owner | SOFT |
| H13 | P11-24/25/26: background notification delivery, biometric lock, home-screen widget (App Group must exist on team `QRCA2Z2HYQ`) | OWNER | owner | SOFT |
| H14 | NFR-TEST-02: two **differently configured** Jenkins servers (CSRF on/off, folder layout) | OWNER | owner | YES |
| H15 | M-02 / P5-13 / P11-03: Android on-device log jank — **on hold, no Android device**; the 50,000-line host test is the stand-in | OWNER | owner | SOFT |

---

## Track I — Documentation truth (8 items)

| ID | Item | Type | Owner | Blocks |
|---|---|---|---|---|
| I1 | Resolve the duplicate M-11 by renumbering the Phase 25 draft (M-18) and indexing it; current status: complete | DOCS | agent | YES |
| I2 | Remove completed M-05 from the active table; current status: complete, retained under Resolved | DOCS | agent | YES |
| I3 | Refresh the collection inventory and remove obsolete local MongoDB drop instructions; complete | DOCS | agent | SOFT |
| I4 | Clarify the backend bind address (`0.0.0.0`) and loopback/LAN access; complete | DOCS | agent | SOFT |
| I5 | Recount Phase 20; 42/57 checkboxes complete, 15 open; recorded in the phase file | DOCS | agent | SOFT |
| I6 | Refresh the root README feature and release status summary; complete | DOCS | agent | SOFT |
| I7 | Renamed the internal backend package to `jobtrigger-backend` and added a descriptive package summary | DOCS | agent | NO |
| I8 | Re-read release notes against merged code; added Support and account/server context highlights | DOCS | agent | YES |

---

## Track J — Explicitly not in 1.0 (do not start)

Recorded so scope creep is visible, not to plan it.

| Item | Where it is tracked | Earliest |
|---|---|---|
| NR-06b app half + server-side push trigger (needs `firebase_messaging`, Firebase config files, and the backend polling Jenkins) | `tasks/phase-22-next-release.md`, M-16 | after 1.0, needs approval |
| GitLab CI and CircleCI | `release/tools.json` | 1.3.0 |
| The other 161 tools in the catalogue | `docs/future-tools.md` | one per release |
| 146 unpromoted product proposals (IMP-01…156 minus PI-01…PI-10) | `docs/product-improvements.md` | unscheduled |
| Team plan / shared workspaces | `docs/subscription/` §10 | Phase 21+ |
| Multi-account switching in the app | `tasks/backlog.md` | unscheduled |
| iPad, Apple Watch, localisation, audit log, AI failure summaries, flaky-test detection | `docs/implemented/improvement-plan.md` "Later" | unscheduled |
| Production email provider, ops `/metrics` dashboard, integration tests in CI, native crash handling | `docs/subscription/04`, `docs/integration-testing.md`, `docs/error-reporting.md` | post-1.0 |

---

## Suggested order

1. **Unblock the branch:** A1 → A2 → A3 (merge, full re-run, PR).
2. **Cheap gaps while CI runs:** B1, B2, B11, I1, I2, C3.
3. **Decisions the owner must make before design freezes:** C1, C2, C4, G1, D8.
4. **Code freeze:** A4 → A5 → A6, then B5/B6/F5/F6/F7 as the last green gates.
5. **Infrastructure:** D1 → D2 → D3 → D4 → D5 → D6 → D7.
6. **One iPhone session covering H1…H14 and C9** (M-03/M-04/M-06 tokens prepared first).
7. **Store path:** E1/E2 → E3/E4/E5 → E6/E7 → E8 → E9/E10.
8. **Website:** F1 → F2 → F3 → F4.
9. **Tag:** A7, after every YES above is green.

Nothing in this plan is a substitute for the per-task approval rule in
`CLAUDE.md` §9: each item that touches code still gets a short plan before it
is built.
