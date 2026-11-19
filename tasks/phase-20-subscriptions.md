# Phase 20 — Subscriptions (epic SUB)

Checklist recount (2026-11-18): **52 of 67** P20 checkbox items are complete;
15 remain open. The release workplan tracks whether billing is enabled for
1.0 and the store, sandbox, and production setup still required.

**Release 1.0.0 owner decisions (2026-11-18, all done in code):**

- [x] P20-86 Prices are **$9.99/month and $29.99/year** (7-day yearly
      trial) in the app's config/preview and the website's pricing content.
- [x] P20-87 Owner `developer@jobtrigger.app` gets a permanent, never-billed
      Pro grant automatically after signup/login (`billing/owner.js`), tied
      to the email rather than the `superAdmin` role.
- [x] P20-88 Tester `tester@jobtrigger.app` starts Free and uses real sandbox
      purchases; new accounts all default to Free with billing on.
- [x] P20-89 `/admin/subscriptions` console: super admin only, lists every
      account's derived plan and sources, grants test Pro for N days or with
      no end, and revokes the grant without touching a paid source.
- [x] P20-90 Web checkout policy recorded: the site may sell to anyone signed
      in, including iPhone users, while the iOS app never links to it.
- [x] P20-91 Docs updated: `docs/subscription/changes.md`, pricing, sandbox
      testing, API reference and the owner checklist.
- [x] P20-92 Tester account replaced: `tester@jobtrigger.app` /
      `TesterPass123!` (Free) via `scripts/ensure-test-accounts.js` and the
      seed; the old `journey1@example.com` account and plan are removed.
- [x] P20-93 Development sandbox store: `/api/billing/sandbox`
      (buy/cancel/resubscribe/expire, 404 in production) plus the app's
      `SANDBOX_BILLING` client and Subscription-screen controls. It charges
      nothing and cannot ship in a release build.
- [x] P20-94 Edge cases from the billing audit: deferred Play purchases are
      reported as pending (not Pro), store refusals get store-specific copy
      (`StoreFailure`), failed payments show "Pro until" plus what to fix,
      trial end dates are labelled, and the sandbox release guard is pinned
      by a test.
- [x] P20-95 `docs/subscription/coverage.md`: the full scenario matrix,
      separating automated coverage, the local sandbox and the real
      Apple/Google sandbox checks that need store accounts.

**Status:** in-progress — P20-00 approved by the owner 2026-11-12; the owner
decided 2026-11-18 that billing ships **enabled** in release 1.0.0. Backend,
app and website tracks are built and merged to `develop`; the code flips,
prices ($9.99 / $29.99), website `subscriptions` status (`live`), owner
grant and hard delete gate are done. What is left is owner setup (stores,
RevenueCat, Paddle sandbox: P20-40..42, P20-85), device and sandbox
verification (P20-51..53) and the production flip (P20-62). Backend
deployment and the stores are on hold.

Docs: [`docs/subscription/`](../docs/subscription/README.md) ·
Stories: [`docs/user-stories/billing/18-subscriptions.md`](../docs/user-stories/billing/18-subscriptions.md).

Branch: `feat/subscriptions` from `develop`, one PR per track (or per
task where a track is large). Commits reference the task id, e.g.
`feat(backend): plan check on credential create [P20-12]`.

## A. Decisions (owner)

- **Working agreement (owner, 2026-11-16):** for the rest of Phase 20,
  each PR's plan and design go in its PR description instead of pausing for
  approval, and each PR is merged once every check is green. Pause only if
  a check fails in a way that can't be fixed, or a decision isn't covered by
  the owner's instructions. The billing-off guarantee stays absolute: with
  no keys, backend `billingEnabled` false, or demo mode, every existing flow
  and test is unchanged.

- [x] P20-00 Approved 2026-11-12, all as written. Approve the plan: Free/Pro split and limits
      (business model §2–3), prices and trial (§4), RevenueCat
      (§5), `purchases_flutter` as a new dependency (add a row to
      CLAUDE.md §3), and the new backend endpoints (technical design §3).
- [x] P20-01 Analytics tool: **Umami**, self-hosted in the DevOps lab
      (`analytics/`), events sent server-side / over HTTP, no SDK. Crash
      reporting (GlitchTip) stays a separate decision. Decided 2026-11-12;
      plan in `docs/configuration.md`.
- [x] P20-02 Email: **Mailpit** for development (lab `mailpit/`),
      `nodemailer` over SMTP (needs approval); production provider chosen
      when the backend deploys. US-AUTH-08 password reset promoted as the
      first use (P20-72..74). Decided 2026-11-12.
