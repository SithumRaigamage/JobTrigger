# Subscriptions

**Date:** 2026-11-18 · **Status:** approved by the owner and built in
Phase 20 (P20-00 closed). Billing ships **enabled** in release 1.0.0: the
Profile row, Subscription screen and paywall are live, and the website's
`/pricing` Pro card is purchasable. Free is the default for new accounts;
the owner (`developer@jobtrigger.app`) has a permanent Pro grant and is
never billed. Enabling it in production requires the store products,
public RevenueCat keys, and backend `BILLING_ENABLED=true` with the secret
key and webhook auth.

Read in this order:

1. **[Changes](changes.md)** — pricing, entitlements, user stories and
   technical changes for release 1.0.0.
2. **[Pricing](docs/pricing.md)** — Free vs Pro, prices, trial and the
   owner grant.
3. **[Billing integration](docs/billing-integration.md)** — RevenueCat
   setup, paywall, purchase/restore, backend sync and Paddle checkout.
4. **[Sandbox testing](sandbox-testing.md)** — how to configure App Store
   Connect, Google Play and RevenueCat for real subscribe/cancel/resubscribe
   testing.
5. **[API reference](references/api-reference-subscription.md)** — the
   subscription and billing endpoints.
6. **[Tasks](tasks/README.md)** — the phased implementation checklist.
7. **[Coverage](coverage.md)** — every subscription/billing scenario and
   whether it is automated, sandbox-tested or a manual store check.
8. **[Extra materials](extra/README.md)** — links, owner checklist and
   open items.

## The plan in brief

- **Free:** one tool, one saved server, every core feature for it.
- **Pro:** every tool, unlimited servers, background notifications,
  widget, unlimited pins, insights. **$9.99/month or $29.99/year**
  with a 7-day trial on yearly.
- **Payments:** App Store and Google Play in-app purchase through
  RevenueCat; cards on the website through Paddle (merchant of record).
  Anyone signed in on the website can buy there, including an iPhone user;
  the iOS app itself never links to web checkout (App Review). One account's
  Pro works on every platform.
- **Owner:** `developer@jobtrigger.app` is permanently Pro, never billed
  (an explicit email grant). The tester `tester@jobtrigger.app` starts Free
  and buys real sandbox subscriptions. `/admin/subscriptions` grants or
  revokes test Pro.
- **Enforcement:** the backend owns the plan and blocks extra servers
  itself; the app gates the features the backend never sees.
- **Safety:** downgrades lock, never delete; security features are never
  paid; `BILLING_ENABLED=false` keeps everyone on Pro outside production
  until the 1.0.0 launch flips it on.

## Decisions needed before any code (P20-00 … P20-03)

1. Free/Pro split and limits. 2. Prices and trial. 3. RevenueCat vs
native billing. 4. Analytics/crash tool. 5. Email provider (password
reset). 6. Web portal free within limits, or Pro-only. 7. RevenueCat
restore-transfer behaviour.
