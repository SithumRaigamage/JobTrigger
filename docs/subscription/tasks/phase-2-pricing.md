# Phase 2 – Pricing Integration

## Tasks

- [ ] **Add pricing constants** to `core/config/app_config.dart`:
  - `monthlyPriceCents = 1999` (representing $19.99)
  - `yearlyPriceCents = 23900` (representing $239.00)
  - `yearlyTrialDays = 7`
- [ ] **Modify `/api/subscription` response handling** in `entitlementsNotifierProvider` to read `plan`, `billingEnabled`, `limits`, `features` from the backend.
- [ ] **Implement `Entitlements` derived type** that maps backend `plan` to UI strings ("Free", "Monthly Pro", "Yearly Pro") and checks `limits`/`features` to unlock gates.
- [ ] **Update `billingAvailableProvider`** logic:
  - true when an SDK key exists for the platform **and** `billingEnabled` from backend is true **and** not demo mode.
- [ ] **Wire the paywall offers** to the pricing constants:
  - Monthly offer: `amountCents: appConfig.monthlyPriceCents`, `name: "Monthly Pro"`.
  - Yearly offer: `amountCents: appConfig.yearlyPriceCents`, `name: "Yearly Pro"`, `freeTrialDays: appConfig.yearlyTrialDays`.
- [ ] **Add unit tests** for the pricing constant mapping and entitlement derivation.
- [ ] **Run `flutter analyze`** – ensure no new warnings.

### Acceptance Criteria
- The app reads the correct prices from the config and displays them in the paywall.
- Entitlements are correctly derived from the backend subscription response.
- `billingAvailableProvider` correctly gates the subscription UI based on platform and backend config.
- Tests pass and `flutter analyze` is clean.

*End of Phase 2 – Pricing Integration.*