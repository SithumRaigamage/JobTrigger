# Subscription changes for release 1.0.0

Owner decisions, 2026-11-18. Billing ships **enabled** in 1.0.0.

## 1. Pricing

| Plan | Price (USD) | Billing | Free trial |
|---|---|---|---|
| Monthly | $9.99 | Monthly recurring | – |
| Yearly | $29.99 | Yearly, billed once | 7 days, yearly only |

- Prices are USD. The App Store and Google Play show the local price; Paddle
  shows USD (the bank may convert).
- Nothing in the app hardcodes a price for display: the store's own localised
  string is shown. The dollar figures are only the fallback preview build's
  placeholders and the website's content (`pricing.ts`).

## 2. Entitlements

### Owner account — `developer@jobtrigger.app`

- Permanent Pro, **never billed** monthly or yearly.
- The grant is **explicit and tied to this email**, not to the `superAdmin`
  role. Changing an account's role never changes billing.
- Granted automatically after signup and after login (`billing/owner.js`), so
  an account created before this rule picks it up on its next sign-in, and a
  fresh database seeded by `scripts/setup-migrations.js` is correct too.
- No store or website subscription is needed, and the app shows Pro with
  nothing to buy. The web checkout refuses an already-Pro account, so the
  owner cannot be charged by accident.
- More owner accounts can be added later by changing `OWNER_EMAIL` (or by
  granting Pro with `scripts/grant-plan.js`); the owner console below can
  grant test Pro without a deploy.

### Tester account — `tester@jobtrigger.app`

- Credentials: `tester@jobtrigger.app` / `TesterPass123!` (case-sensitive),
  created by `scripts/setup-migrations.js`. The same seed removes the old
  `journey1@example.com` account and its plan.
- Starts on **Free**, like everyone else, and is never granted Pro.
- In a real build it upgrades and downgrades with **real sandbox purchases**:
  the App Store or Google Play through RevenueCat in the app, Paddle sandbox
  on the website.
- On a development build (`SANDBOX_BILLING=1` in the app,
  `BILLING_ENABLED=true SANDBOX_BILLING=true` on the backend) it can buy a
  local sandbox plan, cancel it, let it expire and resubscribe without a
  payment or a store account. That mode is impossible in a release build and
  in production.

### Every other account

- Starts on **Free**.
- Can upgrade or downgrade at any time through the channel of the platform it
  is used on (below).

## 3. Payment channels

- **iPhone:** an auto-renewable subscription bought through the App Store
  (StoreKit, via RevenueCat). The user pays with the payment method on their
  Apple ID; the app does **not** run a separate Apple Pay checkout. Manage or
  cancel in the App Store.
- **Android:** a Google Play subscription (via RevenueCat). Manage or cancel
  in Google Play.
- **Web:** card checkout through Paddle on `/account/billing` (Paddle is the
  merchant of record). Manage card, invoices and cancellation in Paddle's
  customer portal.

## 4. Web checkout and the iOS app (App Review)

The recommended and implemented rule:

- **The website sells to anyone who signs in there, including someone who
  also uses the iPhone app.** The site is a browser surface, outside the app;
  App Review's rules about external purchase links apply to the app, not to a
  website the user opens themselves.
- **The iOS app never links to, mentions or opens the website's checkout.**
  The app's own purchase is StoreKit. A web subscription is displayed as Pro
  on the Subscription screen with plain text and no link, and the paywall
  opens no external payment page. Anyone who visits the site directly can buy
  there.
- No "reader app" entitlement, no external purchase link, no mention of
  cheaper web pricing inside the app.

## 5. Cancellation and downgrade

- Cancelling stops the renewal; **Pro remains active until the paid period
  ends** (the backend keeps `active`/`cancelled` with a future `periodEnd`).
- Then the account drops to Free. Nothing is deleted: one saved server stays
  usable and the rest are locked until Pro returns.
- Account deletion is **blocked while a paid store or web subscription is
  still renewing**, with instructions to cancel it in the App Store, Google
  Play or the website first. Grants and student years never block deletion.

## 6. One account, every platform

- The backend owns the entitlement. Pro bought on the website shows in the
  app and the reverse, for the same JobTrigger account.
- The plan is the best of the user's sources (`billing/combine.js`): store,
  web and grant are kept separately, so one source can never overwrite
  another.
- Buying the same plan twice from a second channel is refused: Paddle
  checkout answers **409** when the account is already Pro, and the website
  only offers a portal when the plan came from the web.

## 7. Owner console

- `/admin/subscriptions` on the website (super admin only, the backend
  re-checks the role on every call) lists every account's derived plan and
  each source.
- From there the owner can **grant** Pro for a number of days or with no end,
  and **revoke** that grant. Revoking never touches a paid store or web
  subscription.
- Everything is logged by id; the list is `no-store`. A normal account gets
  the backend's plain 404, so the admin area is not advertised.

## 8. Billing support screen

The app's Subscription screen shows the current plan, the source (App Store,
Google Play, website, student or included with the account), the renewal or
end date, the cancellation state, a **Manage** action where the source has
one (store page or Paddle portal), and **Restore purchases** on Free.

## 9. Webhooks and single source of truth

- Renewal, cancellation, failed payment and expiry arrive from RevenueCat and
  Paddle webhooks. The backend stores them idempotently (`BillingEvent`) and
  re-reads the provider, never the body, before changing a plan.
- The backend is the only place an entitlement is decided; the app and the
  website render `GET /api/subscription`.

## 10. Test-only tools

- The app's billing preview (`BILLING_PREVIEW`) is dev-only and can never be
  enabled in a release build (`AppConfig.fromEnvironment` ignores it there).
- The owner console is a real admin feature, not a test switch, and its
  writes require the super-admin role read from the database.

## 11. Implementation map

- Backend: `billing/owner.js` (owner grant), `billing/combine.js` (sources,
  clear), `controllers/adminSubscriptionController.js`, `routes/adminSubscriptionRoutes.js`.
- App: `AppConfig` prices, `PreviewBillingClient` prices, existing paywall and
  Subscription screen (no new purchase path).
- Website: `src/content/pricing.ts`, `/account/billing`,
  `/admin/subscriptions`.
- Owner setup still required: App Store Connect products, Play Console
  products, RevenueCat, Paddle, and the production `BILLING_ENABLED=true`
  flip (P20-40..42, P20-62, P20-85).
