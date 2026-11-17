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
[`03-technical-design.md`](../../subscription/03-technical-design.md) §3.

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

### US-SUB-10 — Web checkout (deferred to Phase 21)

**Priority:** Could · Buy Pro on the website through a merchant of
record with Sri Lanka payouts. Out of this epic; listed so the set is
complete by exclusion.

### US-SUB-11 — Team plan (deferred)

**Priority:** Could · Organisations, shared servers, seats. Out of this
epic (technical design §10).
