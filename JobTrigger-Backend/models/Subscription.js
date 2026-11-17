const mongoose = require('mongoose');

/**
 * One source of Pro: the app stores (RevenueCat), the website (Paddle) or
 * a manual grant. Kept apart so one can never overwrite another — a user
 * paying on the web isn't downgraded by an empty store record.
 */
const sourceSchema = new mongoose.Schema({
  plan: { type: String, enum: ['free', 'pro'], default: 'free' },
  status: {
    type: String,
    enum: ['none', 'trialing', 'active', 'grace', 'billing_issue', 'cancelled', 'expired'],
    default: 'none',
  },
  source: { type: String, enum: ['app_store', 'play_store', 'web', 'promo', 'admin', 'student', null], default: null },
  productId: { type: String, default: null },
  periodEnd: { type: Date, default: null },
  /** Student grant only: when the year began (periodEnd is when it ends). */
  startsAt: { type: Date, default: null },
  willRenew: { type: Boolean, default: false },
  /** Paddle only: ids for the customer portal and ordering of events. */
  paddleSubscriptionId: { type: String, default: null },
  paddleCustomerId: { type: String, default: null },
  eventAt: { type: Date, default: null },
}, { _id: false });

/**
 * P20-11: one per user; no document means Free. Written only by the
 * billing code (RevenueCat sync, Paddle webhook) and scripts/grant-plan.js.
 * Clients never write it.
 *
 * `store`, `web`, `grant` and `student` are the sources; the top-level plan fields
 * are derived from them by billing/combine.js (the best one wins) and are
 * what entitlements read.
 */
const subscriptionSchema = new mongoose.Schema({
  store: { type: sourceSchema, default: null },
  web: { type: sourceSchema, default: null },
  grant: { type: sourceSchema, default: null },
  /** Phase 21: the free year for verified students. */
  student: { type: sourceSchema, default: null },
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  plan: { type: String, enum: ['free', 'pro'], default: 'free' },
  status: {
    type: String,
    enum: ['none', 'trialing', 'active', 'grace', 'billing_issue', 'cancelled', 'expired'],
    default: 'none',
  },
  source: { type: String, enum: ['app_store', 'play_store', 'web', 'promo', 'admin', 'student', null], default: null },
  productId: { type: String, default: null },
  /** End of the paid period or trial (or of the grace period). Null = no end. */
  periodEnd: { type: Date, default: null },
  willRenew: { type: Boolean, default: false },
  /** The one server kept unlocked on Free (US-SUB-05); null = the oldest. */
  primaryCredentialId: { type: mongoose.Schema.Types.ObjectId, default: null },
  primaryChangedAt: { type: Date, default: null },
  lastSyncedAt: { type: Date, default: null },
}, { timestamps: true });

subscriptionSchema.index({ userId: 1 }, { unique: true });
subscriptionSchema.index({ 'web.paddleSubscriptionId': 1 }, { sparse: true });

module.exports = mongoose.model('Subscription', subscriptionSchema);
