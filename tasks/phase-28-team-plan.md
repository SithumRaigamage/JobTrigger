# Phase 28 — Team plan (US-SUB-11), release 1.1

Source: owner decision 2026-11-20 (pre-release follow-up). Story and
criteria: `docs/user-stories/billing/18-subscriptions.md` US-SUB-11; design:
`docs/design/US-SUB-11-team-plan.md`. Ships in **1.1**, after the `v1.0.0`
tag; off unless `TEAM_PLAN_ENABLED=true`.

- [x] P28-01 Backend: flag, Team model, service, routes, entitlements,
      Paddle per-seat checkout, seat change and webhook branch, invite mail,
      shared Jenkins servers, account-deletion rules (AC1–AC11).
- [x] P28-02 Website: `/account/team`, team billing on `/account/billing`,
      `/team/join`, pricing card (AC12–AC15).
- [x] P28-03 App: team plan copy on the subscription screen, Team servers
      in Settings (AC16–AC17).
- [ ] P28-04 **MANUAL (owner, M-23):** Paddle team prices (monthly/yearly, per seat) and
      `TEAM_PLAN_ENABLED` in staging, then a sandbox purchase (M-23).

## Evidence (2026-11-20)

- P28-01 backend: `lib/team.js`, `models/Team.js`, `controllers/teamController.js`,
  `routes/teamRoutes.js`, entitlements and Paddle webhook branch;
  `test/team.test.js` 20 tests (AC1–AC11).
- P28-02 website: `src/features/team/`, `src/server/team-api.ts`,
  `/account/team`, `/account/team/join`, billing team section, pricing card;
  `team-api.test.ts`, `actions.test.ts`, `team.test.tsx`,
  `team-billing.test.tsx`, pricing and account tests (30 tests, AC12–AC15).
- P28-03 app: `TeamServersRepositoryImpl`, `TeamServersNotifier`,
  `TeamServersSection`, active-server restore/fallback, subscription copy;
  `team_servers_repository_test.dart`, `team_plan_app_test.dart` (15 tests,
  AC16–AC17).
- Whole suite on the branch: Flutter 1,762 passed / 29 skipped, analyze and
  format clean; backend 456 passing; website `npm run check` 512, Playwright 202.

