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
- [x] Scenario: Pro, renewing — Given an active yearly plan, When I open
  Profile → Subscription, Then I see "Pro · Yearly", "Renews on <date>",
  and where it was bought (App Store / Google Play / website).
  Evidence: `test/presentation/features/subscription/subscription_screen_test.dart` "a store subscription shows its renewal date and links to the store's own management page"; `test/presentation/features/subscription/profile_subscription_test.dart` "with billing available the row shows the plan and opens the Subscription screen".
- [x] Scenario: cancelled but paid up — Then I see "Pro until <date>" and no
  renewal date.
  Evidence: `test/presentation/features/subscription/subscription_screen_test.dart` "a cancelled store subscription says when it ends".
- [x] Scenario: Free — Then I see "Free" and an "Upgrade to Pro" action.
  Evidence: `test/presentation/features/subscription/subscription_screen_test.dart` "Free: names the plan and offers Upgrade and Restore".
- [ ] Scenario: offline — Given no connection, Then the last known plan is
  shown with "Last checked <time>", not an error page (`NetworkFailure`
  only as an inline note).
  Open: partly: offline the last known plan is used, not an error (`test/presentation/features/subscription/entitlements_notifier_test.dart` "a cached plan is used at once, then freshened in the background", "a failed refresh keeps what is shown"), but there is no "Last checked <time>" note.

**Security & Privacy Notes** — the plan comes from the backend, not the
device; a modified app can't make the backend accept extra servers.

---

### US-SUB-02 — Upgrade to Pro in the app

**Priority:** Must · **Dependencies:** US-SUB-01

As a Free user
I want to buy Pro monthly or yearly from the app
So that I can unlock every tool and unlimited servers

**Acceptance Criteria**
- [x] Scenario: paywall content — the paywall shows both plans with the
  store's localised price and period, the yearly trial ("7 days free,
  then <price>/year"), auto-renew wording, Terms and Privacy links, and
  "Restore purchases".
  Evidence: `test/presentation/features/subscription/paywall_screen_test.dart` "shows the store prices, the trial and what it converts to, auto-renew text, Restore and the legal links", "Terms and Privacy open the backend-provided links".
- [x] Scenario: purchase — When I buy, Then the store sheet appears; after
  it succeeds, Pro features unlock within a few seconds without
  restarting the app.
  Evidence: `test/presentation/features/subscription/paywall_notifier_test.dart` "a purchase unlocks Pro from the backend's refreshed answer"; `test/presentation/features/subscription/paywall_screen_test.dart` "a purchase confirms and closes the paywall"; a real store purchase is the owner's check (M-15).
- [x] Scenario: cancelled sheet — When I close the store sheet, Then nothing
  changes and no error is shown.
  Evidence: `test/presentation/features/subscription/paywall_notifier_test.dart` "closing the store sheet is a silent cancel: no failure, nothing changes, no refresh"; `test/presentation/features/subscription/paywall_screen_test.dart` "closing the store sheet shows nothing: no toast, no error, paywall stays".
- [x] Scenario: purchase failed — Then I see the store's reason and can try
  again; I'm never charged without Pro being granted (the backend
  re-reads RevenueCat on `POST /refresh`).
  Evidence: `test/presentation/features/subscription/paywall_notifier_test.dart` "a store error is reported and leaves the plan alone", "if the backend is unreachable after a paid purchase, it is still a purchase"; `JobTrigger-Backend/test/billing.test.js` "refresh re-reads RevenueCat for the caller only".
- [x] Scenario: context — When the paywall opens because I hit a limit, Then
  its headline names that limit (e.g. "Add more servers with Pro").
  Evidence: `test/presentation/features/subscription/paywall_screen_test.dart` "the headline follows the reason".

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
- [x] Scenario: restored — When I tap Restore, Then my active purchase is
  linked to my signed-in account and Pro unlocks.
  Evidence: `test/presentation/features/subscription/paywall_notifier_test.dart` "restore: Pro comes back, or says there is nothing to restore".
- [x] Scenario: nothing to restore — Then I see "No active subscription
  found for this store account."
  Evidence: `test/presentation/features/subscription/paywall_screen_test.dart` "restore with nothing to restore says so".
- [ ] Scenario: purchase belongs to another JobTrigger account — Then the
  purchase follows the RevenueCat transfer rule chosen at P20-00, and the
  message says which account now has Pro.
  Open: partly: the backend re-syncs both accounts on a RevenueCat transfer (`JobTrigger-Backend/test/billing.test.js` "re-syncs both sides of a transfer"), but the app never says which account now has Pro.

