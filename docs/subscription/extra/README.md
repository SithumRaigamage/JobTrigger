# Extra Materials – Subscription & Billing

## Links
- **Design Figma file** (link placeholder) – UI mockups for subscription screen, paywall, billing support screen.
- **RevenueCat sandbox credentials** – stored in `config/revenuecat_sandbox.json` (not committed).
- **Paddle developer dashboard** – test mode credentials.
- **Apple App Store Connect** – sandbox tester accounts.
- **Google Play Console** – test account details.

## Checklist for Owner
- Verify that `developer@jobtrigger.app` has permanent Pro without billing. The grant is
  applied automatically after signup and login (`billing/owner.js`).
- Ensure `tester@jobtrigger.app` / `TesterPass123!` starts Free and can upgrade/downgrade
  using **real sandbox** purchases (App Store / Google Play in the app, Paddle sandbox on
  the website). A dev build can also use the local sandbox (`SANDBOX_BILLING=1`).
- **Admin console**: `/admin/subscriptions` on the website (super admin only) lists every
  account's plan and each source, and grants or revokes test Pro by days or with no end.
  `scripts/grant-plan.js` remains the command-line way to grant someone by hand.
- **Billing support screen**: `subscription_screen.dart` shows plan, source, renewal/end date,
  cancellation state, the Manage action where the source has one, and "Restore purchases".
- **Webhooks**: RevenueCat and Paddle webhooks are implemented in `JobTrigger-Backend`
  (`controllers/billingWebhookController.js`, `controllers/paddleController.js`) and tested in
  `test/billing.test.js` / `test/paddle.test.js`.
- Confirm that all other new accounts start Free.
- Confirm `BILLING_ENABLED=true` and the RevenueCat/Paddle secrets are set for production
  (P20-62).
- Review pricing (`docs/subscription/docs/pricing.md`): $9.99/month, $29.99/year, 7-day yearly
  trial.
- Run `flutter analyze` and `flutter test` before each release.

## Known Open Items
- [ ] Owner: App Store Connect and Play Console products at the new prices, RevenueCat
      offering, Paddle sandbox (P20-40..42, P20-85).
- [ ] Device/sandbox passes (P20-51..53) and the production `BILLING_ENABLED` flip (P20-62).

## References
- `docs/subscription/changes.md` – overall model changes.
- `docs/subscription/tasks/` – task list per phase.
- `docs/subscription/references/api-reference-subscription.md` – API spec.
- `docs/subscription/docs/pricing.md` – pricing details.
- `docs/subscription/docs/billing-integration.md` – integration guide.

*End of extra materials.*
