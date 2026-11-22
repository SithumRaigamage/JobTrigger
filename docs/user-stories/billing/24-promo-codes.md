# Epic: PROMO — promo and voucher codes

A promo code gives a Free account a stretch of JobTrigger Pro at no charge:
the owner mails or posts a code, the user redeems it in the app or on the
website, and the account is Pro until the code's days run out.

**Owner decisions, 2026-11-22:**

1. **Codes live in the backend's environment** (`PROMO_CODES`), not in the
   database and not in either client. Adding or retiring a code is an edit to
   the deployment's variables and a redeploy — no app release, no website
   release, no admin screen to build.
2. **A code is free Pro time, or a Paddle discount for the website checkout**
   (US-PROMO-04). One code = one period of Pro (7 days, a month, a year —
   whatever the code says), from the moment it is redeemed; or, with a
   `discountId`, a percentage taken off a website checkout by Paddle. A
   percentage off in the App Store or Google Play is **not** in this story:
   those prices are offers in App Store Connect and the Play Console, and
   adding them is a separate story.
3. **One redemption per account per code**, and a code may cap its total
   redemptions and its own last day.
4. Redeeming is a Pro source of its own (`promo`), so it can never overwrite a
   store or website subscription, and a paid plan always outranks it.

Design: [`docs/design/US-PROMO-redeem-codes.md`](../../design/US-PROMO-redeem-codes.md).
Tasks: `tasks/phase-30-promo-codes.md`.

---

### US-PROMO-01 — Redeem a promo code for Pro

**Priority:** Must · **Source:** owner decision 2026-11-22 · **Dependencies:** P20-10, P20-11

As a Free user with a promo code
I want to enter it in the app or on the website
So that I get JobTrigger Pro for the period the code gives

**Acceptance Criteria**

- [x] Scenario: a valid code — Given billing is on and `PROMO_CODES` lists
  `LAUNCH30` for 30 days, When I redeem it as a Free account, Then
  `POST /api/subscription/promo` answers 200 with the `GET /api/subscription`
  body, `plan: "pro"`, `source: "promo"`, `willRenew: false` and `periodEnd`
  30 days from now; the account is Pro on the next read.
- [x] Scenario: the code is forgiving — leading/trailing spaces and lower case
  are accepted (`  launch30 ` is `LAUNCH30`); an empty or 1000-character value
  is `400` without a lookup error.
- [x] Scenario: one per account — When the same account redeems the same code
  again, Then **409** `already_redeemed` and nothing changes; the plan and its
  end date are exactly as after the first redemption.
- [x] Scenario: a cap on the code — Given a code with `maxRedemptions: 2`, Then
  the first two accounts succeed and the third gets the same **400**
  `invalid_code` as an unknown code (it never says the code exists but is used
  up).
- [x] Scenario: a last day — Given a code whose `expiresAt` has passed, Then
  **400** `invalid_code` and nothing is written.
- [x] Scenario: an unknown code — Then **400** `invalid_code` with one sentence
  that never distinguishes unknown, expired and used-up, and nothing is
  written (no enumeration).
- [x] Scenario: already Pro — Given the account is Pro now (store, website,
  grant, student or an earlier code), Then **409** `already_pro` with a
  sentence saying the code would add nothing.
- [x] Scenario: billed plans win — Given a promo period is running, When the
  account later buys on the store or the website, Then the paid plan is the one
  shown (`GET /api/subscription`, `source` is the store/web), and when the paid
  plan ends the promo period it did not consume comes back into effect.
- [x] Scenario: it ends by date, not by a job — When `periodEnd` passes, Then
  `GET /api/subscription` is `free` with `source: "promo"` and `state:
  "expired"`, with no background job having run.
- [x] Scenario: off unless set up — Given `BILLING_ENABLED` is off, or
  `PROMO_CODES` is empty, Then redeeming is **503** `not_available`, and
  `GET /api/subscription` says `promoAvailable: false` so neither client offers
  the action.
- [x] Scenario: abuse — Then the route is limited per account (10 per 15
  minutes, `PROMO_REDEEM_RATE_LIMIT`), needs a session, and logs the redemption
  with the account id and code only (never the session token).
