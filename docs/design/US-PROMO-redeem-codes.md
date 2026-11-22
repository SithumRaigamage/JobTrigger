# US-PROMO-01…03 — promo and voucher codes (design)

Owner decisions of 2026-11-22. Story:
[`docs/user-stories/billing/24-promo-codes.md`](../user-stories/billing/24-promo-codes.md).
Tasks: `tasks/phase-29-promo-codes.md`.

## Why a source, not a new plan

The billing layer already answers one question — "is this account Pro now?" —
from a set of independent sources (`store`, `web`, `grant`, `student`), and
`billing/combine.js` picks the best of them. A promo code is a fifth source
(`promo`), so:

- it can never overwrite a store or website subscription (those are written by
  their own webhooks into their own source);
- a paid plan always outranks it (the existing ranking: paid/granted beats the
  free sources);
- expiry needs no job: the end date is on the source, and `isPro()` compares it
  with the clock on every read, exactly like the student year.

`Subscription.source` already had `promo` in its enum (RevenueCat promotional
entitlements write `store` with `source: "promo"`). The new source key reuses
that name.

## Configuration

```
PROMO_CODES=[{"code":"LAUNCH30","days":30},
             {"code":"STUDENT-BONUS","days":365,"maxRedemptions":50,"expiresAt":"2027-01-31"}]
```

| Field | Required | Meaning |
|---|---|---|
| `code` | yes | 3–64 characters, letters/digits/`_`/`-`; compared trimmed and upper-cased |
| `days` | yes | whole number 1–3650 of Pro from the moment of redemption |
| `maxRedemptions` | no | total redemptions across all accounts |
| `expiresAt` | no | `YYYY-MM-DD` (usable through that UTC day) or a full ISO date-time |

`config/env.js` parses it once per call into a normalized list. Anything
malformed (bad JSON, a missing `days`, out-of-range values, a bad character, a
duplicate code) is a startup refusal through `invalidConfig`, naming
`PROMO_CODES` and never echoing the value. Unset or `[]` means the feature is
off, and both clients hide the action.

Shipped through the deploy's variables: edit, redeploy, done — no database
write, no app or website release.

## Backend

**`Subscription`** gains `promo` (the shared source schema). **`PromoRedemption`**
is `{ code, userId, days, periodEnd, createdAt }`:

- unique `{ code, userId }` — two requests for the same code from one account
  cannot both write (the second is caught by the duplicate key, not by a
  check-then-write race);
- `{ code, createdAt }` — counting a code's total redemptions and pruning later;
- deleted with the account (added to the cascade in `authController`).

**`billing/promo.js`**

- `normalizeCode(raw)` — trim, upper-case, cap at 64 characters.
- `findCode(raw, now)` — the entry from `PROMO_CODES`, or null when unknown,
  past `expiresAt`, or its cap is reached (the cap is counted from
  `PromoRedemption`).
- `redeemPromo(userId, raw, now)` — the whole decision, in order: billing on and
  at least one code (else `503 not_available`), the code is usable (else
  `400 invalid_code`), the account is not Pro (else `409 already_pro`), the
  redemption is written first (a duplicate key is `409 already_redeemed`), then
  `writeSource(userId, 'promo', …)` sets `plan: pro`, `status: active`,
  `source: promo`, `startsAt: now`, `periodEnd: now + days`, `willRenew: false`,
  and the code is kept in `productId` so the owner console shows which code was
  used. If the source write fails, the redemption row is removed so a retry is
  possible.

**`POST /api/subscription/promo`** (`{ code }`), after `auth`, with
`promoRedeemLimiter` (10 per 15 minutes per account, `PROMO_REDEEM_RATE_LIMIT`).
It answers with the same body as `GET /api/subscription` (`no-store`).

**`GET /api/subscription`** gains `promoAvailable: billingEnabled && codes
exist`. It says nothing about how many or which.

**`combine.js`** ranks `promo` with `student` (both free), below paid and
granted Pro; `clearSource` needs no change.

**`adminSubscriptionController.view`** gains `promo: sourceView(...)`, so
`/admin/subscriptions` lists it beside the others.

## App (`JobTrigger-Frontend`)

- `SubscriptionSnapshot` gains `promoAvailable` (from the DTO, default false, so
  an older backend shows nothing).
- `SubscriptionRepository.redeemPromoCode(code)` → `POST
  /api/subscription/promo`, returning the new snapshot through `guardRequest`,
  like `load`/`refresh`. 409/400 sentences arrive as `StudentRequestFailure`
  (the existing explained-failure mapping).
- `PromoRedeemNotifier` (in `presentation/features/subscription/`): one call,
  outcomes `PromoRedeemed(snapshot)`, `PromoRedeemRefused(message, code)`,
  `PromoRedeemFailed(failure)`; a busy flag so a double tap sends once.
- The Subscription screen: a "Redeem a code" row shown when
  `promoAvailable && !isPro`, a dialog with the code field (Redeem disabled
  while empty), success → `entitlementsNotifier.apply(snapshot)` + toast, and a
  `promo` case in `_sourceNote` ("Redeemed with a code.").

## Website (`JobTrigger-Web`)

- `Subscription` gains `promoAvailable` (optional in zod, default false).
- `src/server/subscription-api.ts`: `redeemPromoCode(token, code)` (`POST`),
  and `getSubscription` parses the new field.
- `src/features/billing/actions.ts`: `redeemPromoCodeAction` (session required,
  forwards to the backend, returns `{ error }` or `{ ok: true }`).
- `src/features/billing/promo-code-form.tsx`: a labelled input and
  `useActionState`, mounted on `/account/billing` when `promoAvailable && plan
  is free`; on success the page re-reads the plan (`router.refresh()`).

## Tests

Backend `test/promo_codes.test.js` walks every criterion over HTTP with the
test database: valid, normalization, duplicate, cap, expiry, unknown, already
Pro, paid-wins, expiry by date, billing off, no codes, rate limit, config
parsing, admin list. App: a repository test and a widget test for the row,
dialog, success, refusal and demo mode. Web: a form test and the API parser
test. See the story's table.
