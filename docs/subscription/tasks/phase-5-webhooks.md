# Phase 5 – Webhooks, Admin & QA

## Tasks

- [ ] **Implement `POST /api/billing/revenuecat` handler** –
  - Verify `REVENUECAT_WEBHOOK_AUTH` secret.
  - Process each `event.id` once (store processed IDs, return 200 `duplicate: true` on repeat).
  - On `subscription_renew`, `subscription_cancel`, `subscription_payment_failure`: re-read the user's entitlement from RevenueCat and update `entitlementsNotifierProvider`.
  - Log none of the payload; return `{ ok: true }`.
- [ ] **Implement `POST /api/billing/paddle/webhook` handler** –
  - Validate `Paddle-Signature` (HMAC-SHA256 of `ts:rawBody`, 5 min tolerance).
  - Process only `subscription.*` events; ignore other event types.
  - On `subscription_activate`, `subscription_cancel`, `subscription_expire`: update the user's subscription source to `web` and refresh entitlements.
  - Return `{ ok: true }`; bad signature → 401.
- [ ] **Admin page** – create a simple screen (`admin_subscription_page.dart`) for super admins to:
  - Grant a test Pro grant to a user (POST `/api/credentials/switch` logic or a custom endpoint).
  - Revoke Pro (set plan to Free).
  - Inspect test subscription details (view entitlements from RevenueCat).
- [ ] **Add `superAdmin` role check** in the router – only users with `role: superAdmin` can access the admin page.
- [ ] **QA gate** – run the full subscription test suite:
  - Sandbox purchase on iOS.
  - Sandbox purchase on Android.
  - Restore purchases.
  - Webhook simulation (renew, cancel, payment failure).
  - Verify entitlement state after each event.
- [ ] **Run `flutter analyze`** and `flutter test` – ensure clean; mark any unverified tests as `@riverpod TestSkip`.

### Acceptance Criteria
- RevenueCat webhook correctly updates the user's subscription state.
- Paddle webhook correctly updates the user's subscription state (source: web).
- Admin page allows super admins to grant/revoke Pro for testing.
- Full QA test suite passes across all platforms.
- `flutter analyze` is clean.

*End of Phase 5 – Webhooks, Admin & QA.*