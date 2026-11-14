/**
 * P20-13/14: the signed-in user's plan (US-SUB-01), a re-sync after a
 * purchase (US-SUB-02/03), and choosing the one server kept on Free
 * (US-SUB-05).
 */
const mongoose = require('mongoose');
const Subscription = require('../models/Subscription');
const { entitlementsFor } = require('../billing/entitlements');
const { allCredentials, sendPlanLimit } = require('../billing/limits');
const { syncSubscription } = require('../billing/syncSubscription');
const { billingEnabled, revenueCatConfig } = require('../config/env');
const { logger } = require('../lib/logger');

const PRIMARY_COOLDOWN_MS = 24 * 60 * 60 * 1000;

/** The public body: no internal ids, no primary bookkeeping. */
const body = ({ subscription, ...rest }) => ({
  ...rest,
  primaryCredentialId: subscription?.primaryCredentialId
    ? String(subscription.primaryCredentialId)
    : null,
});

exports.get = async (req, res, next) => {
  try {
    res.set('Cache-Control', 'no-store');
    res.json(body(await entitlementsFor(req.user.id)));
  } catch (err) {
    next(err);
  }
};

/**
 * Called by the app right after a purchase or restore, so Pro unlocks
 * without waiting for the webhook. A RevenueCat outage keeps the last
 * stored plan (and is logged) rather than failing the purchase screen.
 */
exports.refresh = async (req, res, next) => {
  try {
    if (billingEnabled() && revenueCatConfig()) {
      try {
        await syncSubscription(req.user.id);
      } catch (err) {
        logger.warn('billing.refresh_failed', { requestId: req.requestId, error: err.message });
      }
    }
    res.set('Cache-Control', 'no-store');
    res.json(body(await entitlementsFor(req.user.id)));
  } catch (err) {
    next(err);
  }
};

/**
 * US-SUB-05: on Free, which saved server stays usable. Once per 24 hours,
 * so switching back and forth can't turn Free into several servers.
 */
exports.setPrimary = async (req, res, next) => {
  try {
    const { credentialId } = req.params;
    if (!mongoose.Types.ObjectId.isValid(credentialId)) {
      return res.status(400).json({ message: 'Invalid credential id' });
    }
    const owned = (await allCredentials(req.user.id)).some((c) => c.id === credentialId);
    if (!owned) return res.status(404).json({ message: 'Credential not found' });

    const now = new Date();
    const current = await Subscription.findOne({ userId: req.user.id }).lean();
    if (current?.primaryCredentialId && String(current.primaryCredentialId) === credentialId) {
      return res.json(body(await entitlementsFor(req.user.id)));
    }
    if (current?.primaryChangedAt && now - new Date(current.primaryChangedAt) < PRIMARY_COOLDOWN_MS) {
      return sendPlanLimit(
        res,
        'primaryCooldown',
        'You can change which server you keep once a day. Upgrade to Pro to use them all.',
      );
    }
    await Subscription.updateOne(
      { userId: req.user.id },
      { $set: { primaryCredentialId: credentialId, primaryChangedAt: now } },
      { upsert: true, setDefaultsOnInsert: true },
    );
    res.json(body(await entitlementsFor(req.user.id)));
  } catch (err) {
    next(err);
  }
};

exports.PRIMARY_COOLDOWN_MS = PRIMARY_COOLDOWN_MS;
