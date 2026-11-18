# Phase 4 – Cross-Platform Payment Integration

## Tasks

- [ ] **RevenueCat iOS configuration** – add App Store SKUs for Monthly ($19.99) and Yearly ($239.00) plans in the RevenueCat dashboard; enable sandbox testers.
- [ ] **RevenueCat Android configuration** – add Google Play SKUs for the same prices; configure the `android.purchaseSubscription` intent filter.
- [ ] **Add Reve…** (truncated) – actually continue:
- [ ] **Platform setup**:
  - iOS: create sandbox tester accounts in App Store Connect.
  - Android: add test license testers in Google Play Console.
- [ ] **Backend webhook** – ensure `POST /api/billing/revenuecat` handles `subscription_renew`, `subscription_cancel`, `subscription_payment_failure` events from RevenueCat.
- [ ] **Paddle webhook** – configure `POST /api/billing/paddle/webhook` to receive `subscription.*` events; validate the `Paddle-Signature`.
- [ ] **iOS web checkout restriction** – in the paywall UI, disable/hide the "Visit website to manage subscription" link for iOS users (per App Review guidelines).
- [ ] **Android web checkout** – same restriction for Android users.
- [ ] **Unit tests** for the webhook handlers using mock event payloads.
- [ ] **Integration test** – install the app on a test device/simulator, perform a sandbox purchase, verify entitlement appears in the app and backend.
- [ ] **Run `flutter analyze`** and `flutter test` – ensure clean.

### Acceptance Criteria
- Sandbox purchases on both iOS and Android successfully grant Pro entitlement.
- Backend `/api/subscription` reflects the correct `plan` and `source` after purchase.
- Web checkout links are hidden for iOS/Android users in the app.
- Webhook events update the entitlement state correctly.
- Tests pass and `flutter analyze` is clean.

*End of Phase 4 – Cross-Platform Payment Integration.*