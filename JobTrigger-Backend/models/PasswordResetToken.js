const mongoose = require('mongoose');

/**
 * US-AUTH-08 / P20-73: one pending password reset. Only the SHA-256 of the
 * token is stored; the token itself exists only in the email. MongoDB's
 * TTL monitor deletes a document once `expiresAt` passes (it runs about
 * once a minute, so the controller also checks the date itself).
 */
const passwordResetTokenSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  tokenHash: { type: String, required: true },
  expiresAt: { type: Date, required: true },
  usedAt: { type: Date, default: null },
}, { timestamps: true });

passwordResetTokenSchema.index({ tokenHash: 1 }, { unique: true });
passwordResetTokenSchema.index({ userId: 1 });
passwordResetTokenSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

module.exports = mongoose.model('PasswordResetToken', passwordResetTokenSchema);
