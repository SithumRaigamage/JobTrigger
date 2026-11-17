# M-15 — Billing / subscriptions launch

> Draft task file split from `tasks/MANUAL.md`. Back to the [index](README.md). Each M-XX has one file here so it can be worked, ticked and archived independently.


**Source:** Phase 20 — P20-03, P20-05/06 (links), P20-40..42, P20-51..53,
P20-60..63, P20-85; G/H/F sections of `tasks/phase-20-subscriptions.md`.
**Why only you:** store agreements, tax/banking, RevenueCat and Paddle
accounts, sandbox testers and the pricing/conversion decisions are all yours.

1. App Store Connect: Paid Apps agreement, tax, banking (check Sri Lanka
   payout details), subscription group + two products, 7-day trial on yearly,
   Small Business Program enrolment (P20-40).
2. Play Console: payments profile, monthly and yearly base plans, trial on
   yearly (P20-41).
3. RevenueCat: project, both apps, entitlement `pro`, offering `default`,
   webhook URL + secret, sandbox testers (P20-42).
4. Paddle: sandbox account, Pro product with monthly/yearly prices, approved
   payment link domain, webhook to `/api/billing/paddle/webhook`, client-side
   token (P20-85).
5. Transfer behaviour with two real sandbox store accounts (P20-03).
6. iPhone sandbox pass via `scripts/run-on-iphone.sh`: buy, trial, accelerated
   renewal, cancel, restore on a second install, downgrade locking (P20-51);
   the Android pass is part of [M-02](M-02-android-on-device-jank.md) (P20-52).
7. Decide whether to commission the third-audit security review of the
   webhook and plan checks (P20-53); staging and TestFlight with
   `BILLING_ENABLED=true` (P20-60), grant Pro to testers (P20-61), production
   flip and announcement (P20-62), conversion review after ~200 paywall views
   (P20-63).

**Evidence:** sandbox purchase/restoration results and the live plan setup.
