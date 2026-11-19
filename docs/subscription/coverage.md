# Subscription and billing coverage

What is implemented and how it is checked, for release 1.0.0. This is the
answer to "are all the scenarios covered?": code and backend behaviour are
covered by automated tests; the two real store sandboxes cannot be exercised
from the repository and are listed as manual.

Legend:

- **✅ automated** — a backend or Flutter test asserts the behaviour.
- **🧪 sandbox** — the dev-only local sandbox store exercises the same path
  with no payment (Part D of `sandbox-testing.md`).
- **📱 manual** — needs a store account, a real device, or both.
- **⛔ not supported** — deliberate, with the reason.

## Plans and accounts

| Scenario | Status | Where |
|---|---|---|
| New account starts Free with billing on | ✅ | `billing.test.js` (Free limits) |
| Billing off gives everyone Pro, unchanged | ✅ | `billing.test.js` |
| Owner `developer@jobtrigger.app` permanent Pro, never billed | ✅ | `billing.test.js` (signup and login) |
| Owner grant is per email, not the admin role | ✅ | `billing.test.js` |
| Other accounts never receive the owner grant | ✅ | `billing.test.js` |
| Tester `tester@jobtrigger.app` / `TesterPass123!`, Free | ✅ | `test_accounts.test.js` |
| Old `journey1@example.com` removed with its plan | ✅ | `test_accounts.test.js` |
| Admin grant/revoke with days or no end | ✅ | `admin_subscriptions.test.js` |
| Revoke never touches a paid store/web source | ✅ | `admin_subscriptions.test.js` |
| Admin routes are a 404 for non-admins | ✅ | `admin_subscriptions.test.js` |
| Grant/revoke takes effect without re-login | ✅ | `admin_subscriptions.test.js` |

## Lifecycle

| Scenario | Status | Where |
|---|---|---|
| Monthly active, yearly with 7-day trial | ✅ | `billing.test.js`, `sandbox_billing.test.js` |
| Cancelled keeps Pro until the period ends | ✅ | `billing.test.js`, `sandbox_billing.test.js` |
| Expiry drops to Free | ✅ | `billing.test.js`, `sandbox_billing.test.js` |
| Resubscribe while cancelled / after expiry | ✅ 🧪 | `sandbox_billing.test.js`; real store 📱 |
| Grace period keeps Pro, then expires | ✅ | `billing.test.js` |
| Failed payment (`billing_issue`) keeps Pro | ✅ | `billing.test.js` |
| Refund ends Pro | ✅ | `billing.test.js` |
| Lifetime/no-expiry entitlement is Pro | ✅ | `billing.test.js` |
| Deferred/pending store purchase is not shown as Pro | ✅ | `paywall_notifier_test.dart`, `paywall_screen_test.dart` |
| Downgrade locks extra servers, deletes nothing | ✅ | `billing.test.js` |
| Free keeps one chosen server, 24 h cooldown | ✅ | `billing.test.js` |
| Editing/deleting is never plan-limited | ✅ | `billing.test.js` |
| Owner/tester cannot be charged by accident | ✅ | web checkout 409 in `paddle.test.js` |

## Sources and cross-platform

| Scenario | Status | Where |
|---|---|---|
| Store, web, grant and student sources coexist | ✅ | `paddle.test.js`, `billing.test.js` |
| An empty store record never cancels web/grant | ✅ | `paddle.test.js` |
| Pro from the website is Pro in the app | ✅ | `billing.test.js`, widget tests |
| Pro from a store wins over a student year | ✅ | student tests, `combine.js` |
| Old top-level admin grant is preserved | ✅ | `paddle.test.js` |
| One account's Pro works on every platform | ✅ | backend is the source of truth |
| Buying a second plan on the web while Pro | ✅ | `paddle.test.js` (409) |
| Buying on Apple **and** Google with one account | 📱 | stores allow it; the backend picks the best source. No automatic cross-store cancellation (store rules) |

## Store SDK and app

