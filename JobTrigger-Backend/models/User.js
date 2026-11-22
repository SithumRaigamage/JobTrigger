const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
const encryptedFields = require('./plugins/encryptedFields');

// NFR-SEC-08 (AC7): bcrypt work factor. Each step doubles the cost of
// every guess against a leaked hash. Hashes made at a lower cost are
// replaced on the next successful login (needsRehash).
const BCRYPT_COST = 12;
const normalizeEmail = (value) => value.trim().toLowerCase();

const userSchema = new mongoose.Schema({
  // NFR-SEC-08: encrypted at rest (plugin below, which also trims and
  // lower-cases it). Lookups go through `emailHash`.
  email: {
    type: String,
    required: true
  },
  // No default: a unique sparse index counts every null, but skips a
  // missing field (the rows the backfill hasn't reached yet).
  emailHash: {
    type: String
  },
  password: {
    type: String,
    required: true
  },
  // SP-15: `superAdmin` unlocks the website's student review pages. Set only
  // by scripts/grant-role.js on a local database; no API reads it from a
  // request or writes it.
  role: {
    type: String,
    enum: ['user', 'superAdmin'],
    default: 'user'
  },
  // AUD-26: bumped to revoke every token issued before (logout everywhere).
  tokenVersion: {
    type: Number,
    default: 0
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Hash password before saving
userSchema.pre('save', async function() {
  if (!this.isModified('password')) return;
  
  this.password = await bcrypt.hash(this.password, BCRYPT_COST);
});

// Method to compare password
userSchema.methods.comparePassword = async function(candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

/** True when the stored hash was made at a lower cost than BCRYPT_COST. */
userSchema.methods.needsRehash = function() {
  try {
    return bcrypt.getRounds(this.password) < BCRYPT_COST;
  } catch {
    return false;
  }
};

// NFR-SEC-08: one account per email, enforced on the keyed hash (the
// ciphertext differs every time). Sparse until the backfill fills it in.
userSchema.index({ emailHash: 1 }, { unique: true, sparse: true });

userSchema.plugin(encryptedFields, {
  fields: [{ path: 'email', hash: 'emailHash', normalize: normalizeEmail, maxLength: 254 }],
  flagUnreadable: false,
  logEvent: 'pii.decrypt_failed',
});

module.exports = mongoose.model('User', userSchema);
module.exports.BCRYPT_COST = BCRYPT_COST;
