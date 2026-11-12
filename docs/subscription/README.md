# Subscriptions — plan for review

**Date:** 2026-11-12 · **Status:** proposal, waiting for the owner's
review (P20-00). Nothing here is built yet.

Read in this order:

1. **[Workspace analysis](01-workspace-analysis.md)** — what's in the
   repo today, how the pieces talk, and the gaps that matter once people
   pay (no production backend, no password reset, no analytics…).
2. **[Business model](02-business-model.md)** — Free vs Pro, the
   entitlements matrix, prices, trial, where people pay (stores now,
   website later), unit economics, metrics.
3. **[Technical design](03-technical-design.md)** — backend endpoints and
   models, the plan check on credentials, RevenueCat webhook, Flutter
   layers and gates, website changes, store setup, tests, rollout.
4. **[User stories — epic SUB](../user-stories/billing/18-subscriptions.md)**
   — US-SUB-01 … 11 with acceptance criteria.
5. **[Tasks — Phase 20](../../tasks/phase-20-subscriptions.md)** — the
   build checklist, P20-00 … P20-63.

## The plan in brief

- **Free:** one tool, one saved server, every core feature for it.
- **Pro:** every tool, unlimited servers, background notifications,
  widget, unlimited pins, insights. Suggested $3.99/month or $29.99/year
  with a 7-day trial on yearly.
- **Payments:** App Store and Google Play in-app purchase through
  RevenueCat; website checkout later through a merchant of record (Stripe
  isn't open to Sri Lanka-based businesses, as far as I could find).
- **Enforcement:** the backend owns the plan and blocks extra servers
  itself; the app gates the features the backend never sees.
- **Safety:** downgrades lock, never delete; security features are never
  paid; `BILLING_ENABLED=false` keeps everyone on Pro until launch.

## Decisions needed before any code (P20-00 … P20-03)

1. Free/Pro split and limits. 2. Prices and trial. 3. RevenueCat vs
native billing. 4. Analytics/crash tool. 5. Email provider (password
reset). 6. Web portal free within limits, or Pro-only. 7. RevenueCat
restore-transfer behaviour.