| Scenario | Status | Where |
|---|---|---|
| Offers map when RevenueCat packages are custom, not monthly/annual | ✅ | `_periodOf` fallback (product period and id) |
| Trial days from the store's introductory offer | ✅ | `_trialDays` |
| No offers / offers fail to load | ✅ | `paywall_screen_test.dart` |
| The user closes the store sheet (silent cancel) | ✅ | `paywall_notifier_test.dart` |
| Store refusal (not signed in, no payment method) | ✅ | `StoreFailure` copy, repository test |
| Backend unreachable after a successful purchase | ✅ | `paywall_notifier_test.dart` |
| Restore finds Pro / finds nothing | ✅ | `paywall_notifier_test.dart` |
| Web Pro: no buy button and no web link | ✅ | `paywall_screen_test.dart`, `subscription_screen_test.dart` |
| Cancelled store plan shows Resubscribe; the paywall keeps offers | ✅ | `subscription_screen_test.dart`, `paywall_screen_test.dart` |
| Failed payment copy and "Pro until" date | ✅ | `subscription_screen_test.dart` |
| Trial shows "Trial ends" | ✅ | `subscription_screen_test.dart` (date labels) |
| Store manage link (App Store, Google Play with package) | ✅ | `store_links.dart` |
| Billing hidden with no key, demo mode or billing off | ✅ | `billing_availability_test.dart` |
| Sandbox mode in a release build is impossible | ✅ | `app_config_test.dart` |
| Sandbox buy/cancel/expire/resubscribe | ✅ 🧪 | sandbox tests + widget test |
| Real Apple purchase, trial, cancel, resubscribe, restore on a second install | 📱 | `sandbox-testing.md` Part A/B |
| Real Google Play purchase, license tester, cancel, resubscribe, restore | 📱 | `sandbox-testing.md` Part A/B and the Play runbook |
| RevenueCat transfer between two JobTrigger accounts | 📱 | P20-03; both sides are re-read, tested at the pure level |

## Backend and security

| Scenario | Status | Where |
|---|---|---|
| RevenueCat webhook wrong/missing secret | ✅ | `billing.test.js` |
| Duplicate webhook applied once | ✅ | `billing.test.js` |
| Provider failure releases the event for retry | ✅ | `billing.test.js` |
| Anonymous/transfer events handled safely | ✅ | `billing.test.js` |
| Paddle signature, stale and out-of-order events | ✅ | `paddle.test.js` |
| Paddle checkout ties the transaction to the caller | ✅ | `paddle.test.js` |
| Paddle portal only for web subscribers | ✅ | `paddle.test.js` |
| Account deletion blocked while paid | ✅ | `billing.test.js`, `paddle.test.js` |
| Deleting cancels a renewing web subscription | ✅ | `billing.test.js`, `paddle.test.js` |
| Deleting removes the RevenueCat customer | ✅ | `billing.test.js` |
| Webhook bodies never logged | ✅ | controller code and tests |
| Sandbox routes 404 unless explicitly enabled | ✅ | `sandbox_billing.test.js` |
| Sandbox refused in production | ✅ | `sandbox_billing.test.js` |
| Billing enabled needs a source (store, web or sandbox) | ✅ | `billing.test.js` |
| Rate limits on refresh and webhooks | ✅ | `rate_limit.test.js` |

## Explicitly not supported

- **Team plan / seats** — later phase (US-SUB-11).
- **Automatic cancellation across stores** — Apple/Google require the user to
  cancel in the store that charged them.
- **Web checkout links inside the iOS app** — App Review; the website is
  available only when the user opens it themselves.
- **In-app invoice list** — store receipts live in the store account; web
  invoices are in Paddle's portal.

## What must still be done on real accounts

1. App Store Connect and Play Console products at $9.99 / $29.99, yearly trial.
2. RevenueCat project, both apps, `pro` entitlement, default offering,
   webhook, secret key, sandbox testers.
3. Paddle sandbox products and webhook destination.
4. `BILLING_ENABLED=true` with the store/web secrets in production.
5. Device passes: buy, trial, cancel, resubscribe, restore, downgrade, and
   the RevenueCat transfer case (P20-51..53).
