# Subscription technical design

**Date:** 2026-11-12 · **Status:** proposal, for approval at P20-00.
Follows `CLAUDE.md` (layers, `Result<T, AppFailure>`, locked stack,
"earlier development must keep working") and
[`docs/web-architecture.md`](../web-architecture.md). Plans and limits
come from [`02-business-model.md`](02-business-model.md) §3.

## 1. Principles

1. **The backend decides the plan.** The app and website ask the backend
   "what may this user do?" and never decide it themselves. RevenueCat
   tells the backend; the backend stores it.
2. **Enforce on the server what the server owns.** Saving credentials
   goes through the backend, so the server limits are real limits. Every
   other gate (widget, background watch) is in the app, because the
   backend never sees that traffic (workspace analysis §3).
3. **Never destroy data on downgrade.** Extra servers become *locked*,
   not deleted. Upgrading again unlocks them instantly.
4. **Never paywall security.** App lock, sign out everywhere, change
   password and delete account stay free.
5. **Fail open for paying users, closed for limits.** If the plan can't
   be loaded, the app uses the last known plan (cached); if there is
   none, it assumes Free. A webhook that fails is retried by RevenueCat;
   the app's own "refresh" also re-syncs from RevenueCat.
6. **Shared code changes by addition** (CLAUDE.md §11): a new
   `PlanLimitFailure` case, not edits to existing failure copy.

## 2. Architecture

```text
            ┌──────────── purchase / restore ────────────┐
 Phone app ─┤                                            ▼
 (purchases_│                                 App Store / Google Play
  flutter)  │                                            │
            │                                       RevenueCat
            │                                   (receipts, renewals)
            │                                            │ webhook (event)
            │  GET /api/subscription                     ▼
            └──────────────────────────────▶ Backend ◀── GET /v1/subscribers/:id
 Website (BFF) ── GET /api/subscription ───▶   │        (re-read the truth)
                                               ▼
                                   MongoDB: subscriptions, billing_events
```

- **Identity:** RevenueCat's `appUserID` is the backend user `_id`
  (an ObjectId — no email or name goes to RevenueCat). The app calls
  `Purchases.logIn(userId)` after sign-in and `Purchases.logOut()` on
  sign-out, so a purchase always belongs to the signed-in account and
  follows it to Android, iOS and the website.
- **Truth on webhook:** the webhook body is only a signal. The backend
  then calls RevenueCat's REST API for that subscriber and stores what it
  returns, so out-of-order or duplicate events can't leave a wrong plan.

## 3. Backend (`JobTrigger-Backend/`)

No new npm dependency: the RevenueCat REST call uses Node's built-in
`fetch`.

### 3.1 New files

| File | Purpose |
|---|---|
| `billing/plans.js` | The entitlements matrix as data: `PLANS.free`, `PLANS.pro`, keys from the business model §3. One place to change a limit. |
| `billing/entitlements.js` | `entitlementsFor(userId)` → `{ plan, status, limits, features, periodEnd, willRenew, source }`. Applies `BILLING_ENABLED` and grace periods. |
| `billing/revenuecatClient.js` | `getSubscriber(appUserId)`, `deleteSubscriber(appUserId)`. Injected, so tests use a fake. |
| `billing/syncSubscription.js` | Maps a RevenueCat subscriber to our `Subscription` document. |
| `models/Subscription.js` | One per user (below). |
| `models/BillingEvent.js` | Received webhook ids, for idempotency and audit (unique `eventId`, TTL 180 days). |
| `controllers/subscriptionController.js` | `GET /api/subscription`, `POST /api/subscription/refresh`. |
| `controllers/billingWebhookController.js` | `POST /api/billing/revenuecat`. |
| `routes/subscriptionRoutes.js`, `routes/billingRoutes.js` | Wiring, rate limits. |
| `scripts/grant-plan.js` | Local-only (`scripts/localOnly.js` guard) grant of Pro to a user, for the owner and testers (`source: "admin"`). |

### 3.2 Data model

```js
// models/Subscription.js
{
  userId:     { type: ObjectId, ref: 'User', required: true, unique: true },
  plan:       { type: String, enum: ['free', 'pro'], default: 'free' },
  status:     { type: String, enum: ['none', 'trialing', 'active', 'grace',
                'billing_issue', 'cancelled', 'expired'], default: 'none' },
  source:     { type: String, enum: ['app_store', 'play_store', 'web', 'promo', 'admin'] },
  productId:  String,          // e.g. "jobtrigger_pro_yearly"
  periodEnd:  Date,            // current period / trial end
  willRenew:  Boolean,
  updatedFromEventAt: Date,    // newest event applied, guards against old ones
  primaryCredentialId: ObjectId, // the one server kept unlocked on Free (§3.4)
  primaryChangedAt:    Date,     // 24 h cooldown on switching it
}, { timestamps: true }
```

