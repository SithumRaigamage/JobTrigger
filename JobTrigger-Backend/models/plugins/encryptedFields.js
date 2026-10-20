const { encrypt, decrypt, isEncrypted } = require('../../security/secretCipher');

/**
 * AUD-03: stores [fields] encrypted (security/secretCipher.js) and hands
 * back plaintext when read, including in JSON responses, so the API
 * contract is unchanged. Setters also run on update queries, so
 * findOneAndUpdate `$set`s are encrypted too.
 *
 * Non-strings pass through untouched so mongoose's cast rejects them (a
 * 400), and empty strings stay empty (nothing to protect, and `required`
 * still sees them).
 */
module.exports = function encryptedFields(schema, { fields }) {
  for (const field of fields) {
    schema.path(field).set((value) =>
      typeof value !== 'string' || value === '' || isEncrypted(value)
        ? value
        : encrypt(value, field),
    );
    schema.path(field).get((value) =>
      typeof value === 'string' && value !== '' ? decrypt(value, field) : value,
    );
  }
  schema.set('toJSON', { getters: true, virtuals: false });
  schema.set('toObject', { getters: true, virtuals: false });
};
