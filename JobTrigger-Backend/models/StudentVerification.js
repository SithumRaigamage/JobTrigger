const mongoose = require('mongoose');

/**
 * Phase 21 (SP-12): one student application. `method` says how it is being
 * proved: a one-time code sent to a university email, or an uploaded
 * student ID / enrolment letter reviewed by hand.
 *
 * - An email application stays `pending` (with a code) until the right
 *   code is confirmed, then is `approved` at once.
 * - A document application is `pending` until the owner decides.
 * - `expired` is set by the daily job once the year is over. Whether the
 *   grant still gives Pro is decided by the date, not by this field
 *   (billing/combine.js), so a missed run never extends anyone's Pro.
 *
 * The document is stored encrypted (security/secretCipher.js); this model
 * never returns it in JSON. Only the SHA-256 outlives the bytes
 * (StudentClaim keeps it after the account or this record is deleted).
 */
const studentVerificationSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  method: { type: String, enum: ['email', 'document'], required: true },
  status: {
    type: String,
    enum: ['pending', 'approved', 'rejected', 'expired'],
    default: 'pending',
  },
  universityEmail: { type: String, default: null, lowercase: true, trim: true },

  // Email method: the pending code. Only a salted hash is stored.
  codeSalt: { type: String, default: null, select: false },
  codeHash: { type: String, default: null, select: false },
  codeExpiresAt: { type: Date, default: null },
  codeAttempts: { type: Number, default: 0 },

  // Document method. `documentData` is the encrypted base64 of the file.
  documentData: { type: String, default: null, select: false },
  documentMime: { type: String, default: null },
  documentSize: { type: Number, default: null },
  documentHash: { type: String, default: null },
  /** When the bytes are deleted (30 days after a decision, SP-32). */
  documentDeleteAt: { type: Date, default: null },
  documentDeletedAt: { type: Date, default: null },

  // Decision.
  reviewedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
  reviewedAt: { type: Date, default: null },
  rejectionReason: { type: String, default: null },

  // The granted year (SP-10): approvedAt .. expiresAt.
  approvedAt: { type: Date, default: null },
  expiresAt: { type: Date, default: null },
  reminderSentAt: { type: Date, default: null },
}, { timestamps: true });

studentVerificationSchema.index({ userId: 1, createdAt: -1 });
studentVerificationSchema.index({ status: 1, method: 1, createdAt: 1 });
studentVerificationSchema.index({ status: 1, expiresAt: 1 });
studentVerificationSchema.index({ documentDeleteAt: 1 }, { sparse: true });

studentVerificationSchema.set('toJSON', {
  transform: (doc, ret) => {
    delete ret.codeSalt;
    delete ret.codeHash;
    delete ret.documentData;
    delete ret.__v;
    return ret;
  },
});

module.exports = mongoose.model('StudentVerification', studentVerificationSchema);
