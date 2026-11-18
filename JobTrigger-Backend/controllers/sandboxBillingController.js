/**
 * Development-only sandbox billing. Mounted behind middleware that answers
 * 404 unless SANDBOX_BILLING=true and NODE_ENV is not production, so a
 * release deployment has no such routes.
 *
 * It writes the `store` source exactly as a RevenueCat sync would, except
 * the platform and the period come from the request. No provider is called
 * and no money moves.
 */
const Subscription = require('../models/Subscription');
const { entitlementsFor } = require('../billing/entitlements');
const { derive, writeSource } = require('../billing/combine');
const {
  periodFor,
  purchasedSource,
  cancelledSource,
  resubscribedSource,
  expiredSource,
} = require('../billing/sandbox');
const { logger } = require('../lib/logger');

const body = ({ subscription, ...rest }) => rest;

/** The same `GET /api/subscription` body, after [fields] changed. */
async function answer(userId) {
  return body(await entitlementsFor(userId));
}

const storeOf = async (userId) =>
  (await Subscription.findOne({ userId }).lean())?.store ?? null;

exports.purchase = async (req, res, next) => {
  try {
    res.set('Cache-Control', 'no-store');
    const period = periodFor(req.body?.period);
    if (!period) return res.status(400).json({ message: 'period must be monthly or yearly' });

    const current = await Subscription.findOne({ userId: req.user.id }).lean();
    const plan = derive(current);
    if (plan.plan === 'pro' && plan.willRenew) {
      return res.status(409).json({
        code: 'ALREADY_SUBSCRIBED',
        message: 'This account already has a renewing subscription.',
      });
    }

    const source = purchasedSource({
      period,
      platform: req.body?.platform === 'app_store' ? 'app_store' : 'play_store',
    });
    await writeSource(req.user.id, 'store', source);
    logger.info('billing.sandbox_purchase', {
      requestId: req.requestId,
      userId: req.user.id,
      period,
      platform: source.source,
    });
    res.json(await answer(req.user.id));
  } catch (err) {
    next(err);
  }
};

exports.cancel = async (req, res, next) => {
  try {
    res.set('Cache-Control', 'no-store');
    const store = await storeOf(req.user.id);
    if (!store) return res.status(409).json({ message: 'There is no sandbox subscription to cancel.' });

    await writeSource(req.user.id, 'store', cancelledSource(store));
    logger.info('billing.sandbox_cancel', { requestId: req.requestId, userId: req.user.id });
    res.json(await answer(req.user.id));
  } catch (err) {
    next(err);
  }
};

exports.resubscribe = async (req, res, next) => {
  try {
    res.set('Cache-Control', 'no-store');
    const store = await storeOf(req.user.id);
    if (!store) return res.status(409).json({ message: 'There is no sandbox subscription to resume.' });

    await writeSource(req.user.id, 'store', resubscribedSource(store));
    logger.info('billing.sandbox_resubscribe', { requestId: req.requestId, userId: req.user.id });
    res.json(await answer(req.user.id));
  } catch (err) {
    next(err);
  }
};

/** Testing only: move the end into the past, so Free's gates apply now. */
exports.expire = async (req, res, next) => {
  try {
    res.set('Cache-Control', 'no-store');
    const store = await storeOf(req.user.id);
    if (!store) return res.status(409).json({ message: 'There is no sandbox subscription to expire.' });

    await writeSource(req.user.id, 'store', expiredSource(store));
    logger.info('billing.sandbox_expire', { requestId: req.requestId, userId: req.user.id });
    res.json(await answer(req.user.id));
  } catch (err) {
    next(err);
  }
};