- [x] Scenario: a bad configuration does not start — Given `PROMO_CODES` is not
  JSON, an entry has no `days`, a `days` outside 1–3650, a `maxRedemptions`
  that is not a positive whole number, an `expiresAt` that is not a date, a
  code with characters other than letters, digits, `_` and `-`, or the same code
  twice, Then the server refuses to start and names `PROMO_CODES` (never the
  value).
- [x] Scenario: the owner sees it — Then `/admin/subscriptions` shows the
  account's `promo` source next to the others, with its end date, and the code
  it was redeemed with.

**Security & Privacy Notes** — the codes are a server-side secret list: they
are never sent to a client, listed, or logged in full beyond the one that was
used. A redemption row keeps the account id, the code and the end date so a
code's cap can be counted. Deleting the account deletes its redemption rows
(the global cap still bounds abuse), exactly as the student plan's data is
deleted with the account.

**Impact** — Backend: yes (config, model, route, entitlements, admin view).
App: yes (US-PROMO-02). Web: yes (US-PROMO-03).

---

### US-PROMO-02 — Redeem a code in the app

**Priority:** Must · **Source:** owner decision 2026-11-22 · **Dependencies:** US-PROMO-01

As a Free user on my phone
I want to redeem a code from the Subscription screen
So that I don't need a laptop to use one

**Acceptance Criteria**

- [x] Scenario: the entry — Given `promoAvailable` is true and I am not Pro,
  Then Profile → Subscription shows "Redeem a code"; while I am Pro, or when
  the backend has no codes, the row is absent.
- [x] Scenario: redeem — When I tap it, Then a dialog asks for the code
  ("Redeem" is disabled while the field is empty), and on success it closes,
  a toast confirms Pro, and the screen immediately shows JobTrigger Pro with
  "Ends on <date>".
- [x] Scenario: a refused code — When the backend refuses, Then its sentence is
  shown in the dialog (already used, already Pro, not valid) and I can correct
  the code; a network failure shows "Try again" and sends nothing twice.
- [x] Scenario: the plan's source — Then the Subscription screen's note under
  the plan says "Redeemed with a code." for a promo Pro, and no website link or
  store link is shown.
- [x] Scenario: demo mode — Then no request is made and the row is absent.

**Impact** — App: yes. Backend: yes (US-PROMO-01). Web: no (separate story).

---

### US-PROMO-03 — Redeem a code on the website

**Priority:** Should · **Source:** owner decision 2026-11-22 · **Dependencies:** US-PROMO-01

As a Free user signed in on the website
I want to redeem a code on `/account/billing`
So that I can use one without the app

**Acceptance Criteria**

- [x] Scenario: the form — Given `promoAvailable` is true and the account is
  not Pro, Then the billing page shows a "Redeem a code for free Pro time"
  form; when the backend has no codes the form is absent, and the page's
  existing Paddle copy is unchanged.
- [x] Scenario: success — When I submit a valid code, Then the page shows Pro
  with its end date, and says it was redeemed with a code (not bought).
- [x] Scenario: refusal — Then the backend's sentence is shown in the form
  (used, already Pro, not valid) and the form stays usable.
- [x] Scenario: no session — Then the action redirects to sign-in like the
  other account actions, and no call is made without a session.

**Impact** — Web: yes. Backend: yes (US-PROMO-01). App: no.

---

### US-PROMO-04 — A percentage off the website checkout

**Priority:** Should · **Source:** owner decision 2026-11-22 · **Dependencies:** US-PROMO-01, P20-83

As a Free user with a discount code
I want it taken off the price when I buy on the website
So that I pay less without the owner editing prices

**Acceptance Criteria**

- [x] Scenario: the checkout applies it — Given `PROMO_CODES` lists `SAVE20`
  with the id of a 20% Paddle discount, When I start a yearly or monthly
  checkout with that code (any case, surrounding spaces forgiven), Then the
  Paddle transaction is created with `discount_id` set by the server, and the
  overlay shows the discounted total — the browser never sends a price or a
  discount id.
- [x] Scenario: a bad code stops before Paddle — Given an unknown code, one
  past its `expiresAt`, or a Pro-time code, Then **400** `invalid_code` with
  the same one sentence as the redeem form, and no transaction is created, so
  nothing is charged at a price the buyer did not see.
- [x] Scenario: it is not Pro time — When that code is posted to
  `/api/subscription/promo`, Then **400** `invalid_code` and nothing is
  written; with only discount codes configured, `promoAvailable` is false and
  neither client shows "Redeem a code".
