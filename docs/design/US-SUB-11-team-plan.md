# Design note — US-SUB-11 Team plan (release 1.0.1)

Story and acceptance criteria: `docs/user-stories/billing/18-subscriptions.md`
(US-SUB-11). Owner decisions, 2026-11-20: Paddle on the website
only, $6.99 per seat per month ($69.90 per seat per year), 2–100 seats.
Owner decision 2026-11-21: release **1.0.1** (was 1.1); 1.0.0 ships with
`TEAM_PLAN_ENABLED=false`.

## Backend

- **Flag** `TEAM_PLAN_ENABLED` (`config/env.js`, default off). `middleware/teamOnly.js`
  answers 404 when off, like `sandboxOnly`.
- **Model** `models/Team.js`: `name`, `ownerId`, `seats` (2–100),
  `members[{ userId, joinedAt }]` (the owner is a member), `invites[{ email,
  tokenHash, expiresAt, invitedBy }]`, `sharedServers[{ tool:'jenkins',
  credentialId, sharedAt }]`, `billing{ plan, status, periodEnd, willRenew,
  period, paddleSubscriptionId, paddleCustomerId, eventAt }`. Unique index on
  `members.userId` keeps "one team per user" in the database too.
- **Service** `lib/team.js`: create, invite (seat check), accept, remove,
  leave, setSeats, share/unshare, delete, `activeTeamFor(userId)`,
  `teamIsPro(team, now)` (same statuses as `billing/entitlements.js`).
- **Entitlements** `billing/entitlements.js`: when the user's own
  subscription isn't Pro, an active team makes them Pro with `source:'team'`
  and `team:{ id, name, role }` in the response. Limits and the locked guard
  read entitlements, so they follow automatically.
- **Paddle** `billing/paddleClient.js`: `createTransaction` takes `quantity`
  and `customData`; new `updateSubscriptionQuantity`. Prices from
  `PADDLE_PRICE_TEAM_MONTHLY` / `PADDLE_PRICE_TEAM_YEARLY`. The webhook
  routes events whose `custom_data.teamId` (or known team subscription id)
  matches a team to the team branch; personal events are unchanged.
- **Routes** `/api/team` (auth + flag): `GET /` (my team or null), `POST /`
  create, `DELETE /`, `POST /invites`, `DELETE /invites/:inviteId`,
  `POST /join`, `DELETE /members/:userId`, `POST /leave`, `PUT /seats`,
  `POST /checkout`, `GET /servers`, `POST /servers`, `DELETE /servers/:id`,
  `GET /servers/jenkins/:id/secret`.
- **Mail** `emails/team.js`: the invite, with one link to the website.
- **Account deletion** (`authController.deleteAccount`): blocked while the
  user owns a team; a member's membership is removed.

## Website

- `/account/team` (portal): server component reads `GET /api/team`; server
  actions call the routes above. Owner: create, seats used/total, members,
  invites, invite form, remove, cancel, share/unshare (own Jenkins servers
  from the credentials list), delete. Member: team, owner, leave.
- `/account/billing`: Team section — seats stepper, monthly/yearly, total
  price, "Buy for the team" (Paddle.js, same CSP-scoped page), "Change seats".
- `/account/team/join`: reads `token`, requires sign-in (redirect back after), posts
  `POST /api/team/join`, shows each refusal.
- Pricing: Team card when `statusOf("team-plan") === "live"` (feature status
  `soon` until 1.0.1 ships).

## App

- `SubscriptionStatus` gains `team` (`name`, `role`); the subscription
  screen shows the team copy and hides purchase when `source == team`.
- `TeamServersRepository` (`GET /api/team/servers`, secret through
  `/api/team/servers/jenkins/:id/secret` with the existing
  `CredentialSecrets`), `TeamServersNotifier`, a "Team servers" section in
  Settings with "Use". Active team servers get id `team:<credentialId>` so
  they never collide with the user's own; `ActiveServerNotifier` restores one
  from the team list on restart and falls back when it is gone.
- No change to the shared credential CRUD every tool uses (CLAUDE.md §11).

## Not in this story

Roles beyond owner/member, sharing GitHub/SonarQube tokens, buying a team in
the app stores, SSO.
