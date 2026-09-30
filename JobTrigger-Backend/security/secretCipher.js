const crypto = require('crypto');

/**
 * AUD-03: AES-256-GCM for the tool secrets stored in MongoDB (Jenkins
 * passwords and API tokens, GitHub PATs, SonarQube tokens).
 *
 * Stored form: `enc:v1:<keyId>:<iv>:<tag>:<ciphertext>` (base64url parts).
 * The key id makes rotation possible: new writes use the current key, and
 * older ids stay readable through CREDENTIALS_ENCRYPTION_PREVIOUS_KEYS. The
 * field name is bound in as associated data, so a ciphertext can't be
 * moved into a different field and still decrypt.
 *
 * Keys come from the environment, never from the database:
 * - CREDENTIALS_ENCRYPTION_KEY: base64 of 32 random bytes (required)
 * - CREDENTIALS_ENCRYPTION_KEY_ID: its id (default `k1`)
 * - CREDENTIALS_ENCRYPTION_PREVIOUS_KEYS: `id:base64,id:base64`, read-only
 */

const PREFIX = 'enc:v1:';
const KEY_ID_PATTERN = /^[A-Za-z0-9_-]{1,32}$/;

function parseKey(id, base64, name) {
  if (!KEY_ID_PATTERN.test(id)) {
    throw new Error(`${name}: key id '${id}' must be 1-32 letters, digits, _ or -`);
  }
  const key = Buffer.from(base64 ?? '', 'base64');
  if (key.length !== 32) {
    throw new Error(`${name} must be base64 of exactly 32 bytes`);
  }
  return key;
}

/** Reads the keys from [env]; throws a descriptive Error when invalid. */
function loadKeys(env = process.env) {
  const currentId = env.CREDENTIALS_ENCRYPTION_KEY_ID?.trim() || 'k1';
  const keys = new Map([
    [currentId, parseKey(currentId, env.CREDENTIALS_ENCRYPTION_KEY, 'CREDENTIALS_ENCRYPTION_KEY')],
  ]);
  for (const entry of (env.CREDENTIALS_ENCRYPTION_PREVIOUS_KEYS ?? '').split(',')) {
    if (!entry.trim()) continue;
    const [id, base64] = entry.trim().split(':');
    if (!keys.has(id)) {
      keys.set(id, parseKey(id, base64, 'CREDENTIALS_ENCRYPTION_PREVIOUS_KEYS'));
    }
  }
  return { currentId, keys };
}

let cached;
const keyring = () => (cached ??= loadKeys());

/** For tests that change the environment. */
function resetKeys() {
  cached = undefined;
}

const isEncrypted = (value) => typeof value === 'string' && value.startsWith(PREFIX);

function encrypt(plaintext, field, ring = keyring()) {
  const key = ring.keys.get(ring.currentId);
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
  cipher.setAAD(Buffer.from(field, 'utf8'));
  const ciphertext = Buffer.concat([cipher.update(plaintext, 'utf8'), cipher.final()]);
  return PREFIX + [
    ring.currentId,
    iv.toString('base64url'),
    cipher.getAuthTag().toString('base64url'),
    ciphertext.toString('base64url'),
  ].join(':');
}

/**
 * Plaintext of [stored]. A value without the prefix is a row written before
 * encryption (see scripts/encrypt-credentials.js) and is returned as-is.
 */
function decrypt(stored, field, ring = keyring()) {
  if (!isEncrypted(stored)) return stored;
  const [keyId, iv, tag, ciphertext] = stored.slice(PREFIX.length).split(':');
  const key = ring.keys.get(keyId);
  if (!key) throw new Error(`No key '${keyId}' configured to decrypt ${field}`);
  const decipher = crypto.createDecipheriv('aes-256-gcm', key, Buffer.from(iv, 'base64url'));
  decipher.setAAD(Buffer.from(field, 'utf8'));
  decipher.setAuthTag(Buffer.from(tag, 'base64url'));
  return Buffer.concat([
    decipher.update(Buffer.from(ciphertext, 'base64url')),
    decipher.final(),
  ]).toString('utf8');
}

/** True when [stored] was written with an older key (rotate it). */
const needsRotation = (stored, ring = keyring()) =>
  isEncrypted(stored) && stored.slice(PREFIX.length).split(':')[0] !== ring.currentId;

module.exports = { encrypt, decrypt, isEncrypted, needsRotation, loadKeys, resetKeys };
