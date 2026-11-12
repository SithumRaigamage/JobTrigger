/**
 * P20-15: RevenueCat → our Subscription. The webhook body is only a
 * signal; the truth is the subscriber record fetched again here, so
 * duplicated or out-of-order events can't leave a wrong plan.
 */
const Subscription = require('../models/Subscription');
const { PRO_ENTITLEMENT } = require('./plans');
const { isPro } = require('./entitlements');
const revenueCat = require('./revenuecatClient');

const date = (value) => (value ? new Date(value) : null);
const after = (value, now) => value !== null && value > now;

const SOURCES = {
  app_store: 'app_store',
  mac_app_store: 'app_store',
  play_store: 'play_store',
  stripe: 'web',
  rc_billing: 'web',
  paddle: 'web',
  promotional: 'promo',
};

/**
 * The Subscription fields for a RevenueCat `subscriber` at [now]. Pure.
 *
 * - No `pro` entitlement ever: Free, status `none`.
 * - Entitlement without an expiry (lifetime or promo): Pro, `active`.
 * - Still in the period: `trialing` for a trial, `billing_issue` when the
 *   store reported a failed charge, `cancelled` when auto-renew is off,
 *   else `active`.
 * - Past the period but inside the store's grace period: `grace`.
 * - Otherwise `expired`, which is Free.
 */
function fromSubscriber(subscriber, now = new Date()) {
  const entitlement = subscriber?.entitlements?.[PRO_ENTITLEMENT];
  if (!entitlement) {
    return { plan: 'free', status: 'none', source: null, productId: null, periodEnd: null, willRenew: false };
  }
  const productId = entitlement.product_identifier ?? null;
  const sub = (productId && subscriber.subscriptions?.[productId]) || {};
  const expires = date(entitlement.expires_date);
  const grace = date(entitlement.grace_period_expires_date ?? sub.grace_period_expires_date);
  const refunded = date(sub.refunded_at);
  const source = SOURCES[sub.store] ?? null;

  if (refunded && refunded <= now) {
    return { plan: 'free', status: 'expired', source, productId, periodEnd: refunded, willRenew: false };
  }
  if (expires === null) {
    return { plan: 'pro', status: 'active', source, productId, periodEnd: null, willRenew: false };
  }
  const unsubscribed = Boolean(sub.unsubscribe_detected_at);
  if (after(expires, now)) {
    let status = 'active';
    if (sub.billing_issues_detected_at) status = 'billing_issue';
    else if (unsubscribed) status = 'cancelled';
    else if (sub.period_type === 'trial') status = 'trialing';
    return {
      plan: 'pro',
      status,
      source,
      productId,
      periodEnd: grace && grace > expires ? grace : expires,
      willRenew: !unsubscribed,
    };
  }
  if (after(grace, now)) {
    return { plan: 'pro', status: 'grace', source, productId, periodEnd: grace, willRenew: !unsubscribed };
  }
  return { plan: 'free', status: 'expired', source, productId, periodEnd: expires, willRenew: false };
}

/**
 * Re-reads [userId] from RevenueCat and stores the result. An active
 * admin or promo grant (scripts/grant-plan.js) is kept while RevenueCat
 * has nothing better. The Free-plan primary choice is never touched.
 */
async function syncSubscription(userId, { now = new Date() } = {}) {
  const { subscriber } = await revenueCat.getSubscriber(String(userId));
  const fields = fromSubscriber(subscriber, now);
  const current = await Subscription.findOne({ userId }).lean();
  const keepGrant = current?.source === 'admin' && isPro(current, now) && fields.plan !== 'pro';
  if (keepGrant) {
    await Subscription.updateOne({ userId }, { $set: { lastSyncedAt: now } });
    return current;
  }
  return Subscription.findOneAndUpdate(
    { userId },
    { $set: { ...fields, lastSyncedAt: now } },
    { upsert: true, returnDocument: 'after', setDefaultsOnInsert: true },
  ).lean();
}

module.exports = { fromSubscriber, syncSubscription };
