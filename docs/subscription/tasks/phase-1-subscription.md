# Phase 1 – Subscription Core

## Tasks

- [ ] **Create entitlementsNotifierProvider** (`AsyncNotifier<SubscriptionSnapshot>`) that fetches `GET /api/subscription` on first use and caches the result.
- [ ] **Implement entitlementsProvider** derived `Entitlements` type that gates UI reads; default to `unrestricted` until data arrives.
- [ ] **Add billingSessionProvider** side‑effect that logs in/out the RevenueCat SDK (or no‑op in demo mode).
- [ ] **Add billingClientProvider** that returns `RevenueCatBillingClient` when a key exists for the platform, otherwise `NoBillingClient`.
- [ ] **Create subscriptionRepositoryProvider** that combines backend calls (`/api/subscription`, `/api/subscription/refresh`) with the billing client; cache the last answer in `shared_preferences` (`subscription_cache`), cleared on sign‑out.
- [ ] **Derive billingAvailableProvider** (`bool`) – true only when an SDK key exists for the platform, `billingEnabled` from the backend, and not in demo mode. Use this to gate the Profile "Subscription" row and the `/paywall` / `/profile/subscription` routes.
- [ ] **Write paywallNotifierProvider** (`AsyncNotifier<PaywallState>`) that presents the store’s offers; `purchase()` and `restore()` return a `PaywallOutcome`; on completion call `POST /api/subscription/refresh` and hand the answer to `EntitlementsNotifier.apply`.
- [ ] **Add unit tests** for the new providers/repository using `riverpod_test` and mock backend responses.
- [ ] **Run `flutter analyze`** – ensure no analysis warnings.

### Acceptance Criteria
- The app starts and displays the correct entitlement (Pro or Free) based on the stored snapshot.
- Tapping "Subscribe" opens the paywall; after a successful purchase the entitlement updates and the UI reflects Pro features.
- The "Restore purchases" button works and triggers the refresh endpoint.
- `billingAvailableProvider` correctly hides/shows the subscription UI according to platform and backend config.

*End of Phase 1 – Subscription Core.*