- [ ] P20-03 **MANUAL (owner, M-15):** Needs two real sandbox store accounts. RevenueCat "transfer behaviour" when one store account
      restores onto a second JobTrigger account (US-SUB-03).

## B. Launch prerequisites (already tracked elsewhere — linked, not duplicated)

- [ ] P20-05 **MANUAL (owner, M-14):** Deploy the backend (production Atlas, public https URL). Backend deployed at a public `https://` URL with a
      production Atlas cluster (Phase 15 owner actions, Phase 17).
      **On hold** (owner, 2026-11-12): still in development.
- [ ] P20-06 **MANUAL (owner, M-08, M-09):** Store accounts and signing. Store accounts, signing and artwork (`release-checklist.md`).
      **On hold** (owner, 2026-11-12): still in development.
- [ ] P20-07 **MANUAL (owner, M-03, M-06):** Automated and live API parts are done (P8-26/27, P10-14/15); the iPhone checks remain. GitHub and SonarQube real-server checks (P8-26/27,
      P10-14/15) — these are the tools Pro sells.

## C. Backend (backend track — per-item approval)

- [x] P20-10 `billing/plans.js` + `billing/entitlements.js` with
      `BILLING_ENABLED` (default off → everyone Pro); unit tests for every
      status/date case.
- [x] P20-11 `Subscription` and `BillingEvent` models with indexes
      (unique `userId`, unique `eventId`, TTL on events).
- [x] P20-12 Plan check in `makeCredentialController` (`{ tool }` arg;
      `tool` added to `CREDENTIAL_TARGETS`); `403 PLAN_LIMIT` body;
      tests per tool, multi-tool rule, edit/delete never limited.
- [x] P20-13 `locked` flag on credential lists; `setDefault` refuses a
      locked credential; `POST /api/subscription/primary/:id` with a 24 h
      cooldown; tests.
- [x] P20-14 `GET /api/subscription`, `POST /api/subscription/refresh`
      (rate-limited); tests.
- [x] P20-15 `billing/revenuecatClient.js` (built-in `fetch`, injectable
      fake) + `syncSubscription.js`.
- [x] P20-16 `POST /api/billing/revenuecat`: constant-time auth check,
      idempotency, re-read subscriber, never log the body; tests for bad
      auth, duplicates, out-of-order, upstream failure → 500.
- [x] P20-17 `config/env.js`: new variables, refuse to start half-configured
      when billing is enabled; `.env.example` names (no values).
- [x] P20-18 Account deletion removes the subscription + RevenueCat
      customer (best effort, logged).
- [x] P20-19 `scripts/grant-plan.js` (local-only guard) for admin/promo
      grants; `docs/api-reference.md` and `docs/database-migrations.md`
      updated.

Backend track notes (2026-11-12): tests in `test/billing.test.js`; the
database-backed ones run on the Mac. New optional variables (add the
names to `.env.example` by hand, CLAUDE.md §8): `BILLING_ENABLED`,
`REVENUECAT_SECRET_API_KEY`, `REVENUECAT_WEBHOOK_AUTH`,
`SUBSCRIPTION_REFRESH_RATE_LIMIT`, `BILLING_WEBHOOK_RATE_LIMIT`, and the
development-only `SANDBOX_BILLING` (refused in production).

## D. Mobile app

- [x] P20-20 (2026-11-16, PR A; Android build and a real purchase unverified) Add `purchases_flutter`; SDK keys in `config/*.json` via
      `app_config.dart`; `BillingClient` interface + RevenueCat impl
      (only file importing the SDK).
- [x] P20-21 (2026-11-16, PR A) Domain: `Entitlements`, `SubscriptionStatus`,
      `BillingOffer`, `SubscriptionRepository`; data: DTO (freezed) +
      repository impl; `PlanLimitFailure` and `PurchaseCancelled` as new
      `AppFailure` cases (existing copy untouched).
- [x] P20-22 (2026-11-16, PR A; nothing reads it until PR B/C, so no extra request yet) `EntitlementsNotifier` (keepAlive, cached in
      `user_scoped_prefs`, refreshed on sign-in / resume / purchase);
      RevenueCat `logIn`/`logOut` driven by auth state.
- [x] P20-23 (2026-11-16, PR B; store sheet and real prices unverified until RevenueCat keys exist) Paywall screen + notifier (store prices, trial, auto-renew
      text, Terms/Privacy, Restore, reason-aware headline); route
      `/paywall`.
- [x] P20-24 (2026-11-16, PR B) Profile → Subscription section (US-SUB-01, manage link,
      restore); route `/profile/subscription`.