A user with no document is Free. `cancelled` with a future `periodEnd`
is still Pro until that date (the user paid for the period).

### 3.3 Endpoints

All responses use the existing error shapes and request ids.

**`GET /api/subscription`** — auth (`x-auth-token`).

```json
{
  "plan": "pro",
  "status": "trialing",
  "source": "app_store",
  "periodEnd": "2026-11-19T10:00:00.000Z",
  "willRenew": true,
  "limits":   { "maxCredentialsTotal": null, "maxCredentialsPerTool": 25, "maxPinnedJobs": null },
  "features": { "multiTool": true, "backgroundWatch": true, "homeWidget": true, "insights": true }
}
```

`null` means unlimited. Clients read `limits`/`features`, never `plan`,
so a limit can change without an app release (gap G8).

**`POST /api/subscription/refresh`** — auth. Re-reads RevenueCat for the
caller and returns the same body. The app calls it right after a purchase
or restore so the user doesn't wait for the webhook. Rate-limited (e.g.
10 per 10 minutes per user).

**`POST /api/billing/revenuecat`** — no JWT. RevenueCat sends a fixed
`Authorization` header value we configure; compare it in constant time
with `REVENUECAT_WEBHOOK_AUTH`. Steps: verify header → insert
`BillingEvent` (duplicate id → `200` and stop) → `getSubscriber` →
`syncSubscription` → `200`. Errors return `500` so RevenueCat retries.
Never log the body (it holds store transaction ids); log event type, id
and request id.

### 3.4 Enforcing limits on credentials

`makeCredentialController(Model, fields)` gains a third argument,
`{ tool }` (`'jenkins' | 'github' | 'sonarqube'`). Its `create` handler
runs one check before saving:

```text
ent = entitlementsFor(userId)
counts = count credentials per tool across CREDENTIAL_TARGETS for userId
if !ent.features.multiTool and user has credentials for another tool → 403 PLAN_LIMIT multiTool
if ent.limits.maxCredentialsTotal  and total      >= limit → 403 PLAN_LIMIT maxCredentialsTotal
if ent.limits.maxCredentialsPerTool and counts[tool] >= limit → 403 PLAN_LIMIT maxCredentialsPerTool
```

Response:

```json
{ "message": "Your plan allows 1 saved server. Upgrade to Pro to add more.",
  "code": "PLAN_LIMIT", "limit": "maxCredentialsTotal" }
```

`update`, `remove` and `setDefault` are not limited (a user can always
edit or delete what they have). `CREDENTIAL_TARGETS` gains a `tool` field
so the count and the factory share one list.

**Locked credentials after a downgrade.** `list` adds `locked: true` to
every credential beyond the allowance. The one kept usable is the
user's *primary* credential (`Subscription.primaryCredentialId`; when
unset, the oldest credential). `setDefault` on a locked credential
returns `403 PLAN_LIMIT` —
on Free, switching *which* server is unlocked happens through a small
`POST /api/subscription/primary/:credentialId` (once per 24 h) so Free
can't be used as unlimited by switching back and forth.

### 3.5 Config (`config/env.js`)

| Variable | Required | Meaning |
|---|---|---|
| `BILLING_ENABLED` | no (default `false`) | `false`: everyone gets Pro entitlements (dev, beta, before launch). `true`: plans apply. Our feature flag for the paywall. |
| `REVENUECAT_SECRET_API_KEY` | when billing enabled | Server-side REST key. Never sent to clients. |
| `REVENUECAT_WEBHOOK_AUTH` | when billing enabled | The webhook's shared secret. |

`invalidConfig()` refuses to start with `BILLING_ENABLED=true` and either
key missing, matching AUD-25's "refuse to start half-configured".

### 3.6 Account deletion

`deleteAccount` additionally deletes the `Subscription` and calls
`deleteSubscriber` (best effort, logged on failure). **Deleting an
account doesn't cancel a store subscription** — only the user can do that
in their store settings. The app and website show that notice before
confirming deletion, with a "Manage subscription" link (Apple requires
this).

