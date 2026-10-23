const { configuredKeyIds, keyIdOf, PREFIX } = require('./secretCipher');

/**
 * AUD-63: a key id dropped from the keyring too early (for example a
 * previous key removed from CREDENTIALS_ENCRYPTION_PREVIOUS_KEYS before
 * the rows it encrypts were re-encrypted) leaves secrets the server can
 * no longer read.
 *
 * This counts, per key id, how many stored secrets use it, so the
 * startup check can name the ids that are missing from the keyring and
 * how many rows each one holds.
 */

/** How many stored secrets use each key id, across every target. */
async function countKeyIds(targets) {
  const counts = new Map();
  for (const { Model, fields } of targets) {
    for (const field of fields) {
      // The raw collection: no getters, no setters, so the values are
      // exactly as stored.
      const cursor = Model.collection.find(
        { [field]: { $regex: `^${PREFIX}` } },
        { projection: { [field]: 1 } },
      );
      for await (const raw of cursor) {
        const keyId = keyIdOf(raw[field]);
        if (!keyId) continue;
        counts.set(keyId, (counts.get(keyId) ?? 0) + 1);
      }
    }
  }
  return counts;
}

/**
 * The key ids the database still uses that the keyring cannot decrypt,
 * with the number of rows each one holds. Also returns every key id in
 * use, so the caller can report the healthy case too.
 */
async function auditKeyIds(targets, { ring } = {}) {
  const { keyIds } = configuredKeyIds(ring);
  const configured = new Set(keyIds);
  const counts = await countKeyIds(targets);
  const missing = [];
  for (const [keyId, count] of counts) {
    if (!configured.has(keyId)) missing.push({ keyId, count });
  }
  missing.sort((a, b) => a.keyId.localeCompare(b.keyId));
  return { missing, counts: Object.fromEntries(counts) };
}

module.exports = { auditKeyIds, countKeyIds };
