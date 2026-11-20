/**
 * Website checkout with Paddle (merchant of record).
 *
 * - POST /api/billing/paddle/checkout (signed in): a Paddle transaction
 *   for Pro monthly or yearly, carrying this user's id. The website opens
 *   it with Paddle.js. Refused when the user already has Pro from any
 *   source, so nobody pays twice (app store + web).
 * - POST /api/billing/paddle/portal (signed in): a one-time link to
 *   Paddle's customer portal (card, invoices, cancel).
 * - POST /api/billing/paddle/webhook: Paddle → us. Verified against the
 *   raw body, applied once per event id, older events never overwrite
 *   newer ones, and only the `web` source is written (billing/combine.js).
 *
 * Never logs a webhook body: it carries names, emails and addresses.
 */
const mongoose = require('mongoose');
const BillingEvent = require('../models/BillingEvent');
const Subscription = require('../models/Subscription');
const User = require('../models/User');
const Team = require('../models/Team');
const paddle = require('../billing/paddleClient');
const { verifySignature, fromPaddleSubscription } = require('../billing/paddle');
const { writeSource } = require('../billing/combine');
const { entitlementsFor } = require('../billing/entitlements');
const { billingEnabled, paddleConfig, paddleTeamPrices } = require('../config/env');
const { track } = require('../lib/analytics');
const { logger } = require('../lib/logger');

const unavailable = (res) =>
  res.status(503).json({ message: 'Paying on the website isn\'t available right now.' });

exports.checkout = async (req, res, next) => {
  try {
    const config = paddleConfig();
    if (!billingEnabled() || !config) return unavailable(res);
    const { interval } = req.body ?? {};
    if (interval !== 'monthly' && interval !== 'yearly') {
      return res.status(400).json({ message: 'Choose monthly or yearly' });
    }
    const ent = await entitlementsFor(req.user.id);
    if (ent.plan === 'pro') {
      return res.status(409).json({
        message: ent.source === 'web'
          ? 'You already have Pro. Manage it from your account.'
          : 'You already have Pro through the App Store or Google Play.',
        code: 'ALREADY_SUBSCRIBED',
      });
    }
    const { transactionId } = await paddle.createTransaction({
      priceId: config.prices[interval],
      userId: req.user.id,
    });
    res.set('Cache-Control', 'no-store');
    res.json({ transactionId, environment: config.environment });
  } catch (err) {
    next(err);
  }
};

exports.portal = async (req, res, next) => {
  try {
    if (!paddleConfig()) return unavailable(res);
    const sub = await Subscription.findOne({ userId: req.user.id }).lean();
    if (!sub?.web?.paddleCustomerId) {
      return res.status(404).json({ message: 'You have no subscription bought on the website.' });
    }
    const { url } = await paddle.createPortalSession({
      customerId: sub.web.paddleCustomerId,
      subscriptionId: sub.web.paddleSubscriptionId,
    });
    if (!url) throw new Error('Paddle returned no portal URL');
    res.set('Cache-Control', 'no-store');
    res.json({ url });
  } catch (err) {
    next(err);
  }
};

/**
 * US-SUB-11 AC4: the team a Paddle subscription belongs to, or null. Team
 * checkouts carry `custom_data.teamId`; later events are matched by the
 * subscription id the first one recorded.
 */
async function teamOf(data) {
  const fromCheckout = data?.custom_data?.teamId;
  if (typeof fromCheckout === 'string' && mongoose.Types.ObjectId.isValid(fromCheckout)) {
    const team = await Team.findById(fromCheckout);
    if (team) return team;
  }
  if (typeof data?.id !== 'string') return null;
  return Team.findOne({ 'billing.paddleSubscriptionId': data.id });
}

