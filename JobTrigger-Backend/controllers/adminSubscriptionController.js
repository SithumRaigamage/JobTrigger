/**
 * Release 1.0.0: the owner's subscription console. Super admin only
 * (middleware/requireSuperAdmin.js), rate limited, `no-store`, and every
 * write is logged with ids only (never an email).
 *
 * It inspects every account's derived plan and lets the owner grant Pro to
 * a tester (with or without an end date) or take that grant away again.
 * It never touches a store or web subscription: those are the customer's
 * and can only be changed where they were bought.
 */
const mongoose = require('mongoose');
const User = require('../models/User');
const Subscription = require('../models/Subscription');
const PromoRedemption = require('../models/PromoRedemption');
const { clearSource, derive, writeSource } = require('../billing/combine');
const { isPro } = require('../billing/entitlements');
const { promoCodes } = require('../config/env');
const { logger } = require('../lib/logger');

const PAGE = 50;
const MAX_DAYS = 3650;
const DAY_MS = 24 * 60 * 60 * 1000;

const escapeRegex = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const validId = (id) => mongoose.Types.ObjectId.isValid(id);

function sourceView(source) {
  if (!source) return null;
  return {
    plan: source.plan ?? 'free',
    status: source.status ?? 'none',
    source: source.source ?? null,
    productId: source.productId ?? null,
    periodEnd: source.periodEnd ? new Date(source.periodEnd).toISOString() : null,
    willRenew: Boolean(source.willRenew),
  };
}

/** One account as the console shows it. Pure apart from Date. */
function view(user, subscription, now = new Date()) {
  const derived = derive(subscription, now);
  const pro = isPro(derived, now);
  return {
    userId: String(user._id),
    email: user.email,
    plan: pro ? 'pro' : 'free',
    status: derived.status,
    source: derived.source,
    productId: derived.productId,
    periodEnd: derived.periodEnd ? new Date(derived.periodEnd).toISOString() : null,
    willRenew: Boolean(derived.willRenew),
    sources: {
      store: sourceView(subscription?.store),
      web: sourceView(subscription?.web),
      grant: sourceView(subscription?.grant),
      student: sourceView(subscription?.student),
      // US-PROMO-01: a redeemed code (productId holds the code).
      promo: sourceView(subscription?.promo),
    },
    createdAt: user.createdAt ? new Date(user.createdAt).toISOString() : null,
  };
}

/**
 * US-PROMO-05: every configured code, with how many accounts hold it and
 * what is left of its cap. The count is the redemption rows — the same count
 * the redeem rule enforces (billing/promo.js `isUsable`) — so a code deleted
 * with its account frees a slot here exactly as it does there. A checkout
 * discount has no local rows: Paddle counts its own redemptions. Codes are
 * only shown to a super admin, and only the numbers, never who holds one.
 */
function promoCodeViews(counts, now = new Date()) {
  return promoCodes().map((entry) => {
    const redemptions = entry.days ? counts.get(entry.code) ?? 0 : null;
    return {
      code: entry.code,
      kind: entry.days ? 'pro' : 'checkout',
      days: entry.days ?? null,
      redemptions,
      maxRedemptions: entry.maxRedemptions ?? null,
      remaining:
        entry.maxRedemptions === null || redemptions === null
          ? null
          : Math.max(0, entry.maxRedemptions - redemptions),
      expiresAt: entry.expiresAt ? new Date(entry.expiresAt).toISOString() : null,
      expired: Boolean(entry.expiresAt && entry.expiresAt <= now),
    };
  });
}

/** `?q=` an account email; `?plan=all|pro|free` (default all). Newest first. */
exports.list = async (req, res, next) => {
  try {
    res.set('Cache-Control', 'no-store');
    const q = typeof req.query.q === 'string' ? req.query.q.trim().slice(0, 100) : '';
    const requested = typeof req.query.plan === 'string' ? req.query.plan : 'all';
    if (!['all', 'pro', 'free'].includes(requested)) {
      return res.status(400).json({ message: 'Unknown plan filter' });
    }
    const filter = q
      ? { email: mongoose.trusted({ $regex: new RegExp(escapeRegex(q), 'i') }) }
      : {};
    const users = await User.find(filter)
      .sort({ createdAt: -1 })
      .limit(200)
      .select('email createdAt')
      .lean();
    const subscriptions = await Subscription.find({
      userId: mongoose.trusted({ $in: users.map((u) => u._id) }),
    }).lean();
    const byUser = new Map(subscriptions.map((s) => [String(s.userId), s]));
    const now = new Date();
    const items = users
      .map((u) => view(u, byUser.get(String(u._id)), now))
      .filter((item) => requested === 'all' || item.plan === requested)
      .slice(0, PAGE);
    // Counted over every account, not the page: a cap is global.
    const counts = await PromoRedemption.aggregate([
      { $group: { _id: '$code', count: { $sum: 1 } } },
    ]);
    res.json({
      items,
      codes: promoCodeViews(new Map(counts.map((c) => [c._id, c.count])), now),
    });
  } catch (err) {
    next(err);
  }
};

/**
 * `POST /:userId/grant` `{ days }`: Pro with no end (days empty) or for a
 * bounded test window. Replaces any earlier grant, never a paid source.
 */
exports.grant = async (req, res, next) => {
  try {
    res.set('Cache-Control', 'no-store');
    if (!validId(req.params.userId)) return res.status(404).json({ message: 'Not found' });
    const user = await User.findById(req.params.userId).select('email createdAt').lean();
    if (!user) return res.status(404).json({ message: 'Not found' });

    const raw = req.body?.days;
    const days = raw === undefined || raw === null || raw === '' ? null : Number(raw);
    if (days !== null && (!Number.isInteger(days) || days < 1 || days > MAX_DAYS)) {
      return res.status(400).json({
        message: `days must be a whole number from 1 to ${MAX_DAYS}, or empty for no end`,
      });
    }

    await writeSource(user._id, 'grant', {
      plan: 'pro',
      status: 'active',
      source: 'admin',
      productId: null,
      periodEnd: days === null ? null : new Date(Date.now() + days * DAY_MS),
      willRenew: false,
    });
    logger.info('admin.subscription_granted', {
      requestId: req.requestId,
      adminId: req.user.id,
      userId: String(user._id),
      days,
    });
    const subscription = await Subscription.findOne({ userId: user._id }).lean();
    res.json(view(user, subscription));
  } catch (err) {
    next(err);
  }
};

/** `POST /:userId/revoke`: removes the grant source only. */
exports.revoke = async (req, res, next) => {
  try {
    res.set('Cache-Control', 'no-store');
    if (!validId(req.params.userId)) return res.status(404).json({ message: 'Not found' });
    const user = await User.findById(req.params.userId).select('email createdAt').lean();
    if (!user) return res.status(404).json({ message: 'Not found' });

    const subscription = await clearSource(user._id, 'grant');
    logger.info('admin.subscription_revoked', {
      requestId: req.requestId,
      adminId: req.user.id,
      userId: String(user._id),
    });
    res.json(view(user, subscription));
  } catch (err) {
    next(err);
  }
};

exports.view = view;
exports.promoCodeViews = promoCodeViews;
exports.MAX_DAYS = MAX_DAYS;
