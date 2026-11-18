# JobTrigger 1.0.0 — release workplan

**Created:** 2026-11-18 · **Branch audited:** `future-updates` (4 commits ahead
of `origin/develop` at the time of writing) · **Target:** `main`, tag `v1.0.0`.

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
| A1 | Merge `origin/develop` into `future-updates` (currently 12 behind) and resolve conflicts by hand | DEV | agent | YES |
| A2 | Re-run **everything** on the merged result: `flutter analyze`, full `flutter test`, backend `npm test`, web `npm run check` + `vitest` (CLAUDE.md §11 — two green branches can fail together) | DEV | agent | YES |
| A3 | Push `future-updates` and open the PR into `develop` with the P24-05/P25/backend-test commits summarised | DEV | owner approves | YES |
| A4 | Cut `release/v1.0.0` from `develop`; feature freeze (bug fixes only, cherry-picked) | OPS | owner | YES |
| A5 | Bump `pubspec.yaml` to `1.0.0+N` (the store build number, not the P24 footer) | DEV | agent | YES |
| A6 | Fill `JobTrigger-Frontend/config/prod.json`: production `https://` backend URL plus the **public** Sentry/RevenueCat keys (never committed) | OPS | owner | YES |
| A7 | At tag time: refresh `Releases/v1.0.0/deployment-log.md` (base SHA `9b87d10` and the 2026-11-17 dates are stale), then tag and merge `release/v1.0.0` → `main` → back to `develop` | OPS | owner | YES |

---

## Track B — Engineering quality and security (11 items)

| ID | Item | Type | Owner | Blocks |
|---|---|---|---|---|
| B1 | Add `JobTrigger-Web/package-lock.json` to the OSV scan in `.github/workflows/security.yml` (today only Frontend + Backend lockfiles are scanned) | DEV | agent | YES |
| B2 | Add an `npm audit --omit=dev` (runtime) gate to `.github/workflows/web-ci.yml`, matching what the backend CI already does | DEV | agent | YES |
| B3 | Write the documented exception for the 7 high `picomatch` advisories (build-time only, via `@sentry/nextjs`/`vite`; installed 4.0.7 is newest and npm proposes no in-range fix) and revisit upstream | DECISION | owner | YES |
| B4 | Turn on branch protection for `develop` and `main` with every required check (`analyze-and-test`, `build-android`, `build-ios`, `test`, `secrets`, `dependencies`, web `check`) | OPS | owner | SOFT |
| B5 | Run `gitleaks` + the full secret scan against the release branch before tagging; confirm no `.env`, `key.properties`, DSN or store key is in the diff | DEV | agent | YES |
| B6 | Confirm the 50,000-line log host test and the 2.5× fixture-Jenkins e2e still pass on the release branch | DEV | agent | YES |
| B7 | Reconcile `flutter pub outdated`: 40 packages locked older, 11 constrained older. Schedule the refresh **after** 1.0 (a lockfile churn during freeze is risk without release value) | DEV | agent | NO |
| B8 | Wire the e2e fixture suite into CI (`docs/integration-testing.md` says "not run in CI … future work") — post-1.0, needs Docker on the runner | DEV | agent | NO |
| B9 | Revisit native crash handling (`enableNativeCrashHandling: false`) once a native scrubber exists — deliberately off for 1.0 | DEV | agent | NO |
| B10 | Re-check `workmanager`'s temp `wm_execute_task_marker` file on its next upgrade (open audit note) | DEV | agent | NO |
| B11 | Confirm backend `npm audit` is still 0 and review any new Dependabot PRs before the freeze | DEV | agent | YES |

---

## Track C — Design and UX (11 items)

| ID | Item | Type | Owner | Blocks |
|---|---|---|---|---|
| C1 | **Decide the drill-down header placement.** The P24-05 chip sits *above* the back button while its doc says "under the back button". Pick one and make all four URL-keyed screens match | DESIGN | owner | YES |
| C2 | **Decide the version string.** Profile shows `Version 1.0.0`, App Info shows `Version 1.0.0 (1)`. Keeping the build number is defensible for support; pin the decision in P24-03 and make both screens agree | DESIGN | owner | YES |
| C3 | Add pull-to-refresh to Support → "Your reports" (it has retry-on-error but no gesture) | DEV | agent | SOFT |
| C4 | **New-user journey gap:** after tool selection nothing explains Jenkins vs GitHub Actions vs SonarQube beyond the cards, and the first-run checklist only counts "Connect tool". Decide whether to add a one-line "which tool do I have?" hint | DESIGN | owner | SOFT |
| C5 | Accessibility pass NFR-A11Y-01/02/03: semantic labels on icon-only actions, 200% text scale, focus order on the four tab roots | DEV | agent | YES |
| C6 | Re-check contrast in both themes after the P24 work (text ≥4.5:1, non-text ≥3:1) — P6-05 was a visual review, never a tool-assisted audit | DEV | agent | YES |
| C7 | Audit loading/empty/error states on every 1.0 screen for the three tools; the rule is UI maps `AppFailure` to copy, never a raw status code | DEV | agent | YES |
| C8 | Layout check at 320pt width and large text on the new credential chip, subscription cards and build-log toolbar | DEV | agent | YES |
| C9 | Keyboard/safe-area check on server form, token wizard, and support composer (iPhone) | OWNER | owner | YES |
| C10 | Write the in-app "What's new" content for 1.0 (dashboard, log folding, QR pairing, support, read-only mode) | DESIGN | agent | SOFT |
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
| D8 | Decide the crash-reporting host: GlitchTip on Render, a hosted Sentry-compatible service, or ship with no DSN | DECISION | owner | SOFT |
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
| G1 | Decide: does 1.0.0 ship with billing **on** or **off**? Off is a supported state (everyone is effectively Pro, `BILLING_ENABLED=false`) but the listing and release notes must not sell Pro | DECISION | owner | YES |
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
| I1 | Resolve the duplicate **M-11**: `manually/M-11-public-release.md` and `manually/M-11-support-tickets-iphone.md` share an id, and `manually/README.md` only lists the first. Renumber the Phase 25 draft (M-18) and add it to the index | DOCS | agent | YES |
| I2 | Remove M-05 (Android screenshots, DONE 2026-11-17) from the *active* table in `manually/README.md` so the open count is honest | DOCS | agent | YES |
| I3 | `docs/database-migrations.md`: the collection table lists only `users`, `jenkinscredentials`, `appinfos` — missing GitHub, SonarQube, billing, tickets, student. Also still shows local `mongo --eval` / `docker compose down -v` although there is no local MongoDB | DOCS | agent | SOFT |
| I4 | `docs/dev-setup.md` contradicts itself on the bind address ("all local interfaces" vs `127.0.0.1`) | DOCS | agent | SOFT |
| I5 | `tasks/phase-20-subscriptions.md` says "41 of 57 tasks done"; re-count against the file before quoting it in release notes | DOCS | agent | SOFT |
| I6 | Root `README.md` project table is stale (flagged in `docs/audit/2026-09-29-workspace-audit.md` §6); refresh before the repo goes public | DOCS | agent | SOFT |
| I7 | Backend package name/description still `lab-trigger-backend` — rename only if it appears in anything user-visible; otherwise document why it stays | DOCS | owner | NO |
| I8 | After the merge, re-read `Releases/v1.0.0/release-notes.md` against the merged code (P25 support, P24 headers, NR-01/02, PI-01/02) and add anything missing | DOCS | agent | YES |

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
