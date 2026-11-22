# Phase 29 — Promo and voucher codes (epic PROMO)

**Approved by the owner, November 2026** (decision of 2026-11-22 in the
request): a code gives a Free account a stretch of Pro; the codes are a list in
the backend's environment (`PROMO_CODES`), so adding one is an edit and a
redeploy. Story: `docs/user-stories/billing/24-promo-codes.md`. Design:
`docs/design/US-PROMO-redeem-codes.md`. Follow `CLAUDE.md`: plan before code,
logic in notifiers, analyze clean, no new dependencies, Jenkins frozen (§11).

## Decisions (owner)

- A code is **free Pro time** (`days`) or a **Paddle discount for the website
  checkout** (`discountId`, US-PROMO-04). Percent-off offers in the App Store
  or Google Play are a later story.
- Codes live in `PROMO_CODES` only: no database of codes, no admin screen to
  create them. Parameters per code: `days`, optional `maxRedemptions`, optional
  `expiresAt`.
- **One redemption per account per code**; a code may cap its total redemptions
  and its last day.
- A pro account cannot redeem ("nothing to add"); a paid or granted plan always
  outranks the promo source.
- Expiry is computed from `periodEnd` on every read, for the `promo` source
  only — no job. A grant, student year or paid source keeps the status its own
  writer set (review note, 2026-11-22), so this story changes nothing else.

## Tasks

### PV-1 Backend
- [x] PV-10 `PROMO_CODES` parsing and startup validation in `config/env.js`,
      with `PROMO_CODES` in `docs/configuration.md`.
- [x] PV-11 `Subscription.promo` source and `PromoRedemption` model (unique
      `{ code, userId }`, counted per code, deleted with the account).
- [x] PV-12 `billing/promo.js`: normalization, lookup with cap and last day,
      and the redeem decision.
- [x] PV-13 `POST /api/subscription/promo` behind `auth` and a per-account rate
      limit; `promoAvailable` in `GET /api/subscription`.
- [x] PV-14 `promo` in `combine.js` (ranked with the student year) and in the
      owner's `/admin/subscriptions` view.
- [x] PV-15 `test/promo_codes.test.js`: every criterion in US-PROMO-01.

### PV-2 App
- [x] PV-20 `SubscriptionSnapshot.promoAvailable`, `redeemPromoCode` on the
      repository and its implementation.
- [x] PV-21 `PromoRedeemNotifier` with its outcomes and a busy guard.
- [x] PV-22 Subscription screen: the row, the dialog, the success toast, the
      refreshed plan, and the "Redeemed with a code." note.
- [x] PV-23 Tests: repository, notifier, widget (row, dialog, success, refusal,
      demo mode).

### PV-3 Website
- [x] PV-30 `promoAvailable` in the domain type and the API parser.
- [x] PV-31 `redeemPromoCode` in `server/subscription-api.ts` and the server
      action.
- [x] PV-32 "Redeem a code" form on `/account/billing`.
- [x] PV-33 Tests: the form and the parser.

### PV-4 Docs
- [x] PV-40 Story and design note (done first, this phase).
- [x] PV-41 `docs/api-reference.md` (the route, `promoAvailable`, the admin
      `promo` source), `docs/data-models.md`, `docs/configuration.md`, the
      user-story index and the `tasks/README.md` row.

### PV-6 A percentage off the checkout (US-PROMO-04)
- [x] PV-60 `PROMO_CODES` entries are one kind — `days` or `discountId`; the
      discount id is validated as `dsc_…`, and `maxRedemptions` on a discount
      code is refused (Paddle owns that cap).
- [x] PV-61 `billing/promo.js` `checkoutDiscount`: unknown, expired or a
      Pro-time code is one neutral `invalid_code`; nothing is written.
- [x] PV-62 `POST /api/billing/paddle/checkout` takes an optional `code`,
      resolves it server-side and sends Paddle `discount_id`.
- [x] PV-63 Website: "Discount code (optional)" on the upgrade buttons, sent
      through the action; tests in `billing-actions.test.tsx`, `actions.test.ts`
      and `billing-api.test.ts`.
- [x] PV-64 Docs: story US-PROMO-04, design note, `docs/configuration.md`,
      `docs/api-reference.md`.
- [x] PV-66 Copy and the wire: the checkout field is "Discount code (money off
      this purchase)" with a hint that it adds no Pro time, the form is
      "Redeem a code for free Pro time" and points money-off codes at the
      checkout, and `test/paddle_client.test.js` proves the real client sends
      `discount_id`.
- [ ] PV-65 MANUAL (owner): create the percentage discount in Paddle, put its
      `dsc_…` id on a `PROMO_CODES` entry, redeploy, then buy with the code and
      check the checkout shows the lower total.

### PV-7 Running codes: numbers and a safe deploy (US-PROMO-05)
- [x] PV-70 `GET /api/admin/subscriptions` gains `codes`: every configured
      code with its redemptions (the rows the cap counts), `maxRedemptions`
      and `remaining`; a checkout discount reports no local numbers.
- [x] PV-71 `/admin/subscriptions` shows the codes card (counts, cap left,
      retired codes) without listing who holds one.
- [x] PV-72 `promo_redeemed` in the analytics catalogue, sent with `{ days }`
      only — never the code.
- [x] PV-73 `scripts/check-promo-codes.js` + `npm run check-promo-codes`: the
      same `PROMO_CODES` rules as startup, exit 1 on a typo, counts by kind,
      no value printed; documented in `docs/configuration.md`.
- [x] PV-74 Tests: backend console counts (and that the count matches the rule)
      and the event; the script (usable, typo, unset); web parser and card.

### PV-5 Manual
- [ ] PV-50 MANUAL (owner): put the real codes in the deployment's
      `PROMO_CODES` and redeploy, then redeem one on the iPhone
      (Profile → Subscription → Redeem a code) and check the plan shows Pro
      with its end date.

## Done when
- `npm test` in `JobTrigger-Backend/`, `flutter analyze` and `flutter test` in
  `JobTrigger-Frontend/`, and `npm run check` in `JobTrigger-Web/` are clean.
- The owner has a code in `PROMO_CODES` and has redeemed it on the iPhone
  (MANUAL, PV-50), and a discount code bought once on the website (MANUAL,
  PV-65).
