# Subscription API Reference (excerpt)

Endpoints related to user entitlements and billing.

| Endpoint | Method | Auth | Response | Notes |
|---|---|---|---|---|
| `/api/subscription` | GET | `x-auth-token` | `{ plan, billingEnabled, status, source, productId, periodEnd, willRenew, manageOnWeb, limits, features, primaryCredentialId }` | P20‑14 (US‑SUB‑01). Clients read `limits` and `features`, never `plan`. `billingEnabled: false` means everyone is Pro. `source` says which one (app store, web, manual grant). `manageOnWeb` true when Paddle portal can manage it. |
| `/api/subscription/refresh` | POST | `x-auth-token` | same as GET | P20‑14. Re‑reads the caller from RevenueCat after a purchase or restore; a RevenueCat outage keeps the stored plan. 10 per 10 min per user. |
| `/api/subscription/primary/:credentialId` | POST | `x-auth-token` | same as GET | P20‑13 (US‑SUB‑05). Which saved server stays usable on Free (any tool). Once per 24 h: **403** `PLAN_LIMIT`, `limit: "primaryCooldown"`. Not the caller’s: 404. |
| `/api/billing/revenuecat` | POST | `Authorization = REVENUECAT_WEBHOOK_AUTH` | `{ ok }` | P20‑16 (US‑SUB‑09). Wrong secret: 401. Each `event.id` applied once (duplicate: 200 `duplicate: true`). Every account the event names is re‑read from RevenueCat; failure: 500 so RevenueCat retries. Body never logged. |
| `/api/billing/paddle/checkout` | POST | `x-auth-token` | `{ transactionId, environment }` | Website checkout (Paddle). Creates a Paddle transaction whose `custom_data.userId` is set by the server; the website opens it with Paddle.js. Already Pro from any source: **409** `ALREADY_SUBSCRIBED` (no double payment). Billing off or Paddle not set up: 503. |

*End of subscription API reference.*