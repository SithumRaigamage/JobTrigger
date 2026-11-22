const crypto = require('crypto');
const { loadKeys } = require('./secretCipher');

/**
 * NFR-SEC-08: a keyed hash ("blind index") of a personal value, so an
 * encrypted field can still be found by exact match. Encryption uses a
 * random IV, so the same email never encrypts to the same text twice;
 * the HMAC of its normalized form does, and without the key it can't be
 * reversed by guessing emails (a plain SHA-256 can).
 *
 * The key is PII_INDEX_KEY (base64 of 32 bytes) when set. Otherwise it is
 * derived with HKDF from the encryption key whose id is
 * PII_INDEX_SOURCE_KEY_ID (default `k1`, or the current key when there is
 * no `k1`). It must not change for the life of the data, which is why it
 * comes from a fixed key id rather than whichever key is current.
 * Design: docs/design/NFR-SEC-08-pii-at-rest.md.
 */

function loadIndexKey(env = process.env) {
  const explicit = env.PII_INDEX_KEY?.trim();
  if (explicit) {
    const key = Buffer.from(explicit, 'base64');
    if (key.length !== 32) throw new Error('PII_INDEX_KEY must be base64 of exactly 32 bytes');
    return key;
  }
  const { currentId, keys } = loadKeys(env);
  const sourceId = env.PII_INDEX_SOURCE_KEY_ID?.trim() || (keys.has('k1') ? 'k1' : currentId);
  const source = keys.get(sourceId);
  if (!source) {
    throw new Error(`PII_INDEX_SOURCE_KEY_ID '${sourceId}' is not in the encryption keyring`);
  }
  return Buffer.from(crypto.hkdfSync('sha256', source, 'jobtrigger-pii-index', 'blind-index-v1', 32));
}

let cached;
const indexKey = () => (cached ??= loadIndexKey());

/** For tests that change the environment. */
function resetIndexKey() {
  cached = undefined;
}

/** Hex HMAC of [value] for [field]; the field name keeps fields apart. */
function blindIndex(field, value, key = indexKey()) {
  return crypto.createHmac('sha256', key).update(`${field}:${value}`, 'utf8').digest('hex');
}

module.exports = { blindIndex, loadIndexKey, resetIndexKey };
