# Phase 28 — Team plan (US-SUB-11), release 1.1

Source: owner decision 2026-11-20 (pre-release follow-up). Story and
criteria: `docs/user-stories/billing/18-subscriptions.md` US-SUB-11; design:
`docs/design/US-SUB-11-team-plan.md`. Ships in **1.1**, after the `v1.0.0`
tag; off unless `TEAM_PLAN_ENABLED=true`.

- [ ] P28-01 Backend: flag, Team model, service, routes, entitlements,
      Paddle per-seat checkout, seat change and webhook branch, invite mail,
      shared Jenkins servers, account-deletion rules (AC1–AC11).
- [ ] P28-02 Website: `/account/team`, team billing on `/account/billing`,
      `/team/join`, pricing card (AC12–AC15).
- [ ] P28-03 App: team plan copy on the subscription screen, Team servers
      in Settings (AC16–AC17).
- [ ] P28-04 Owner: Paddle team prices (monthly/yearly, per seat) and
      `TEAM_PLAN_ENABLED` in staging, then a sandbox purchase (M-23).
