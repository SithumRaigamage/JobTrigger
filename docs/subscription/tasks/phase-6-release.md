# Phase 6 – Regression, QA Gates & Release

## Tasks

- [ ] **Full regression test pass** –
  - Run `flutter analyze` – must be clean.
  - Run `flutter test` – all subscription-related unit/widget tests pass.
  - Test on both iOS simulator and Android emulator (or physical devices if available).
- [ ] **Test against two Jenkins instances** –
  - One with folders/nested jobs (tree depth > 1).
  - One with flat jobs only.
  - Verify URL rewriting works correctly on both.
- [ ] **Cold-start, backgrounding, and token-expiry flows** –
  - Kill the app in background, restart, verify session persists (or not based on "Remember me").
  - Simulate 401 mid-session; verify refresh flow and entitlement state.
- [ ] **Checklist before store submission** –
  - [ ] `flutter analyze` clean.
  - [ ] All parity checklist items from `docs/migration-strategy.md` are marked done.
  - [ ] Subscription UI/flows tested on both platforms.
  - [ ] Rollback plan: keep last SwiftUI build archived on App Store Connect.
- [ ] **Submit to stores** –
  - Internal TestFlight (iOS) and Play Internal Testing (Android).
  - Include release notes describing the new pricing and subscription flow.
- [ ] **Post‑release monitoring** –
  - Track crash‑free rate.
  - Monitor RevenueCat analytics for subscription conversions.
  - Be ready to roll back if a parity gap surfaces.

### Acceptance Criteria
- `flutter analyze` is clean and all unit/widget tests pass.
- Successful test on two differently-configured Jenkins servers.
- Cold-start and token‑expiry flows work as expected.
- App submitted to internal testing tracks on both iOS and Android.
- Post‑release monitoring plan in place.

*End of Phase 6 – Regression, QA Gates & Release.*