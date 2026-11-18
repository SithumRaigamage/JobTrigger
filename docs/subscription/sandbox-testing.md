# Sandbox purchase testing (Apple App Store / Google Play)

This is the honest, complete guide to testing **real** subscribe → cancel →
resubscribe flows. Code alone cannot enable this: Apple, Google and
RevenueCat accounts must be configured by the owner with their credentials.
The app is already wired for it — you only supply keys.

## Why preview mode "fails"

`BILLING_PREVIEW=true` (the dev default) shows the two plan cards but
`Subscribe` deliberately fails with *"Preview build: no store is
connected"*. That is by design — no real store is attached. To buy, you must
attach a real store via RevenueCat (below).

---

## Part A — External setup (you must do this)

### 1. App Store Connect (iOS sandbox)
1. Sign in to https://appstoreconnect.apple.com.
2. Your app → **Features → In-App Purchases** → create two **Auto-Renewable Subscriptions**:
   - Monthly — Product ID e.g. `jobtrigger_pro_monthly`, price $9.99.
   - Yearly — Product ID e.g. `jobtrigger_pro_yearly`, price $29.99, **7-day free trial**.
3. Put both in one **Subscription Group** (required for upgrade/downgrade/cancel).
4. Submit the subscription metadata (a review screenshot + a description) —
   required even for sandbox in most cases.
5. **Users and Access → Sandbox Testers** → add a tester Apple ID (e.g. a
   dedicated sandbox email, not your real Apple ID). Set its country to one
   where your products exist.

### 2. Google Play Console (Android sandbox)
1. Sign in to https://play.google.com/console.
2. **Monetize → Products → Subscriptions** → create the same two products
   (monthly $9.99, yearly $29.99 with 7-day trial), same IDs as iOS is fine.
3. **Setup → License testing** → add the Google account(s) that will test.
   License testers are never charged.

### 3. RevenueCat (the bridge)
1. Create a project at https://app.revenuecat.com.
2. Add an iOS app (bundle id = your app's) and an Android app (package name = your app's).
3. **Products** → add the App Store and Play product IDs from steps 1–2 with
   their prices.
4. Create one **Entitlement** called `pro` (the backend checks exactly this
   name — `billing/plans.js` `PRO_ENTITLEMENT`). Attach both products to it.
5. Create an **Offering** (default) containing the monthly + yearly packages.
6. **API keys**: copy the *public* SDK key for iOS (`app_...`) and Android.
7. **Webhooks** → add a webhook pointing to
   `https://<your-backend>/api/billing/revenuecat`, with the same Authorization
   value as `REVENUECAT_WEBHOOK_AUTH` on the backend.
8. **Integrations → REST API** → create a *secret* API key
   (`REVENUECAT_SECRET_API_KEY`) for the backend.

### 4. Backend `.env` (JobTrigger-Backend)
```
BILLING_ENABLED=true
REVENUECAT_SECRET_API_KEY=<secret REST key from step 8>
REVENUECAT_WEBHOOK_AUTH=<the webhook auth value from step 7>
```
Restart the backend. `GET /api/subscription` should now show
`billingEnabled: true` and a real plan.

---

## Part B — Run the app with real sandbox purchases

### iPhone (profile build)
```bash
REVENUECAT_IOS_KEY=app_<your public iOS key> scripts/run-on-iphone.sh
```
Passing the key turns preview mode off automatically. Then:
1. Sign out of any real Apple ID on the phone; sign in with the **Sandbox Tester**
   from step 5 when the purchase sheet asks (App Store sign-in prompt).
2. Log in as `tester@jobtrigger.app` / `TesterPass123!` (Free).
3. **Profile → Subscription → Upgrade to Pro** → Subscribe (monthly or yearly).
   No real money is charged; it is a sandbox transaction.
4. After purchase the app calls `POST /api/subscription/refresh` and shows Pro.

### Cancel / resubscribe
- **Cancel**: Subscription screen → **Manage in the App Store** (or Google
  Play) opens the store's subscription page; cancel there. Pro stays until
  the period ends, then becomes Free (backend computes this on each read).
- **Resubscribe**: once Free, **Upgrade to Pro** → Subscribe again, or use
  **Restore purchases** if the store still has an active entitlement.
- Sandbox subscriptions renew on an accelerated schedule (monthly ≈ 5 min,
  yearly ≈ 1 hour), so expiry/downgrade can be observed quickly.

---

## Part C — Verify
- App: paywall shows real store prices; purchase succeeds in sandbox; plan flips to Pro.
- Backend: `GET /api/subscription` returns `plan: pro`, `source: app_store` (or
  `play_store`) after purchase; `free` after cancellation takes effect.
- Webhook: a purchase/cancellation in the store creates a `BillingEvent` row
  and logs `billing.webhook_applied`.

## Part D — Local sandbox with no store accounts (development only)

Until the App Store, Play Console and RevenueCat are configured, a dev run
can exercise the whole billing flow against a local sandbox store. Nothing
is charged, no provider is contacted, and the backend writes the same
`store` source a real purchase would.

1. Backend (`JobTrigger-Backend`), then restart it:

   ```bash
   PORT=5001 BILLING_ENABLED=true SANDBOX_BILLING=true npm run dev
   ```

   `SANDBOX_BILLING` is refused in production, and the routes answer 404
   unless it is on.

2. App, pointing at the backend:

   ```bash
   SANDBOX_BILLING=1 scripts/run-flutter.sh --target=android-device
   # or, on the iPhone:
   SANDBOX_BILLING=1 scripts/run-on-iphone.sh
   ```

3. Sign in as `tester@jobtrigger.app` / `TesterPass123!`. Profile →
   Subscription: the paywall says **Sandbox mode**, both plans offer the
   local `$9.99`/`$29.99` prices, and Subscribe takes no payment.
4. The Subscription screen gains **Sandbox billing**:
   - **Cancel subscription** stops the renewal; Pro stays until the period
     ends (monthly 30 days, yearly 7-day trial then a year).
   - **Simulate expiry** moves the end into the past, so the Free limits and
     the locked-server behaviour appear at once.
   - **Resubscribe** restores Pro, with no new trial.

This mode exists only in development: `AppConfig.billingSandbox` is false in
release builds, and the backend routes are 404 in production. Real Apple and
Google sandbox tests still need Part A above.

## Play Store first release

The 1.0.0 Android release is the first store listing, so use Play's sandbox
first:

1. Play Console → **Setup → License testing**: add the Google account used on
   the test device. License testers are never charged.
2. **Monetize → Products → Subscriptions**: `jobtrigger_pro_monthly`
   ($9.99/month) and `jobtrigger_pro_yearly` ($29.99/year, 7-day free trial),
   both active.
3. RevenueCat → the Play app: attach both products to the `pro` entitlement
   and the default offering. Package identifiers are arbitrary; the app now
   recognises monthly/yearly from the product's own period too, so a custom
   package still shows up.
4. Install the build from Play's internal testing track (a sideloaded debug
   build cannot buy), then run Part B with the license-tester account.

## What I changed in code for this
- Removed the earlier **fake success** simulation (preview purchases fail
  again, honestly).
- `scripts/run-on-iphone.sh` now accepts `REVENUECAT_IOS_KEY` and disables
  preview mode when it is supplied.
- `config/README.md` documents the real-sandbox flow.

The cancel/manage link and Restore already existed in `subscription_screen.dart`
and `store_links.dart`; no new UI was needed.
