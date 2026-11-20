# Epic: SUB — Subscriptions (Free + Pro)

This epic is **new scope** proposed on 2026-11-12. It is **not promoted**
until the owner approves P20-00 in
[`tasks/phase-20-subscriptions.md`](../../../tasks/phase-20-subscriptions.md).
Background: [`docs/subscription/`](../../subscription/README.md).

**Why it exists.** JobTrigger has an ongoing cost competitors without a
backend don't (accounts, credential sync, the setup portal). A Free tier
keeps it competitive with free single-tool apps; Pro charges for what
only JobTrigger does — several tools, several servers, and the power
features.

"Must" here means *needed to charge money correctly and pass store
review*. "Should" means high value for conversion or trust. "Could" is
nice-to-have.

**New technology (needs approval):** `purchases_flutter` (RevenueCat) in
the app. No new backend or website dependency in this epic.

**New backend work (backend track, needs per-item approval):**
`GET /api/subscription`, `POST /api/subscription/refresh`,
`POST /api/subscription/primary/:id`, `POST /api/billing/revenuecat`,
the `Subscription` and `BillingEvent` collections, and the plan check in
the credential factory. Specified in
[`billing-integration.md`](../../subscription/docs/billing-integration.md) §3.

New failure kind: **`PlanLimitFailure(limit)`**, added as a new case of
`AppFailure` (CLAUDE.md §11 — existing copy untouched). Copy: "Your plan
allows *n* saved server(s). Upgrade to Pro to add more." (wording varies
by `limit`). A user cancelling the store sheet is not a failure.

---

### US-SUB-01 — See my plan

**Priority:** Must · **Dependencies:** US-AUTH-02

As a signed-in user
I want to see which plan I'm on and when it renews or ends
So that I know what I'm paying for

**Acceptance Criteria**
- Scenario: Pro, renewing — Given an active yearly plan, When I open
  Profile → Subscription, Then I see "Pro · Yearly", "Renews on <date>",
  and where it was bought (App Store / Google Play / website).
- Scenario: cancelled but paid up — Then I see "Pro until <date>" and no
  renewal date.
- Scenario: Free — Then I see "Free" and an "Upgrade to Pro" action.
- Scenario: offline — Given no connection, Then the last known plan is
  shown with "Last checked <time>", not an error page (`NetworkFailure`
  only as an inline note).

**Security & Privacy Notes** — the plan comes from the backend, not the
device; a modified app can't make the backend accept extra servers.

---

### US-SUB-02 — Upgrade to Pro in the app

**Priority:** Must · **Dependencies:** US-SUB-01

As a Free user
I want to buy Pro monthly or yearly from the app
So that I can unlock every tool and unlimited servers

**Acceptance Criteria**
- Scenario: paywall content — the paywall shows both plans with the
  store's localised price and period, the yearly trial ("7 days free,
  then <price>/year"), auto-renew wording, Terms and Privacy links, and
  "Restore purchases".
- Scenario: purchase — When I buy, Then the store sheet appears; after
  it succeeds, Pro features unlock within a few seconds without
  restarting the app.
- Scenario: cancelled sheet — When I close the store sheet, Then nothing
  changes and no error is shown.
- Scenario: purchase failed — Then I see the store's reason and can try
  again; I'm never charged without Pro being granted (the backend
  re-reads RevenueCat on `POST /refresh`).
- Scenario: context — When the paywall opens because I hit a limit, Then
  its headline names that limit (e.g. "Add more servers with Pro").

**UI / Design Notes** — Phase 14 design system; yearly pre-selected;
one primary button; no dark patterns (no hidden close button, no
countdown timers).

---

### US-SUB-03 — Restore purchases

**Priority:** Must (store-required) · **Dependencies:** US-SUB-02

As a user on a new phone or after reinstalling
I want to restore my purchase
So that I get Pro back without paying twice

**Acceptance Criteria**
- Scenario: restored — When I tap Restore, Then my active purchase is
  linked to my signed-in account and Pro unlocks.
- Scenario: nothing to restore — Then I see "No active subscription
  found for this store account."
- Scenario: purchase belongs to another JobTrigger account — Then the
  purchase follows the RevenueCat transfer rule chosen at P20-00, and the
  message says which account now has Pro.

---

### US-SUB-04 — Server limits on Free

**Priority:** Must · **Dependencies:** US-CRED-01, US-GH-CRED-01, US-SQ-CRED-01

As a Free user
I want clear limits when adding servers
So that I understand why I can't add another and what to do

**Acceptance Criteria**
- Scenario: first server — Given no saved servers, When I add one of any
  tool, Then it saves as today.
