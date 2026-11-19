/**
 * Development-only sandbox for the store flow. It never charges anything and
 * it never talks to Apple, Google or RevenueCat: it writes the same `store`
 * source a real purchase would, so the app and the backend can be exercised
 * end to end (subscribe → cancel → expiry → resubscribe) before the stores
 * and RevenueCat are configured.
 *
 * This is not a release feature. `sandboxBillingEnabled()` is false in
 * production and unless SANDBOX_BILLING=true, and app builds can only turn
 * it on outside release mode (`AppConfig.billingSandbox`).
 */

const DAY_MS = 24 * 60 * 60 * 1000;

const PERIODS = Object.freeze({
  monthly: Object.freeze({ productId: 'jobtrigger_pro_monthly', days: 30, trialDays: 0 }),
  yearly: Object.freeze({ productId: 'jobtrigger_pro_yearly', days: 365, trialDays: 7 }),
});

const periodFor = (value) => (value === 'yearly' ? 'yearly' : value === 'monthly' ? 'monthly' : null);

/** The period a stored product id belongs to. */
function periodOfProduct(productId) {
  const id = String(productId ?? '');
  return id.includes('year') || id.includes('annual') ? 'yearly' : 'monthly';
}

/** A new sandbox store source for [period] bought on [platform]. Pure. */
function purchasedSource({ period, platform, now = new Date() }) {
  const plan = PERIODS[periodFor(period)];
  if (!plan) return null;
  const trial = plan.trialDays > 0;
  return {
    plan: 'pro',
    status: trial ? 'trialing' : 'active',
    source: platform === 'app_store' ? 'app_store' : 'play_store',
    productId: plan.productId,
    periodEnd: new Date(now.getTime() + (trial ? plan.trialDays : plan.days) * DAY_MS),
    willRenew: true,
  };
}

/** Cancel: keep Pro until the paid period ends. Pure. */
function cancelledSource(source) {
  return { ...source, status: 'cancelled', willRenew: false };
}

/**
 * Resubscribe: renew from the end of a still-running period, or start a new
 * period now if it already ended. A resubscribe never re-applies the trial.
 * Pure.
 */
function resubscribedSource(source, { now = new Date() } = {}) {
  if (!source) return null;
  const period = periodOfProduct(source.productId);
  const plan = PERIODS[period];
  const end = source.periodEnd ? new Date(source.periodEnd) : null;
  if (end && end > now) {
    return { ...source, plan: 'pro', status: 'active', willRenew: true };
  }
  return {
    ...source,
    plan: 'pro',
    status: 'active',
    willRenew: true,
    periodEnd: new Date(now.getTime() + plan.days * DAY_MS),
  };
}

/** Move the end into the past so the test can see the downgrade at once. */
function expiredSource(source, { now = new Date() } = {}) {
  return {
    ...source,
    status: 'expired',
    willRenew: false,
    periodEnd: new Date(now.getTime() - 1000),
  };
}

module.exports = {
  PERIODS,
  DAY_MS,
  periodFor,
  periodOfProduct,
  purchasedSource,
  cancelledSource,
  resubscribedSource,
  expiredSource,
};
