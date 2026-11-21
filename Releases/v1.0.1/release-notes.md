# Release Notes — v1.0.1 (planned)

- **Release Version**: v1.0.1
- **Release Date**: not set (after `v1.0.0` is live)
- **Target Branch**: main
- **Supported Tools Manifest**: `release/tools.json` (unchanged from 1.0.0)

## What's Shipping
- **Summary**: turns on the team plan (US-SUB-11). Owner decision
  2026-11-21: the team plan moves from 1.1 to 1.0.1.
- **New Capabilities**:
  - Team plan: Pro per seat ($6.99 per seat per month, $69.90 per seat per
    year, 2–100 seats), bought and managed on the website through Paddle;
    invites; shared Jenkins servers in the app's Settings
    (`docs/user-stories/billing/18-subscriptions.md` US-SUB-11,
    `tasks/phase-28-team-plan.md`).
- **Bug Fixes & Refinements**: none planned yet.

## How it is switched on
The code already ships in 1.0.0, switched off: `TEAM_PLAN_ENABLED=false`
in `render.yaml`, so every `/api/team` route is a 404 and the website shows
"coming in JobTrigger 1.0.1". For 1.0.1:
1. Owner: M-23 — Paddle per-seat prices (`PADDLE_PRICE_TEAM_MONTHLY`,
   `PADDLE_PRICE_TEAM_YEARLY`) and a sandbox purchase.
2. `render.yaml`: `TEAM_PLAN_ENABLED` to `"true"`.
3. Website: `team-plan` in `src/content/feature-status.ts` to `live` (the
   pricing Team card and a changelog line follow from it), and the
   "coming in 1.0.1" copy on `/account/team` goes away with it.
4. App: no change needed; it shows team features when the backend reports a
   team membership.

## Breaking Changes & Deprecations
- None.

## Known Limitations & Scope
- Team billing is on the website only (store rules); the app never links to it.