- [x] Scenario: one kind per entry — Given an entry with both `days` and
  `discountId`, with neither, with a `discountId` that is not `dsc_…`, or with
  `maxRedemptions` on a discount code, Then the server refuses to start and
  names `PROMO_CODES` (never the value).
- [x] Scenario: where the limits live — Then the percentage, whether it recurs,
  how many payments it covers and its redemption cap are set on the Paddle
  discount (Paddle counts its own redemptions); our `expiresAt` on the code is
  still checked before a transaction is made.
- [x] Scenario: without a code nothing changes — Then the checkout body omits
  it, no `discount_id` is sent, and the existing checkout, portal and webhook
  behaviour is unchanged.
- [x] Scenario: the two boxes say which is which — Given a Free user sees both
  actions, Then the checkout field is labelled "Discount code (money off this
  purchase)" with a hint that it does not add Pro time, and the form is headed
  "Redeem a code for free Pro time" with a line saying a money-off code is
  entered at the checkout instead.
- [x] Scenario: the id really goes to Paddle — Then the real Paddle client's
  transaction body carries `discount_id` for a discount code and no such field
  without one (fetch stubbed, nothing leaves the process).

**Security & Privacy Notes** — the discount id never leaves the server: the
browser names a code, the backend resolves it. A refused code reads exactly
like a refused redemption (unknown, expired and wrong-kind are one sentence).

**Impact** — Backend: yes (config, `billing/promo.js`, checkout controller,
Paddle client). Web: yes (a field on the upgrade buttons). App: no — buying in
the app goes through the stores' own offers, which is a separate story.

---

---

### US-PROMO-05 — Run codes with numbers, and ship them safely

**Priority:** Should · **Source:** owner request 2026-11-22 · **Dependencies:** US-PROMO-01, US-PROMO-04

As the owner
I want to see how much of each code is used, and to check the list before a deploy
So that I can run a campaign, spot a leaked code, and never take the API down with a typo

**Acceptance Criteria**

- [x] Scenario: the console shows each code — Given `PROMO_CODES` lists
  `LAUNCH30` (30 days, `maxRedemptions: 50`), `OPEN7` (7 days, no cap) and
  `SAVE20` (a checkout discount), Then `/admin/subscriptions` shows a "Promo
  codes" card with all three: "Pro for 30 days · 3 redeemed of 50, 47 left",
  "Pro for 7 days · 4 redeemed", and Paddle counting the checkout discount.
- [x] Scenario: the count is the rule — Given a code with `maxRedemptions: 2`
  and two accounts holding it, Then the console says "2 redeemed of 2, 0
  left" and a third account is still refused with `invalid_code`: the number
  shown is the redemption rows the redeem rule counts, not a second tally.
- [x] Scenario: retiring a code shows — Then a code past its `expiresAt` reads
  "past its last day" rather than looking usable.
- [x] Scenario: counts, never people — Then the card carries no account id,
  email or who redeemed what; the per-account rows stay as they were.
- [x] Scenario: one event, no code — When a code is redeemed, Then Umami
  receives `promo_redeemed` with `{ days }` and nothing else; the code appears
  in neither the event name nor its data (the log keeps it, the third-party
  analytics never does).
- [x] Scenario: a typo is caught before the deploy — When I run
  `PROMO_CODES='…' npm run check-promo-codes`, Then a usable list exits 0 and
  prints how many codes and of which kind, a malformed one exits 1 with the
  sentence the server would refuse to start on, and unset exits 0 saying the
  feature is off — never printing a code or the raw value.

**Security & Privacy Notes** — the codes stay server-side: the console shows
counts to a super admin only, analytics gets the days and never the code, and
the pre-deploy check prints kinds and counts, not values.

**Impact** — Backend: yes (console response, analytics event, a script). Web:
yes (the codes card). App: no.

---

### US-PROMO-06 — A reminder before a code's Pro runs out

**Priority:** Should · **Source:** owner request 2026-11-22 · **Dependencies:** US-PROMO-02, US-JX-10

As a user whose Pro came from a promo code
I want to be told three days before it ends
So that I don't lose Pro without noticing

**Acceptance Criteria**

- [x] Scenario: three days out — Given Pro from a redeemed code ends within
  three days, When the plan reaches the app (launch, a resume refresh, a
  redemption or a purchase), Then one local notification says "Your Pro from a
  code ends soon", with the day it ends and that Free follows, on a channel of
  its own so someone who silenced build results still hears it.
