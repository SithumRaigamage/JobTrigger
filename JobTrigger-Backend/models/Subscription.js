const mongoose = require('mongoose');

/**
 * P20-11: one per user; no document means Free. Written only by
 * billing/syncSubscription.js (from RevenueCat) and scripts/grant-plan.js.
 * Clients never write it.
 */
const subscriptionSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  plan: { type: String, enum: ['free', 'pro'], default: 'free' },
  status: {
    type: String,
    enum: ['none', 'trialing', 'active', 'grace', 'billing_issue', 'cancelled', 'expired'],
    default: 'none',
  },
  source: { type: String, enum: ['app_store', 'play_store', 'web', 'promo', 'admin', null], default: null },
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

module.exports = mongoose.model('Subscription', subscriptionSchema);
