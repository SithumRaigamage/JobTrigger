const { encrypt, decrypt, isEncrypted } = require('../../security/secretCipher');
const { logger } = require('../../lib/logger');

/**
 * AUD-03: stores [fields] encrypted (security/secretCipher.js) and hands
 * back plaintext when read, including in JSON responses, so the API
 * contract is unchanged. Setters also run on update queries, so
 * findOneAndUpdate `$set`s are encrypted too.
 *
 * Non-strings pass through untouched so mongoose's cast rejects them (a
 * 400), and empty strings stay empty (nothing to protect, and `required`
 * still sees them).
 *
 * AUD-63: the read side is tolerant. `decrypt` throws when the key id is
 * gone from the keyring or the GCM tag doesn't check out, and because
 * `toJSON` runs the getters, one such row made the whole list 500 and
 * cost the user every server, not just the broken one. The getter now
 * drops the secret (null) and flags the credential with
 * `needsReentry: true`, so the client asks for that one secret again
 * and the other credentials stay usable.
 */
module.exports = function encryptedFields(schema, { fields }) {
  for (const field of fields) {
    schema.path(field).set((value) =>
      typeof value !== 'string' || value === '' || isEncrypted(value)
        ? value
        : encrypt(value, field),
    );
    // Mongoose calls a path getter with the document as `this`, which is
    // how the failure is recorded for the toJSON transform below.
    schema.path(field).get(function (value) {
      if (typeof value !== 'string' || value === '') return value;
      try {
        return decrypt(value, field);
      } catch {
        recordUnreadable(this, field);
        return null;
      }
    });
  }
  schema.set('toJSON', { getters: true, virtuals: false, transform: withNeedsReentry });
  schema.set('toObject', { getters: true, virtuals: false, transform: withNeedsReentry });
};

/**
 * Records that [doc]'s [field] could not be decrypted, and says so in the
 * log. The line names the model, the document and the field, and nothing
 * else: not the ciphertext, not the plaintext, not a part of the secret.
 */
function recordUnreadable(doc, field) {
  if (!doc) return;
  const locals = doc.$locals;
  const failures = locals.unreadableSecrets ??= new Set();
  // Once per field per document: the getter runs again on every read.
  if (failures.has(field)) return;
  failures.add(field);
  logger.error('credential.decrypt_failed', {
    model: doc.constructor?.modelName,
    credentialId: doc._id?.toString(),
    field,
  });
}

/**
 * Adds `needsReentry` to every credential, true when a secret could not
 * be read. It is always present, so the client can rely on it.
 */
function withNeedsReentry(doc, ret) {
  ret.needsReentry = Boolean(doc?.$locals?.unreadableSecrets?.size);
  return ret;
}
