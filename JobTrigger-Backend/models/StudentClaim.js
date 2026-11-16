const mongoose = require('mongoose');

/**
 * Phase 21 (SP-14, note 6): "one student grant per person, ever". When a
 * university email or a document is used for an approved grant, its SHA-256
 * is kept here, with no user id, so deleting the account or the application
 * can't be used to claim again. The unique index makes the claim atomic:
 * two accounts racing for the same email or document can't both win.
 *
 * Nothing here can be turned back into the email or the file.
 */
const studentClaimSchema = new mongoose.Schema({
  kind: { type: String, enum: ['email', 'document'], required: true },
  hash: { type: String, required: true },
  createdAt: { type: Date, default: Date.now },
}, { versionKey: false });

studentClaimSchema.index({ kind: 1, hash: 1 }, { unique: true });

module.exports = mongoose.model('StudentClaim', studentClaimSchema);