## 4. Mobile app (`JobTrigger-Frontend/`)

### 4.1 New dependency — needs approval (CLAUDE.md §3)

| Package | Why | Scope |
|---|---|---|
| `purchases_flutter` (RevenueCat) | In-app purchase on both stores, restore, offerings | Only `data/billing/`; nothing else imports it |
| `purchases_ui_flutter` | **Not used.** The paywall is our own widget, in the Phase 14 design system. | — |

Public SDK keys (one per platform) go in `config/*.json` via
`--dart-define-from-file`, read through `core/config/app_config.dart`
like the backend URL. They're public keys, but stay out of the source.

### 4.2 Layers

```text
lib/
  domain/subscription/
    entitlements.dart            Plan, Entitlements (limits + features), free() default
    subscription_status.dart     status, periodEnd, willRenew, source
    subscription_repository.dart load(), refresh(), offerings(), purchase(pkg), restore()
    billing_offer.dart           price string, period, trial — store-agnostic
  data/billing/
    billing_client.dart          interface over the RevenueCat SDK (fake in tests)
    revenuecat_billing_client.dart
  data/models/subscription/subscription_dto.dart     @freezed, from GET /api/subscription
  data/repositories/subscription_repository_impl.dart
  presentation/features/subscription/
    entitlements_notifier.dart   keepAlive; loads on sign-in, app resume, after purchase
    paywall_screen.dart          monthly/yearly, trial, terms, restore
    paywall_notifier.dart        purchase → POST /refresh → update entitlements
    plan_gate.dart               PlanGate(feature:, child:, lockedBuilder:)
    subscription_section.dart    in Profile: plan, renews/ends on, manage, restore
  core/error/app_failure.dart    + PlanLimitFailure(limit), + PurchaseCancelled (silent)
```

- `EntitlementsNotifier` caches the last good value in
  `user_scoped_prefs` (non-secret), so the app starts with the right
  gates offline.
- Purchase flow: `BillingClient.purchase` → on success
  `POST /api/subscription/refresh` → `EntitlementsNotifier.set`. A user
  cancelling the store sheet is `PurchaseCancelled`, shown as nothing.
- `RevenueCat logIn/logOut` is driven from the auth notifier's state, in
  the data layer, not in widgets.

### 4.3 Where the gates go

| Feature | File(s) | Free behaviour |
|---|---|---|
| Add server / account | `settings/*_form_notifier.dart` | Pre-check `limits`; on submit, map `403 PLAN_LIMIT` → `PlanLimitFailure` → paywall sheet. |
| Switch tool | `tool_selection/active_tool_notifier.dart` | Tools other than the one in use show a "Pro" badge; tap → paywall. |
| Locked credentials | `active_server_gate.dart`, credential lists | Locked rows greyed with "Pro" badge; can still edit/delete. |
| Background watch | `notifications/build_watch_notifier.dart`, `background_watch.dart` | "Notify me" opens the paywall; existing watches stop being scheduled after downgrade. |
| Home widget | `home_widget/home_widget_sync.dart` | Widget shows "Upgrade to Pro to use the widget" snapshot. |
| Pinned jobs | `home/pinned_jobs_notifier.dart` | 4th pin → paywall; existing pins beyond 3 stay visible, read-only. |
| Insights | `history/build_trends_card.dart`, `nodes/`, `queue/`, `home/views_notifier.dart` | Teaser card with "Pro". |

Routes: `AppRoutes.paywall = '/paywall'` (modal, carries the reason, e.g.
`?reason=maxCredentialsTotal`, so the headline matches what the user
tried), `AppRoutes.subscription = '/profile/subscription'`.

### 4.4 Paywall requirements (store review)

Both stores reject paywalls that miss these, so they're acceptance
criteria, not polish:

- Price, billing period and what the trial converts to, in the store's
  localised price string (never a hard-coded "$3.99").
- "Auto-renews until cancelled; cancel any time in your App Store /
  Google Play settings."
- Links to Terms of Use and Privacy Policy (already in `AppInfo`).
- A visible **Restore purchases** action.
- No link or wording pointing iOS users to buy on the website until the
  current App Review rules for the user's region have been checked
  (Phase 21).

## 5. Website (`JobTrigger-Web/`)

Phase 20 (no web checkout):

- `src/server/subscription-api.ts` (`server-only`, zod-parsed) →
  `Result<Subscription, AppFailure>`.
