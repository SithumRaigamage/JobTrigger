/**
 * P20-16: RevenueCat → POST /api/billing/revenuecat (US-SUB-09).
 *
 * 1. The Authorization header must equal REVENUECAT_WEBHOOK_AUTH,
 *    compared in constant time. Wrong or missing: 401, nothing stored.
 * 2. Each event id is applied once (BillingEvent, unique): a duplicate
 *    answers 200 and stops.
 * 3. The body is only a signal: every account it names is re-read from
 *    RevenueCat (syncSubscription), so order doesn't matter.
 * 4. A failure answers 500 so RevenueCat retries; the event id is then
 *    released so the retry is applied.
 *
 * Never logs the body: it carries store transaction ids and prices.
 */
const crypto = require('crypto');
const mongoose = require('mongoose');
const BillingEvent = require('../models/BillingEvent');
const User = require('../models/User');
const { syncSubscription } = require('../billing/syncSubscription');
const { revenueCatConfig } = require('../config/env');
const { track } = require('../lib/analytics');
const { logger } = require('../lib/logger');

function authorized(header, expected) {
  if (typeof header !== 'string' || !expected) return false;
  const a = crypto.createHash('sha256').update(header).digest();
  const b = crypto.createHash('sha256').update(expected).digest();
  return crypto.timingSafeEqual(a, b);
}

/** Account ids an event names: the buyer and both sides of a transfer. */
function accountIds(event) {
  const ids = [
    event.app_user_id,
    event.original_app_user_id,
    ...(Array.isArray(event.transferred_from) ? event.transferred_from : []),
    ...(Array.isArray(event.transferred_to) ? event.transferred_to : []),
  ];
  // Anonymous RevenueCat ids ($RCAnonymousID:...) and anything else that
  // isn't one of our users is skipped.
  return [...new Set(ids.filter((id) => typeof id === 'string' && mongoose.Types.ObjectId.isValid(id)))];
}

/** P20-78: anonymous lifecycle counts (catalogue names only). */
function trackEvent(event) {
  const product = typeof event.product_id === 'string' ? event.product_id : undefined;
  if (event.type === 'INITIAL_PURCHASE' && event.period_type === 'TRIAL') track('trial_started', { product });
  else if (event.type === 'RENEWAL') track('subscription_renewed', { product });
  else if (event.type === 'EXPIRATION') track('subscription_expired', { product });
  else if (event.type === 'CANCELLATION' && event.cancel_reason === 'CUSTOMER_SUPPORT') track('refund', { product });
}

exports.revenuecat = async (req, res) => {
  const log = logger.child({ requestId: req.requestId });
  const config = revenueCatConfig();
  if (!config || !authorized(req.get('authorization'), config.webhookAuth)) {
    log.warn('billing.webhook_unauthorized');
    return res.status(401).json({ message: 'Unauthorized' });
  }

  const event = req.body?.event;
  if (!event || typeof event.id !== 'string' || !event.id) {
    return res.status(400).json({ message: 'Missing event' });
  }
  const type = typeof event.type === 'string' ? event.type : null;

  try {
    await BillingEvent.create({ eventId: event.id, type });
  } catch (err) {
    if (err.code === 11000) {
      log.info('billing.webhook_duplicate', { eventId: event.id, type });
      return res.json({ ok: true, duplicate: true });
    }
    log.error('billing.webhook_failed', { eventId: event.id, type, error: err.message });
    return res.status(500).json({ message: 'Server error' });
  }

  try {
    for (const id of accountIds(event)) {
      if (!(await User.exists({ _id: id }))) continue;
      await syncSubscription(id);
    }
    trackEvent(event);
    log.info('billing.webhook_applied', { eventId: event.id, type });
    res.json({ ok: true });
  } catch (err) {
    // Release the id so RevenueCat's retry is applied, not skipped.
    await BillingEvent.deleteOne({ eventId: event.id }).catch(() => {});
    log.error('billing.webhook_failed', { eventId: event.id, type, error: err.message });
    res.status(500).json({ message: 'Server error' });
  }
};

exports.accountIds = accountIds;