- [x] P20-25 (2026-11-16, PR C; paywall opening from the real screens and the native widget's upgrade copy unverified until a device run) Gates (technical design §4.3): add-server forms, tool
      switch, locked credential rows, background watch, widget, pinned
      jobs, insights. Each gate gets a notifier test. One `PlanGate`
      (`plan_gate.dart`) decides; it blocks nothing unless billing is
      available (key + `billingEnabled` + not demo), so with billing off every
      flow is as before. Blocked actions open `/paywall?reason=<limit>`. A
      locked *active* credential is replaced by the first unlocked one (or
      none), its cached secret deleted, and the paywall opens with `locked`
      the next time the tool is opened (`locked_active_guard.dart`).
- [x] P20-26 (2026-11-16, PR B) Delete-account dialog warns about an active store
      subscription (US-SUB-07).
- [x] P20-27 (2026-11-16, PR B) `ios/Runner/PrivacyInfo.xcprivacy`, App Privacy answers and
      Play Data safety updated for purchases. The manifest entries (Purchase
      History, User ID) and the Play Data safety text in `release-checklist.md`
      are done; entering the answers in the two stores is an owner action.

## E. Website

- [x] P20-30 (2026-11-16) Analytics events wired on the site: `signup`,
      `server_added`, `pricing_view` and `limit_hit` (with the backend's
      `limit`). The app sends none — the owner decision in
      `docs/configuration.md` §4.2 — so the app-only
      rows (paywall view, purchase, restore) are unsent by design;
      purchase outcomes still come from the store webhooks.
- [x] P20-31 (2026-11-16, PR D) `server/subscription-api.ts` + `PlanLimitFailure` copy in
      `domain/app-failure.ts`; add-server form shows the plan limit.
- [x] P20-32 (2026-11-16, PR D) Account page: plan, dates, manage-in-store instructions.
- [x] P20-33 (2026-11-16, PR D) `/pricing` from `src/content/pricing.ts` (tested), header,
      footer, sitemap; comparison wording per competitive analysis §7.2.
- [x] P20-34 (2026-11-16, PR D; legal wording is a draft for legal review, like the rest of the policy) Terms and Privacy updated for subscriptions and RevenueCat.

## F. Store and RevenueCat setup (owner)

- [ ] P20-40 **MANUAL (owner, M-15):** App Store Connect: Paid Apps agreement, tax, banking (check
      Sri Lanka payout details), subscription group + 2 products, 7-day
      trial on yearly, **Small Business Program enrolment**.
- [ ] P20-41 **MANUAL (owner, M-15):** Play Console: payments profile, subscription with monthly
      and yearly base plans, trial offer on yearly.
- [ ] P20-42 **MANUAL (owner, M-15):** RevenueCat: project, both apps, entitlement `pro`, offering
      `default`, webhook URL + secret, sandbox testers.

## G. Verification

- [x] P20-50 (2026-11-16, on develop after PR E) Whole suite clean: `flutter analyze` (no issues),
      `flutter test` (1327), `npm test` backend (289) and web (310), Playwright
      (182), `flutter build ios --profile --no-codesign`, gitleaks over the whole
      history. Not run on a device or against real RevenueCat/Paddle (P20-51/52/85).
- [ ] P20-51 **MANUAL (owner, M-15):** iPhone sandbox pass via `scripts/run-on-iphone.sh`
      (CLAUDE.md §10): buy, trial, accelerated renewal, cancel, restore on
      a second install, downgrade locking.
- [ ] P20-52 **MANUAL (owner, M-02, M-15):** Android sandbox pass with a Play license tester (blocked on
      a physical Android device, like P11-03).
- [ ] P20-53 **MANUAL (owner, M-15):** Owner decides to commission the third audit scope (billing code needs the owner's go-ahead). Security review of the webhook and plan checks (third audit
      scope, small): auth, idempotency, `userId` scoping, logging.

## H. Launch

- [ ] P20-60 **MANUAL (owner, M-15):** Staging with `BILLING_ENABLED=true`; TestFlight + Play
      internal testers.
- [ ] P20-61 **MANUAL (owner, M-15):** Grant Pro to owner and early testers (`grant-plan.js`).
- [ ] P20-62 **MANUAL (owner, M-15):** Production: flip `BILLING_ENABLED=true` with the real
      RevenueCat/Paddle secrets (the website's `subscriptions` status and Pro CTA are already
      live in code), announce in the changelog.
- [ ] P20-63 **MANUAL (owner, M-15):** After ~200 paywall views: review conversion and price
      (`docs/subscription/docs/pricing.md`).

## I. Email and analytics (plan: `docs/configuration.md`)

Local development first (backend and stores on hold). Each item still
needs its plan approved before code (CLAUDE.md §9).

- [x] P20-70 Lab services: Umami (`analytics/`, port 3004, data in the lab
      Postgres) and Mailpit (`mailpit/`, SMTP 1025, inbox 8025) added to
      `custom-devops-stack` by its rules. Not yet started on the Mac.
- [x] P20-71 Approve `nodemailer` (backend) — approved by the owner
      2026-11-12; CLAUDE.md §3 row added.
- [x] P20-72 Backend mailer (`lib/mailer.js`, SMTP config validated in
      `config/env.js`, disabled when unset, fake transport in tests).
      Done 2026-11-12 on `feat/password-reset-email`.
- [x] P20-73 Password reset endpoints + `PasswordResetToken` model
      (US-AUTH-08): no enumeration, 15-minute single-use hashed tokens,
      rate limits, `tokenVersion` bump; `test/password_reset.test.js`.
      **Unverified:** the database-backed suite needs `npm install` and
      `npm test` on the Mac (in-memory MongoDB couldn't download here).
- [x] P20-74 Password reset is **web only** (owner decision 2026-11-12).
      Website: `/forgot-password`, `/reset-password` (no-store,
      `no-referrer`); the sign-in "Forgot?" link and support FAQ switch to
      them when `password-reset` turns `live`. App: no reset screens; the
      login screen's "Forgot password? Reset it on the web" opens
      `<WEBSITE_BASE_URL>/forgot-password` in the browser (new
      `WEBSITE_BASE_URL` config key; `run-on-iphone.sh` writes the Mac's
      address). The email has one link, to the website.
- [x] P20-75 Event catalogue as code: backend `lib/analyticsEvents.js`,
      web `domain/analytics-events.ts`. Same names and data rules.
- [x] P20-76 ~~App analytics~~ **Dropped** (owner decision 2026-11-12):
      analytics is website and backend only; the mobile app sends no usage
      data. The app code built for it was removed again.
- [x] P20-77 Website `server/analytics.ts` from server actions (no browser
      script, CSP unchanged). Events wired: `signup`, `server_added`.
- [x] P20-78 Backend `lib/analytics.js` for webhook/auth events (no-op
      without Umami config, fire-and-forget, catalogue only). Tested.
- [x] P20-79 Privacy policy on the website: anonymous server-side usage
      counts (website only, the app sends none) and account email. The
      app's `PrivacyInfo.xcprivacy` is unchanged: the app collects no new
      data. (Store privacy answers stay as they were.)

## J. Website checkout with Paddle (US-SUB-10, promoted 2026-11-12)

Owner decision 2026-11-12: people can subscribe in the app (App Store /
Google Play via RevenueCat) **or** on the website (Paddle, merchant of
record: Stripe doesn't accept Sri Lanka-based businesses, Paddle does and
pays out by wire or Payoneer). The backend owns the plan, so either way
the app and site see the same Pro.

- [x] P20-80 Subscription sources: `store`, `web`, `grant` kept apart,
      plan derived as the best of them (`billing/combine.js`), so a store
      sync can't cancel a web subscription or the reverse.
- [x] P20-81 Paddle config (`PADDLE_API_KEY`, `PADDLE_WEBHOOK_SECRET`,
      `PADDLE_PRICE_MONTHLY`, `PADDLE_PRICE_YEARLY`, `PADDLE_ENV`),
      `billing/paddleClient.js`, `billing/paddle.js` (signature, mapping).
- [x] P20-82 `POST /api/billing/paddle/webhook` (raw body, signature,
      once per event, stale events ignored), `/checkout` (server-set
      user id, 409 when already Pro), `/portal`; deleting an account
      cancels a renewing web subscription. Tests: `test/paddle.test.js`.
- [x] P20-83 (2026-11-16, PR E; Paddle's real checkout, portal and CSP hosts unverified until the P20-85 sandbox exists) Website: `/pricing`, account billing page (plan, Upgrade →
      Paddle.js overlay, Manage → portal), CSP allowance for Paddle on
      the billing page only, zod-parsed BFF calls.
- [x] P20-84 (2026-11-16, PR B) App: show a web subscription as Pro and hide the store
      purchase for it (with P20-23/24).
- [ ] P20-85 **MANUAL (owner, M-15):** Owner: Paddle sandbox account, Pro product with monthly and
      yearly prices, default payment link domain approved, notification
      destination → `/api/billing/paddle/webhook` (subscription events),
      client-side token for the website. Then live account verification
      and payout details (wire or Payoneer).

## Later (not this phase)
- Team plan (US-SUB-11), its own phase and audit.
