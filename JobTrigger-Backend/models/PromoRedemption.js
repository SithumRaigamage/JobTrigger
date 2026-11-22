const mongoose = require('mongoose');

/**
 * US-PROMO-01: one account's use of one promo code. Kept so a code can be
 * limited to one redemption per account (the unique index) and to a total
 * across all accounts (counted by code), and so the owner can see when a code
 * ran out. Holds no personal data beyond the account id; deleted with the
 * account (controllers/authController.js).
 *
 * `code` is the normalized (upper-cased) code, never the raw input.
 */
const promoRedemptionSchema = new mongoose.Schema({
  code: { type: String, required: true, uppercase: true, trim: true },
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  days: { type: Number, required: true },
  /** When the Pro period this redemption granted ends. */
  periodEnd: { type: Date, required: true },
}, { timestamps: true });

// One redemption per account per code: two requests can't both write.
promoRedemptionSchema.index({ code: 1, userId: 1 }, { unique: true });
// Counting a code's total redemptions.
promoRedemptionSchema.index({ code: 1, createdAt: -1 });

module.exports = mongoose.model('PromoRedemption', promoRedemptionSchema);