- `domain/app-failure.ts` + `PlanLimitFailure`, same copy as the app.
- Add-server form shows the plan-limit message with "Upgrade in the
  JobTrigger app" instead of a generic error.
- Account page: plan, renewal date, source, and "Manage in App Store /
  Google Play" instructions.
- Marketing: a `/pricing` page driven by `src/content/pricing.ts`
  (one list, tested, like `feature-status.ts`); header and footer links;
  `sitemap.ts`.
- Terms and Privacy: subscriptions, auto-renewal, refunds handled by the
  store, RevenueCat as a processor (only the account id is shared).

Phase 21 (web checkout): a merchant of record with Sri Lanka payouts
(business model §5). Prefer routing it through RevenueCat if it supports
that provider, so there's still one subscriber record; otherwise add
`POST /api/billing/<provider>` beside the RevenueCat webhook, writing
the same `Subscription` with `source: "web"`.

## 6. Store setup (owner, outside the code)

- App Store Connect: Paid Applications agreement, tax and banking;
  subscription group "JobTrigger Pro" with `jobtrigger_pro_monthly` and
  `jobtrigger_pro_yearly`; 7-day free trial intro offer on yearly;
  enrol in the **Small Business Program**.
- Play Console: merchant/payments profile; subscription `jobtrigger_pro`
  with base plans `monthly` and `yearly`, trial offer on yearly.
- RevenueCat: project, both apps, entitlement `pro`, offering `default`
  (monthly + yearly packages), webhook URL + auth header, sandbox testers.
- Privacy: App Store "App Privacy" → Purchases; Play "Data safety" →
  Purchase history; re-check `ios/Runner/PrivacyInfo.xcprivacy` (the
  release checklist already asks for this).

## 7. Testing

| Level | What | How |
|---|---|---|
| Backend unit | `entitlementsFor` for every status/date combination; `BILLING_ENABLED=false` | mocha, fake clock |
| Backend API | Limit per tool, multi-tool rule, locked flags, setDefault on locked, primary switch cooldown | supertest + in-memory Mongo |
| Backend webhook | Bad auth 401; duplicate event id ignored; old event doesn't overwrite newer state; RevenueCat outage → 500 | fake `revenuecatClient` |
| App unit | `EntitlementsNotifier` (cache, refresh, sign-out clears), `PaywallNotifier` (success, cancel, failure), each gate | `mocktail` fake `BillingClient`, existing repository fakes |
| App widget | Paywall shows store price strings, trial text, terms, restore; locked server row | `flutter_test` |
| Web | `subscription-api` parsing; plan-limit copy; pricing page content test | Vitest; Playwright with the fake backend extended |
| Sandbox | Buy, renew (accelerated), cancel, refund, restore on a second device | iPhone with a Sandbox Apple Account via `scripts/run-on-iphone.sh` (CLAUDE.md §10); Play license tester on Android |
| Regression | Whole suite before every PR | `flutter analyze`, `flutter test`, `npm test` (backend + web) |

Unverifiable in development (real money, real renewals) is marked
unverified per CLAUDE.md §11 and moved to the release checklist.

## 8. Rollout

1. Ship everything with `BILLING_ENABLED=false` → everyone is Pro;
   the paywall code path is live but never shown.
2. TestFlight / Play internal: flip to `true` on a staging backend;
   testers buy with sandbox accounts.
3. Grant the owner and early testers Pro with `scripts/grant-plan.js`
   (`source: "admin"`, optional end date) as a thank-you.
4. Production launch with `true`. Because the app has never been public,
   no existing user loses a feature.

## 9. Security notes

- Webhook secret compared in constant time; webhook rate-limited; body
  never logged; events stored without receipts.
- The REST key lives only on the backend (same handling as
  `CREDENTIALS_ENCRYPTION_KEY`; not in `.env.example` values).
- Plan checks run after `auth` middleware, scoped by `req.user.id` only
  (AUD-24 pattern) — a client can't pass someone else's id.
- `GET /api/subscription` responses get `Cache-Control: no-store` on the
  website, like the rest of the portal.

## 10. Later: Team plan (not in Phase 20)

Needs an `Organization` (members, roles, seats) that owns credentials,
credential sharing without exposing secrets to members who shouldn't
see them, per-seat billing, and an admin page in the portal. It changes
`userId`-scoped queries everywhere (AUD-24), so it's its own phase with
its own audit, after Pro has paying users.