- [x] Scenario: it is said in the app as well, with no permission needed —
  Then a banner at the top of Home and of Profile → Subscription says the same
  thing while the period is in its last three days and opens the Subscription
  screen: this is the reminder for the many people who redeem a code and never
  turned notifications on.
- [x] Scenario: once per period — Then reloading the same plan posts nothing
  more: the end date the notification covered is kept in `shared_preferences`
  (removed on logout), and a *new* period — another code redeemed — is
  announced again.
- [x] Scenario: not for anything else — Given an App Store, Play, website or
  student plan, or Free, or more than three days left, or a period already
  over, Then no notification.
- [x] Scenario: it never prompts — Then no notification permission is asked
  for on its account: with notifications not allowed nothing is posted and
  the banner carries the reminder instead, and a refused or failing platform
  call is swallowed so the app carries on.
- [x] Scenario: a period counts as reminded only once it was shown — Given the
  OS refused the notification (not allowed, or the call failed), Then the end
  date is *not* recorded, and the reminder is posted once notifications are
  allowed: a refused notification never silently ends the reminders for that
  period.
- [x] Scenario: where it is read — Then it also appears while the app is open
  (iOS hides a foreground notification otherwise), carries no payload, and
  never names the code.
- [x] Scenario: no request of its own — Then it is computed from the plan the
  app already has: no new endpoint and no extra call.

**Security & Privacy Notes** — the reminder and its banner name no code, no
account and no amount; a local notification leaves nothing the device.

**Impact** — App: yes. Backend: no (`periodEnd` and `source: "promo"` were
already in `GET /api/subscription`). Web: no.

---

## Tests needed

| Criterion | Test |
|---|---|
| US-PROMO-01 (redeem, caps, expiry, duplicates, already Pro, billing off, rate limit, config validation) | `JobTrigger-Backend/test/promo_codes.test.js` |
| US-PROMO-01 (paid wins over promo) | `JobTrigger-Backend/test/promo_codes.test.js` "a paid plan outranks the promo period" |
| US-PROMO-01 (owner console) | `JobTrigger-Backend/test/promo_codes.test.js` admin list; `JobTrigger-Web/src/server/admin-subscriptions-api.test.ts` |
| US-PROMO-02 | `JobTrigger-Frontend/test/presentation/features/subscription/promo_redeem_test.dart`, `test/data/repositories/subscription_repository_impl_test.dart` |
| US-PROMO-03 | `JobTrigger-Web/src/features/billing/promo-code-form.test.tsx`, `src/server/subscription-api.test.ts` |
| US-PROMO-04 (the wire body: `discount_id` present with a code, absent without) | `JobTrigger-Backend/test/paddle_client.test.js` |
| US-PROMO-05 (counts and caps, the event, the pre-deploy check) | `JobTrigger-Backend/test/promo_codes.test.js` "counts each code and what is left of its cap…", "records the redemption for analytics without the code"; `test/check_promo_codes.test.js`; `JobTrigger-Web/src/features/admin/subscriptions-view.test.tsx`, `src/server/admin-subscriptions-api.test.ts` |
| US-PROMO-06 (three days before the end, once per period, nothing for other plans, the in-app banner, and a refused notification leaving the period unmarked) | `JobTrigger-Frontend/test/presentation/features/subscription/promo_expiry_reminder_test.dart` |
| US-PROMO-04 (the checkout discount, refusals, one kind per entry) | `JobTrigger-Backend/test/paddle.test.js` "applies a discount code to the transaction…", `test/promo_codes.test.js` "keeps a discount code out of the Pro-time redeem action" and the config test; `JobTrigger-Web/src/features/billing/billing-actions.test.tsx`, `src/features/billing/actions.test.ts`, `src/server/billing-api.test.ts` |

## Verification (2026-11-22)

Every criterion above was checked against the built code, with these tests:

