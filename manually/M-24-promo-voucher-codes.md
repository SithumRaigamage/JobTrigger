# M-24 — Promo codes, checkout discounts and expiry reminders (US-PROMO-01..06)

> Added 2026-11-22 with Phase 30. Back to the [index](README.md).

**Source:** PV-50, PV-65, PV-79 (`tasks/phase-30-promo-codes.md`).
**Why only you:** production/staging deployment variables, the Paddle account/dashboard, and physical iPhone hardware testing in your hands.

---

### Step 1: Pre-deploy check & configure `PROMO_CODES` (PV-50)

1. Decide your production and test codes. For example:
   * `LAUNCH30`: 30 days of Pro time.
   * `TEST4D`: 4 days of Pro time (for fast expiry reminder testing).
   * `SAVE20`: website checkout discount (linked to Paddle `discountId`).

2. Verify the JSON with the CLI script before deploying:
   ```bash
   cd JobTrigger-Backend
   PROMO_CODES='[{"code":"LAUNCH30","days":30},{"code":"TEST4D","days":4}]' npm run check-promo-codes
   ```
   *(Must exit 0 with: `PROMO_CODES is usable: 2 codes (2 Pro-time, 0 checkout discounts)`)*

3. Add `PROMO_CODES` to your deployment environment (e.g., Render Dashboard under Environment Variables) and redeploy the backend.

4. Run the app on your physical iPhone:
   ```bash
   ./scripts/run-on-iphone.sh
   ```

5. In the app:
   * Navigate to **Profile → Subscription**.
   * Verify "Redeem a code" is visible when on Free plan.
   * Tap "Redeem a code", enter `LAUNCH30`, and tap **Redeem**.
   * Verify the success toast, the updated screen showing **JobTrigger Pro**, "Ends on <date>", and "Redeemed with a code."

---

### Step 2: Paddle percentage discount checkout test (PV-65)

1. Sign in to your **Paddle Dashboard** (sandbox or production):
   * Navigate to **Catalog → Discounts**.
   * Click **New Discount** (e.g. 20% off, name `SAVE20`).
   * Copy the generated discount ID (starts with `dsc_...`).

2. Update `PROMO_CODES` in your backend environment (Render / `.env`):
   ```json
   [{"code":"LAUNCH30","days":30},{"code":"TEST4D","days":4},{"code":"SAVE20","discountId":"dsc_YOUR_DISCOUNT_ID"}]
   ```
   Verify with `npm run check-promo-codes` and redeploy.

3. On the website (`JobTrigger-Web`):
   * Sign in to an account with a Free plan.
   * Go to `/account/billing`.
   * Under the Upgrade buttons, find **Discount code (money off this purchase)**.
   * Enter `SAVE20` and click Upgrade (Monthly or Yearly).
   * Verify the Paddle checkout overlay opens with the discounted total.

---

### Step 3: Validate the 3-day expiry reminder notification & banner (PV-79)

1. On your iPhone, redeem the short code `TEST4D` (4 days of Pro).
2. Background the app.
3. Advance the iPhone date by 2 days (Settings → General → Date & Time → toggle off "Set Automatically" and move forward 2 days) so the period has less than 3 days remaining.
4. Relaunch or foreground the app:
   * **With notifications allowed**: Verify a local notification arrives on the `subscription` channel stating your Pro from a code ends soon with the end date.
   * **With notifications disabled**: Open the app and verify the persistent `PromoExpiryBanner` appears at the top of the **Home** screen and **Profile → Subscription** screen, tapping it navigates to Subscription.