- Scenario: second server — Given one saved server, When I try to add
  another (app or website), Then the backend returns `403 PLAN_LIMIT`,
  shown as `PlanLimitFailure` with an "Upgrade" action (app) or "Upgrade
  in the JobTrigger app" (website).
- Scenario: edit and delete — Then editing or deleting my server always
  works, whatever my plan.
- Scenario: bypass attempt — When a client calls the create endpoint
  directly past the limit, Then the backend still refuses.

---

### US-SUB-05 — Downgrade keeps my data

**Priority:** Must · **Dependencies:** US-SUB-04

As a user whose Pro ended
I want my servers kept, not deleted
So that upgrading again puts everything back

**Acceptance Criteria**
- Scenario: locked, not deleted — Given 4 saved servers and Pro ended,
  Then all 4 are listed, 1 usable and 3 shown as locked with a Pro badge.
- Scenario: choose which stays — When I pick a different server to keep
  unlocked, Then it switches, at most once per 24 hours.
- Scenario: re-upgrade — When I buy Pro again, Then all servers unlock at
  once.
- Scenario: Pro-only features — background watches stop being scheduled,
  the widget shows an upgrade message, pins beyond 3 become read-only.

---

### US-SUB-06 — Pro feature gates

**Priority:** Should · **Dependencies:** US-SUB-02

As a Free user
I want to see Pro features marked, not hidden
So that I know what Pro adds

**Acceptance Criteria**
- Scenario: each gate in technical design §4.3 shows a "Pro" badge and
  opens the paywall with the matching reason.
- Scenario: never gated — app lock, sign out everywhere, change password,
  delete account, and core trigger/logs/history work on Free.

---

### US-SUB-07 — Delete account with an active subscription

**Priority:** Must (store-required) · **Dependencies:** US-AUTH-06, US-WEB-21

As a subscriber deleting my account
I want to be told that deletion doesn't cancel billing
So that I'm not charged after leaving

**Acceptance Criteria**
- Scenario: active subscription — Before confirming deletion, Then I see
  "Deleting your account doesn't cancel your subscription. Cancel it in
  <store> first." with a "Manage subscription" link.
- Scenario: deleted — Then the backend deletes my subscription record and
  asks RevenueCat to delete my customer record.

---

### US-SUB-08 — Plan on the website

**Priority:** Should · **Dependencies:** US-WEB-21

As a user on the setup portal
I want to see my plan and limits
So that laptop setup matches what my phone allows

**Acceptance Criteria**
- Scenario: account page shows plan, renewal/end date and "manage in
  App Store / Google Play" instructions.
- Scenario: `/pricing` lists Free vs Pro from one content file, tested.
- Scenario: Terms and Privacy cover auto-renewal, store refunds and
  RevenueCat as a processor.

---

### US-SUB-09 — Billing events stay correct

**Priority:** Must · **Dependencies:** backend track

As the owner
I want renewals, cancellations, refunds and billing issues reflected
automatically
So that nobody keeps Pro unpaid or loses Pro they paid for

**Acceptance Criteria**
- Scenario: renewal / cancellation / expiry / refund / billing issue —
  Then `GET /api/subscription` reflects it within a minute of
  RevenueCat's webhook.
- Scenario: duplicate or out-of-order webhook — Then the stored state
  matches RevenueCat's current subscriber record.
- Scenario: wrong webhook secret — `401`, nothing stored, logged without
  the body.
- Scenario: `BILLING_ENABLED=false` — everyone gets Pro entitlements.

---

### US-SUB-10 — Web checkout

**Priority:** Could · Buy Pro on the website through a merchant of
record with Sri Lanka payouts. **Status:** built in Phase 20 (P20-83,
Paddle on `/account/billing` only); go-live is the owner's Paddle setup
(P20-85, M-15). Earlier versions of this file listed it as deferred.

### US-SUB-11 — Team plan

> **Status: built 2026-11-20 for release 1.1, all 17 criteria ticked against code and tests** (owner decision 2026-11-20:
> build now on its own branch, ship after the `v1.0.0` tag; billed per seat on
> the website through Paddle only; **$6.99 per seat per month**). Off unless
> `TEAM_PLAN_ENABLED=true`. Design note: [`docs/design/US-SUB-11-team-plan.md`](../../design/US-SUB-11-team-plan.md).

**Priority:** Could · **Release:** 1.1 · **Task:** P28-01 (`tasks/phase-28-team-plan.md`)

As the person who looks after CI for a small team
I want to buy JobTrigger Pro for my team and share our Jenkins servers once
So that everyone gets Pro and the same servers without passing tokens around

**Acceptance Criteria**

*Backend (`JobTrigger-Backend`)*
- [x] AC1 Off by default. Without `TEAM_PLAN_ENABLED=true` every
      `/api/team` route answers 404 and nothing about teams appears in any
      other response.
