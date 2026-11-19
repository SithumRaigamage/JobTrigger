/**
 * P20-10: what a user may do right now. The only place that turns a
 * Subscription document into limits and features; everything else (the
 * credential checks, GET /api/subscription) asks here.
 */
const Subscription = require('../models/Subscription');
const { PLANS } = require('./plans');
const { billingEnabled } = require('../config/env');

/** Statuses that keep Pro until `periodEnd` (or forever when it is null). */
const PRO_STATUSES = new Set(['trialing', 'active', 'grace', 'billing_issue', 'cancelled']);

/** Whether [sub] grants Pro at [now]. Pure, for tests. */
function isPro(sub, now = new Date()) {
  if (!sub || sub.plan !== 'pro' || !PRO_STATUSES.has(sub.status)) return false;
  return !sub.periodEnd || new Date(sub.periodEnd) > now;
}

/** The response body of GET /api/subscription for [sub] at [now]. Pure. */
function describe(sub, { enabled, now = new Date() }) {
  const pro = !enabled || isPro(sub, now);
  const plan = PLANS[pro ? 'pro' : 'free'];
  return {
    plan: pro ? 'pro' : 'free',
    billingEnabled: enabled,
    status: sub?.status ?? 'none',
    source: sub?.source ?? null,
    productId: sub?.productId ?? null,
    periodEnd: sub?.periodEnd ? new Date(sub.periodEnd).toISOString() : null,
    willRenew: Boolean(sub?.willRenew),
    // Web checkout: the user has a Paddle customer, so the website can
    // open Paddle's portal (change card, cancel). Store subscriptions are
    // managed in the App Store / Google Play instead.
    manageOnWeb: Boolean(sub?.web?.paddleCustomerId),
    limits: { ...plan.limits },
    features: { ...plan.features },
  };
}

/**
 * US-SUB-07 / changes.md §4: a paid subscription that is still billing (a
 * store or web source that renews and is in a Pro-granting state) blocks
 * account deletion — otherwise deleting the account leaves the subscriber
 * paying for an app they can no longer use. Grants and student years are
 * free, so they never block. Pure, for tests.
 *
 * Returns the blocking source key ('store' | 'web') or null.
 */
function activePaidSource(sub, now = new Date()) {
  if (!sub) return null;
  for (const key of ['store', 'web']) {
    const s = sub[key];
    if (!s || s.plan !== 'pro' || !s.willRenew || !PRO_STATUSES.has(s.status)) continue;
    if (s.periodEnd && new Date(s.periodEnd) <= now) continue;
    return key;
  }
  return null;
}

/** The entitlements of [userId] now. */
async function entitlementsFor(userId, { now = new Date() } = {}) {
  const enabled = billingEnabled();
  const sub = await Subscription.findOne({ userId }).lean();
  return { ...describe(sub, { enabled, now }), subscription: sub };
}

module.exports = { entitlementsFor, describe, isPro, activePaidSource, PRO_STATUSES };