| Criterion | Evidence |
|---|---|
| valid code → Pro for its days | `promo_codes.test.js` "redeems a valid code for Pro for its days, and shows it on the next read" |
| forgiving input, empty and huge values | "forgives case and surrounding spaces, and refuses an empty or huge value" |
| one per account | "counts one redemption per account per code, and changes nothing the second time" |
| the cap | "stops a code at its total cap, saying the same thing as an unknown code" |
| last day | "refuses a code past its last day and writes nothing" |
| already Pro | "tells a Pro account the code would add nothing" |
| paid plans win, the promo comes back | "a paid plan outranks the promo period, which comes back when the paid one ends" |
| ends by date | "ends by date, not by a job" |
| off unless set up | "is unavailable when billing is off, and says so to both clients", "is unavailable when no codes are configured" |
| abuse | "needs a session", "limits attempts per account, so a code list cannot be walked", "keeps the promo out of the entitlements of a different account" |
| bad configuration | "refuses to start with a broken code list, naming only the variable" |
| the owner sees it | "shows the redemption to the owner console"; `JobTrigger-Web` admin sources parser |
| account deletion | "removes the redemption with the account" |
| app: row, dialog, success, refusal, network, demo, double tap | `promo_redeem_test.dart` (9 widget/unit tests); `subscription_repository_impl_test.dart` "redeemPromoCode posts the code…", "a refused code keeps the backend's own sentence and code" |
| US-PROMO-04: the two boxes are told apart | `promo-code-form.test.tsx` "says it gives Pro days, not money off (US-PROMO-04)"; `billing-actions.test.tsx` "names the field for money off…" |
| website: form, refusal, refresh | `promo-code-form.test.tsx`, `subscription-api.test.ts` "redeemPromoCode (US-PROMO-01)", `billing.test.tsx` "offers Redeem a code on Free…", "says a promo plan was redeemed with a code" |
| US-PROMO-04: the checkout discount, refusals, one kind per entry | `paddle.test.js` "applies a discount code to the transaction, and refuses a bad one before Paddle (US-PROMO-04)"; `promo_codes.test.js` "keeps a discount code out of the Pro-time redeem action (US-PROMO-04)" and the broken-list test; `billing-actions.test.tsx` (field, trim, refusal), `actions.test.ts` (forwarded, too long), `billing-api.test.ts` (body) |
| US-PROMO-05: counts/caps, no PII, the event, the pre-deploy check | `promo_codes.test.js` "counts each code…" (2 of 2 used, 0 left, third refused), "records the redemption for analytics without the code"; `check_promo_codes.test.js` (usable, typo, unset, same rules); `subscriptions-view.test.tsx` (lines, checkout, retired, no card, per-account note); `admin-subscriptions-api.test.ts` |
| US-PROMO-06: the notification | `promo_expiry_reminder_test.dart` (18 tests): `promoEndingSoon` inside three days and outside it (earlier, at the end, after it, another source, Free); one notification with the end date and a fixed id; no repeat for the same period across three loads; a new period announces again; nothing for a store plan or a plan months out; a throwing platform call still completes; the end date is **not** recorded when notifications are refused or the call throws, so the reminder arrives once they are allowed; and the notifier wiring — one reminder from a plan loaded as promo Pro ending in two days, none from a reload, a store plan, a distant end, or a phone that never allowed notifications |
| US-PROMO-06: the in-app banner | same file, `PromoExpiryBanner` group: the end date and the way to the Subscription screen inside three days, hidden with more left, for a store plan, and after the period |
| US-PROMO-01: only a promo source ends by date on a read | `billing.test.js` "ends a promo period by date, and leaves every other source to its writer" |

Checks run on 2026-11-22: `npm test` (backend, 487 passing), `flutter analyze`
(clean) and `flutter test` (1943 passing, 18 of them US-PROMO-06) in the app,
`format:check`, `lint`, `typecheck` and `npm test` (537 passing) in the website. **Not verified:** the
iPhone pass (`tasks/phase-30-promo-codes.md` PV-50) — a real code redeemed in
the app on a device — and the Paddle discount purchase (PV-65), which needs a
discount created in Paddle and a real checkout.

## Not in this story

- **A percentage off in the app stores.** Those prices are offers in App Store
  Connect and the Play Console (bought through RevenueCat), so they are their
  own story; the website's percentage discount is US-PROMO-04.
- **A code that does both.** An entry is either Pro time or a checkout
  discount, so there is never a question of which applies first.
- **Codes that grant a specific product** (a yearly plan rather than days).
  Every code grants Pro for a number of days; that is all a voucher needs
  today.
- **An owner screen to create or revoke codes.** They are one line in the
  deployment's variables, and the redemption log is visible on
  `/admin/subscriptions`.