---

### US-SUB-04 — Server limits on Free

**Priority:** Must · **Dependencies:** US-CRED-01, US-GH-CRED-01, US-SQ-CRED-01

As a Free user
I want clear limits when adding servers
So that I understand why I can't add another and what to do

**Acceptance Criteria**
- [x] Scenario: first server — Given no saved servers, When I add one of any
  tool, Then it saves as today.
  Evidence: `JobTrigger-Backend/test/billing.test.js` "allows one server on Free, of any tool, and refuses the next with PLAN_LIMIT"; `test/presentation/features/subscription/gates/gate_notifiers_test.dart` "Free: the first server is allowed".
- [x] Scenario: second server — Given one saved server, When I try to add
  another (app or website), Then the backend returns `403 PLAN_LIMIT`,
  shown as `PlanLimitFailure` with an "Upgrade" action (app) or "Upgrade
  in the JobTrigger app" (website).
  Evidence: `JobTrigger-Backend/test/billing.test.js` "allows one server on Free, of any tool, and refuses the next with PLAN_LIMIT"; `test/presentation/features/subscription/gates/gate_widgets_test.dart` "Free with a server saved: Add opens the paywall for maxCredentialsTotal and does not save"; website: `JobTrigger-Web/src/domain/plan-limit.test.ts`.
- [x] Scenario: edit and delete — Then editing or deleting my server always
  works, whatever my plan.
  Evidence: `JobTrigger-Backend/test/billing.test.js` "never limits editing or deleting"; `test/presentation/features/subscription/gates/gate_notifiers_test.dart` "Jenkins form: a blocked add never reaches the backend; an edit does".
- [x] Scenario: bypass attempt — When a client calls the create endpoint
  directly past the limit, Then the backend still refuses.
  Evidence: `JobTrigger-Backend/test/billing.test.js` "allows one server on Free, of any tool, and refuses the next with PLAN_LIMIT"; the limit is enforced by the backend whatever the client (`JobTrigger-Backend/test/plan_journey.test.js` "keeps every limit and the locked-server guard consistent end to end").

---

### US-SUB-05 — Downgrade keeps my data

**Priority:** Must · **Dependencies:** US-SUB-04

As a user whose Pro ended
I want my servers kept, not deleted
So that upgrading again puts everything back

**Acceptance Criteria**
- [x] Scenario: locked, not deleted — Given 4 saved servers and Pro ended,
  Then all 4 are listed, 1 usable and 3 shown as locked with a Pro badge.
  Evidence: `JobTrigger-Backend/test/billing.test.js` "lists everything after Pro ends, one usable and the rest locked", "refuses to make a locked server active"; `test/presentation/features/subscription/gates/gate_widgets_test.dart` "a locked server is marked Pro, tapping it opens the paywall and does not switch to it".
- [x] Scenario: choose which stays — When I pick a different server to keep
  unlocked, Then it switches, at most once per 24 hours.
  Evidence: `JobTrigger-Backend/test/billing.test.js` "lets a Free user choose which server stays, once a day".
- [x] Scenario: re-upgrade — When I buy Pro again, Then all servers unlock at
  once.
  Evidence: `JobTrigger-Backend/test/billing.test.js` "unlocks everything again on Pro".
- [x] Scenario: Pro-only features — background watches stop being scheduled,
  the widget shows an upgrade message, pins beyond 3 become read-only.
  Evidence: `test/presentation/features/subscription/gates/gate_notifiers_test.dart` "after a downgrade, stored watches stay but are not scheduled", "Free: the widget gets an upgrade snapshot, never the jobs", "Free: unpinning, and pins already pinned, are never blocked".

---

### US-SUB-06 — Pro feature gates

**Priority:** Should · **Dependencies:** US-SUB-02

As a Free user
I want to see Pro features marked, not hidden
So that I know what Pro adds

**Acceptance Criteria**
- [x] Scenario: each gate in technical design §4.3 shows a "Pro" badge and
  opens the paywall with the matching reason.
  Evidence: `test/presentation/features/subscription/gates/plan_gate_test.dart` "Free blocks each feature with its own reason"; `test/presentation/features/subscription/gates/gate_widgets_test.dart` "a teaser opens the paywall with its reason"; `test/presentation/features/subscription/gates/gate_screens_test.dart` "Free: the pin button opens maxPinnedJobs at the 4th pin", "Free: the view picker opens insights".
