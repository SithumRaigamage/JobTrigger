# Phase 3 – Subscription UI

## Tasks

- [ ] **Create `paywall_screen.dart`** – a `ConsumerWidget` that reads `paywallNotifierProvider` and displays:
  - Monthly and Yearly plan cards with price, features list, and "Subscribe" button.
  - "Restore purchases" button.
  - Description of what Pro includes (priority support, offline browsing, etc.).
- [ ] **Implement `paywallNotifierProvider`** methods:
  - `loadOffers()` – fetches offers from the backend or uses local config.
  - `purchase(packageId)` – calls RevenueCat `Purchases.buyPackage()`.
  - `restore()` – calls RevenueCat `Purchases.restorePurchases()`.
- [ ] **Add `billing_available` gate** in the app router – if `billingAvailableProvider` is false, redirect to Home screen.
- [ ] **Create `billing_support_screen.dart`** – shows current plan, renewal date, cancellation state, invoice link (if available), and "Restore purchases" action.
- [ ] **Update `main.dart`** to include the `AuthNotifier.logout` handler that clears the subscription cache (`subscription_cache` shared_preferences key).
- [ ] **Write unit widgets tests** for the paywall screen (mock RevenueCat responses).
- [ ] **Run `flutter analyze`** and `flutter test` – ensure clean.

### Acceptance Criteria
- The paywall screen displays the correct pricing ($19.99 monthly, $239 yearly) and features.
- Tapping "Subscribe" opens the RevenueCat purchase sheet; after purchase, the entitlement updates and the UI reflects Pro features.
- The "Restore purchases" button works.
- The billing support screen shows the user's plan and renewal info.
- Accessing the subscription UI is gated by `billingAvailableProvider`; non-eligible users are redirected.
- Tests pass and `flutter analyze` is clean.

*End of Phase 3 – Subscription UI.*