- [x] AC2 Create. A signed-in user who is in no team creates one (name 1–60
      characters) and becomes its owner. A user is in at most one team.
- [x] AC3 Price and seats. $6.99 per seat per month or $69.90 per seat per
      year (two months free), 2 to 100 seats. Checkout is a Paddle
      transaction created by the backend with `quantity = seats` and
      `custom_data = { teamId }`; only the owner can buy, on the website.
- [x] AC4 Billing events. Paddle subscription events carrying a `teamId`
      update the team's status, period end and seats (from the item
      quantity), once per event, never with an older event, and never touch
      anyone's personal `web` subscription.
- [x] AC5 Invite. The owner invites by email while members + pending invites
      < seats. The invite expires in 7 days, its token is stored only as a
      hash, and the email links to `/account/team/join?token=…`. Inviting the same
      address again replaces the old invite.
- [x] AC6 Accept. A signed-in user whose account email matches the invite
      (case-insensitive) joins with the token. Refused, with a reason, when
      the token is unknown or expired, the email doesn't match, the user is
      already in a team, or the seats are full.
- [x] AC7 Pro for members. While the team's subscription is in a Pro state
      and inside its period, the owner and every member have Pro with
      source `team`; a member's own Pro (store, web, grant, student) still
      shows as their source when they have one.
- [x] AC8 Leave and remove. The owner removes a member or cancels an invite;
      a member leaves. The owner can't leave (they delete the team). Someone
      who loses the team falls back to their own plan, with the
      locked-server guard and nothing deleted.
- [x] AC9 Change seats. The owner sets 2–100 seats, never below members +
      pending invites; the backend updates the Paddle subscription's
      quantity (prorated) and the webhook confirms it.
- [x] AC10 Shared Jenkins servers. The owner shares their own Jenkins
      servers with the team. Members of an active team list them masked and
      read a secret only through `GET /api/team/servers/jenkins/:id/secret`
      (rate-limited, `no-store`). Unsharing, removal, or the team lapsing
      revokes access at once. GitHub and SonarQube tokens are personal and
      are not shareable.
- [x] AC11 Delete. The owner deletes the team only when its subscription no
      longer renews; members then fall back to their own plan. Deleting the
      owner's account is blocked while they own a team; a member's account
      deletion removes the membership.

*Website (`JobTrigger-Web`)*
- [x] AC12 Team page. `/account/team` lets the owner create the team, see
      seats used and total, members and pending invites, invite, remove,
      cancel an invite, and share or unshare their Jenkins servers; a member
      sees the team and can leave. Shows "not available" when the backend
      has teams off.
- [x] AC13 Team billing. `/account/billing` (the only page with Paddle's
      CSP exception) has a Team section: seats and monthly/yearly with the
      price worked out, checkout through Paddle, and changing seats.
- [x] AC14 Join. `/account/team/join?token=…` accepts an invite after sign-in and
      shows each refusal from AC6 in plain words.
- [x] AC15 Pricing. The pricing page shows a Team card ($6.99 per seat per
      month, from 2 seats, bought on the website) only when the `team-plan`
      feature is live.

*App (`JobTrigger-Frontend`)*
- [x] AC16 Plan screen. When Pro comes from a team, the subscription screen
      says "Pro through <team name>" and "Your team's owner manages this
      plan." No in-app purchase is offered and nothing links to the website
      checkout (store rules).
- [x] AC17 Team servers. Settings lists the team's shared Jenkins servers
      (name, URL, shared by) under "Team servers". "Use" makes one the
      active server (its secret is fetched through the team endpoint and
      kept in secure storage like the user's own). Team servers can't be
      edited or deleted in the app; one that stops being shared disappears
      and the active server falls back to the user's own.

**Layer impact:** backend, website and app — all three (see the criteria).

**Tests needed**
- Backend: flag off → 404; create/one-team rule; invite seat limit, expiry,
  hashed token, replace; accept refusals; entitlement source `team` and
  personal-source precedence; Paddle team checkout body; webhook team
  branch (idempotent, stale, seats from quantity, personal `web` untouched);
  seat change bounds and Paddle call; shared-server listing masked, secret
  only for active members, revocation; delete rules; account-deletion
  rules.
- Website: team page states (none, owner, member, off); actions validate
  input; join page refusals; billing team section price maths; pricing card
  gated by feature status.
- App: subscription screen team copy and no purchase; team servers list,
  Use → active server, not editable, disappears when unshared.

**Security & Privacy Notes**
- Secrets are shared by reference: members fetch the owner's credential
  through the team endpoint, so revocation is immediate; nothing is copied.
- Invite tokens: 32 random bytes, only the SHA-256 is stored, 7-day expiry,
  single use.
- The team name and member emails are visible to members of that team only.