- [ ] Scenario: never gated — app lock, sign out everywhere, change password,
  delete account, and core trigger/logs/history work on Free.
  Open: not proven: `PlanGate` has no gate for these (`plan_gate.dart`), but no test asserts app lock, sign out everywhere, change password, delete account and trigger/logs/history all stay usable on Free.

---

### US-SUB-07 — Delete account with an active subscription

**Priority:** Must (store-required) · **Dependencies:** US-AUTH-06, US-WEB-21

As a subscriber deleting my account
I want to be told that deletion doesn't cancel billing
So that I'm not charged after leaving

**Acceptance Criteria**
- [x] Scenario: active subscription — Before confirming deletion, Then I see
  "Deleting your account doesn't cancel your subscription. Cancel it in
  <store> first." with a "Manage subscription" link.
  Evidence: `test/presentation/features/subscription/profile_subscription_test.dart` "deleting an account with a renewing store subscription warns, and links to the store"; `JobTrigger-Backend/test/billing.test.js` "blocks deletion while a paid store or web subscription is renewing".
- [x] Scenario: deleted — Then the backend deletes my subscription record and
  asks RevenueCat to delete my customer record.
  Evidence: `JobTrigger-Backend/test/billing.test.js` "removes the subscription and asks RevenueCat to delete the customer".

---

### US-SUB-08 — Plan on the website

**Priority:** Should · **Dependencies:** US-WEB-21

As a user on the setup portal
I want to see my plan and limits
So that laptop setup matches what my phone allows

**Acceptance Criteria**
- [x] Scenario: account page shows plan, renewal/end date and "manage in
  App Store / Google Play" instructions.
  Evidence: `JobTrigger-Web/src/features/account/plan-section.test.tsx` "shows the plan, limits and the manage instructions for Pro", "says where to manage it, per source, and never links to buy".
- [x] Scenario: `/pricing` lists Free vs Pro from one content file, tested.
  Evidence: `JobTrigger-Web/src/features/marketing/pricing/pricing-view.test.tsx` "lists both plans and every comparison row from the content file"; `JobTrigger-Web/src/content/pricing.test.ts`.
- [x] Scenario: Terms and Privacy cover auto-renewal, store refunds and
  RevenueCat as a processor.
  Evidence: `JobTrigger-Web/src/features/marketing/legal/legal.test.tsx` "terms cover auto-renewal, store refunds and Paddle", "privacy names RevenueCat and Paddle and what they receive".

---

### US-SUB-09 — Billing events stay correct

**Priority:** Must · **Dependencies:** backend track

As the owner
I want renewals, cancellations, refunds and billing issues reflected
automatically
So that nobody keeps Pro unpaid or loses Pro they paid for

**Acceptance Criteria**
- [x] Scenario: renewal / cancellation / expiry / refund / billing issue —
  Then `GET /api/subscription` reflects it within a minute of
  RevenueCat's webhook.
  Evidence: `JobTrigger-Backend/test/billing.test.js` "maps active, trial, cancelled and billing-issue periods", "keeps Pro through the store grace period, then expires", "treats a refund as the end, and no expiry as lifetime", "syncs the named account from RevenueCat, not from the body".
- [x] Scenario: duplicate or out-of-order webhook — Then the stored state
  matches RevenueCat's current subscriber record.
  Evidence: `JobTrigger-Backend/test/billing.test.js` "applies a duplicate delivery once", "syncs the named account from RevenueCat, not from the body", "answers 500 and releases the event when RevenueCat fails, so the retry applies".
- [x] Scenario: wrong webhook secret — `401`, nothing stored, logged without
  the body.
  Evidence: `JobTrigger-Backend/test/billing.test.js` "refuses a wrong or missing secret and stores nothing".
- [x] Scenario: `BILLING_ENABLED=false` — everyone gets Pro entitlements.
  Evidence: `JobTrigger-Backend/test/billing.test.js` "gives everyone Pro while billing is off", "changes nothing while billing is off"; `test/presentation/features/subscription/gates/plan_gate_test.dart` "billing off: nothing is ever blocked".

---

### US-SUB-10 — Web checkout

**Priority:** Could · Buy Pro on the website through a merchant of
record with Sri Lanka payouts. **Status:** built in Phase 20 (P20-83,
Paddle on `/account/billing` only); go-live is the owner's Paddle setup
(P20-85, M-15). Earlier versions of this file listed it as deferred.

### US-SUB-11 — Team plan (deferred)

**Priority:** Could · Organisations, shared servers, seats. Out of this
epic (technical design §10).
