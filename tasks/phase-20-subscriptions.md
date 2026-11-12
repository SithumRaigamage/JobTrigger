# Phase 20 — Subscriptions (epic SUB)

**Status:** todo — proposed 2026-11-12, **not approved**. Nothing below
starts until P20-00 is signed off (CLAUDE.md §9: plan → approval → build).

Docs: [`docs/subscription/`](../docs/subscription/README.md) ·
Stories: [`docs/user-stories/billing/18-subscriptions.md`](../docs/user-stories/billing/18-subscriptions.md).

Branch: `feat/subscriptions` from `develop`, one PR per track (or per
task where a track is large). Commits reference the task id, e.g.
`feat(backend): plan check on credential create [P20-12]`.

## A. Decisions (owner)

- [ ] P20-00 Approve the plan: Free/Pro split and limits
      (business model §2–3), prices and trial (§4), RevenueCat
      (§5), `purchases_flutter` as a new dependency (add a row to
      CLAUDE.md §3), and the new backend endpoints (technical design §3).
- [ ] P20-01 Choose the analytics / crash tool (unblocks gap G3; moves
      the `backlog.md` crash-reporting item into scope).
- [ ] P20-02 Choose an email provider; promote US-AUTH-08 password reset
      out of `backlog.md` (gaps G2, G5). Paid users can't be left locked out.
- [ ] P20-03 RevenueCat "transfer behaviour" when one store account
      restores onto a second JobTrigger account (US-SUB-03).

## B. Launch prerequisites (already tracked elsewhere — linked, not duplicated)

- [ ] P20-05 Backend deployed at a public `https://` URL with a
      production Atlas cluster (Phase 15 owner actions, Phase 17).
- [ ] P20-06 Store accounts, signing and artwork (`release-checklist.md`).
- [ ] P20-07 GitHub and SonarQube real-server checks (P8-26/27,
      P10-14/15) — these are the tools Pro sells.

## C. Backend (backend track — per-item approval)

- [ ] P20-10 `billing/plans.js` + `billing/entitlements.js` with
      `BILLING_ENABLED` (default off → everyone Pro); unit tests for every
      status/date case.
- [ ] P20-11 `Subscription` and `BillingEvent` models with indexes
      (unique `userId`, unique `eventId`, TTL on events).
- [ ] P20-12 Plan check in `makeCredentialController` (`{ tool }` arg;
      `tool` added to `CREDENTIAL_TARGETS`); `403 PLAN_LIMIT` body;
      tests per tool, multi-tool rule, edit/delete never limited.
- [ ] P20-13 `locked` flag on credential lists; `setDefault` refuses a
      locked credential; `POST /api/subscription/primary/:id` with a 24 h
      cooldown; tests.
- [ ] P20-14 `GET /api/subscription`, `POST /api/subscription/refresh`
      (rate-limited); tests.
- [ ] P20-15 `billing/revenuecatClient.js` (built-in `fetch`, injectable
      fake) + `syncSubscription.js`.
- [ ] P20-16 `POST /api/billing/revenuecat`: constant-time auth check,
      idempotency, re-read subscriber, never log the body; tests for bad
      auth, duplicates, out-of-order, upstream failure → 500.
- [ ] P20-17 `config/env.js`: new variables, refuse to start half-configured
      when billing is enabled; `.env.example` names (no values).
- [ ] P20-18 Account deletion removes the subscription + RevenueCat
      customer (best effort, logged).
- [ ] P20-19 `scripts/grant-plan.js` (local-only guard) for admin/promo
      grants; `docs/api-reference.md` and `docs/database-migrations.md`
      updated.

## D. Mobile app

- [ ] P20-20 Add `purchases_flutter`; SDK keys in `config/*.json` via
      `app_config.dart`; `BillingClient` interface + RevenueCat impl
      (only file importing the SDK).
- [ ] P20-21 Domain: `Entitlements`, `SubscriptionStatus`,
      `BillingOffer`, `SubscriptionRepository`; data: DTO (freezed) +
      repository impl; `PlanLimitFailure` and `PurchaseCancelled` as new
      `AppFailure` cases (existing copy untouched).
- [ ] P20-22 `EntitlementsNotifier` (keepAlive, cached in
      `user_scoped_prefs`, refreshed on sign-in / resume / purchase);
      RevenueCat `logIn`/`logOut` driven by auth state.
- [ ] P20-23 Paywall screen + notifier (store prices, trial, auto-renew
      text, Terms/Privacy, Restore, reason-aware headline); route
      `/paywall`.
- [ ] P20-24 Profile → Subscription section (US-SUB-01, manage link,
      restore); route `/profile/subscription`.
- [ ] P20-25 Gates (technical design §4.3): add-server forms, tool
      switch, locked credential rows, background watch, widget, pinned
      jobs, insights. Each gate gets a notifier test.
- [ ] P20-26 Delete-account dialog warns about an active store
      subscription (US-SUB-07).
- [ ] P20-27 `ios/Runner/PrivacyInfo.xcprivacy`, App Privacy answers and
      Play Data safety updated for purchases.

## E. Website

- [ ] P20-30 Analytics events wired in the app and on the site (after
      P20-01): paywall view, trial start, purchase, limit hit (with which
      limit), restore, pricing-page view.
- [ ] P20-31 `server/subscription-api.ts` + `PlanLimitFailure` copy in
      `domain/app-failure.ts`; add-server form shows the plan limit.
- [ ] P20-32 Account page: plan, dates, manage-in-store instructions.
- [ ] P20-33 `/pricing` from `src/content/pricing.ts` (tested), header,
      footer, sitemap; comparison wording per competitive analysis §7.2.
- [ ] P20-34 Terms and Privacy updated for subscriptions and RevenueCat.

## F. Store and RevenueCat setup (owner)

- [ ] P20-40 App Store Connect: Paid Apps agreement, tax, banking (check
      Sri Lanka payout details), subscription group + 2 products, 7-day
      trial on yearly, **Small Business Program enrolment**.
- [ ] P20-41 Play Console: payments profile, subscription with monthly
      and yearly base plans, trial offer on yearly.
- [ ] P20-42 RevenueCat: project, both apps, entitlement `pro`, offering
      `default`, webhook URL + secret, sandbox testers.

## G. Verification

- [ ] P20-50 Whole suite clean: `flutter analyze`, `flutter test`,
      `npm test` (backend and web), Playwright.
- [ ] P20-51 iPhone sandbox pass via `scripts/run-on-iphone.sh`
      (CLAUDE.md §10): buy, trial, accelerated renewal, cancel, restore on
      a second install, downgrade locking.
- [ ] P20-52 Android sandbox pass with a Play license tester (blocked on
      a physical Android device, like P11-03).
- [ ] P20-53 Security review of the webhook and plan checks (third audit
      scope, small): auth, idempotency, `userId` scoping, logging.

## H. Launch

- [ ] P20-60 Staging with `BILLING_ENABLED=true`; TestFlight + Play
      internal testers.
- [ ] P20-61 Grant Pro to owner and early testers (`grant-plan.js`).
- [ ] P20-62 Production: flip `BILLING_ENABLED=true`, flip the website's
      pricing status to live, announce in the changelog.
- [ ] P20-63 After ~200 paywall views: review conversion and price
      (business model §4, §7).

## Later (not this phase)

- Phase 21 — web checkout through a merchant of record (US-SUB-10).
- Team plan (US-SUB-11), its own phase and audit.
