# Extra Materials – Subscription & Billing

## Links
- **Design Figma file** (link placeholder) – UI mockups for subscription screen, paywall, billing support screen.
- **RevenueCat sandbox credentials** – stored in `config/revenuecat_sandbox.json` (not committed).
- **Paddle developer dashboard** – test mode credentials.
- **Apple App Store Connect** – sandbox tester accounts.
- **Google Play Console** – test account details.

## Checklist for Owner
- Verify that `developer@jobtrigger.app` has permanent Pro without billing.
- Ensure `journey1@example.com` can upgrade/downgrade using sandbox purchases.
- Confirm that all other new accounts start Free.
- Review pricing page (`docs/subscription/docs/pricing.md`) with product team.
- Run `flutter analyze` and all related unit tests before each release.

## Known Open Items
- [ ] Finalize the admin page UI for granting/revoking test subscriptions.
- [ ] Add webhook endpoint tests for `POST /api/billing/revenuecat`.
- [ ] Document the exact flow for canceling a subscription via Apple/Google Play settings.

## References
- `docs/subscription/changes.md` – overall model changes.
- `docs/subscription/tasks/` – task list per phase.
- `docs/subscription/references/api-reference-subscription.md` – API spec.
- `docs/subscription/docs/pricing.md` – pricing details.
- `docs/subscription/docs/billing-integration.md` – integration guide.

*End of extra materials.*