/** AC4: applies a subscription event to [team]; never a personal source. */
async function applyToTeam(team, data, eventAt) {
  if (team.billing?.eventAt && new Date(team.billing.eventAt) > eventAt
      && team.billing.paddleSubscriptionId === data?.id) {
    return 'stale';
  }
  const mapped = fromPaddleSubscription(data);
  const prices = paddleTeamPrices();
  const priceId = data?.items?.[0]?.price?.id;
  const quantity = Number(data?.items?.[0]?.quantity);
  team.billing = {
    plan: mapped.plan,
    status: mapped.status,
    period: prices && priceId === prices.yearly ? 'yearly' : prices && priceId === prices.monthly ? 'monthly' : team.billing?.period ?? null,
    periodEnd: mapped.periodEnd,
    willRenew: mapped.willRenew,
    paddleSubscriptionId: mapped.paddleSubscriptionId,
    paddleCustomerId: mapped.paddleCustomerId,
    eventAt,
  };
  if (Number.isInteger(quantity) && quantity >= 2 && quantity <= 100) team.seats = quantity;
  await team.save();
  return 'applied';
}

/** The user a Paddle subscription belongs to, or null. */
async function ownerOf(data) {
  const fromCheckout = data?.custom_data?.userId;
  if (typeof fromCheckout === 'string' && mongoose.Types.ObjectId.isValid(fromCheckout)
      && (await User.exists({ _id: fromCheckout }))) {
    return fromCheckout;
  }
  if (typeof data?.id !== 'string') return null;
  const known = await Subscription.findOne({ 'web.paddleSubscriptionId': data.id }, { userId: 1 }).lean();
  return known ? String(known.userId) : null;
}

exports.webhook = async (req, res) => {
  const log = logger.child({ requestId: req.requestId });
  const config = paddleConfig();
  if (!config || !verifySignature(req.body, req.get('paddle-signature'), config.webhookSecret)) {
    log.warn('billing.paddle_unauthorized');
    return res.status(401).json({ message: 'Unauthorized' });
  }

  let event;
  try {
    event = JSON.parse(req.body.toString('utf8'));
  } catch {
    return res.status(400).json({ message: 'Malformed JSON body' });
  }
  const { event_id: eventId, event_type: type, occurred_at: occurredAt, data } = event ?? {};
  if (typeof eventId !== 'string' || typeof type !== 'string') {
    return res.status(400).json({ message: 'Missing event' });
  }
  // Only subscription events change a plan; the rest are acknowledged.
  if (!type.startsWith('subscription.')) return res.json({ ok: true, ignored: true });

  const key = `paddle:${eventId}`;
  try {
    await BillingEvent.create({ eventId: key, type });
  } catch (err) {
    if (err.code === 11000) return res.json({ ok: true, duplicate: true });
    log.error('billing.paddle_failed', { eventId, type, error: err.message });
    return res.status(500).json({ message: 'Server error' });
  }

  try {
    const eventAtForTeam = occurredAt ? new Date(occurredAt) : new Date();
    const team = await teamOf(data);
    if (team) {
      const outcome = await applyToTeam(team, data, eventAtForTeam);
      log.info(`billing.paddle_team_${outcome}`, { eventId, type });
      return res.json({ ok: true, team: true, ...(outcome === 'stale' ? { stale: true } : {}) });
    }
    const userId = await ownerOf(data);
    if (!userId) {
      log.warn('billing.paddle_no_owner', { eventId, type });
      return res.json({ ok: true, ignored: true });
    }
    const eventAt = occurredAt ? new Date(occurredAt) : new Date();
    const current = await Subscription.findOne({ userId }, { web: 1 }).lean();
    const newer = current?.web?.eventAt && new Date(current.web.eventAt) > eventAt
      && current.web.paddleSubscriptionId === data?.id;
    if (newer) {
      log.info('billing.paddle_stale', { eventId, type });
      return res.json({ ok: true, stale: true });
    }
    await writeSource(userId, 'web', { ...fromPaddleSubscription(data), eventAt });
    if (type === 'subscription.created' && data?.status === 'trialing') track('trial_started', { store: 'web' });
    else if (type === 'subscription.canceled') track('subscription_expired', { store: 'web' });
    log.info('billing.paddle_applied', { eventId, type });
    res.json({ ok: true });
  } catch (err) {
    await BillingEvent.deleteOne({ eventId: key }).catch(() => {});
    log.error('billing.paddle_failed', { eventId, type, error: err.message });
    res.status(500).json({ message: 'Server error' });
  }
};
