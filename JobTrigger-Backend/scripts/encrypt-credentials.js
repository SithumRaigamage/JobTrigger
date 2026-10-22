/**
 * AUD-03 backfill and key rotation. Encrypts tool secrets written before
 * encryption at rest, and re-encrypts ones written with an older key. Safe
 * to re-run: values already under the current key are left alone.
 *
 *   node scripts/encrypt-credentials.js --dry-run   # count only
 *   node scripts/encrypt-credentials.js             # write
 *
 * Needs MONGODB_URI and the same CREDENTIALS_ENCRYPTION_* settings as the
 * server (see docs/deployment.md). Back up the collections first.
 */
const path = require('path');
const mongoose = require('mongoose');
const { encrypt, decrypt, isEncrypted, needsRotation, loadKeys } = require('../security/secretCipher');
// The same list the startup key-id audit uses (AUD-63), so a new
// credential model can't be left out of the backfill.
const CREDENTIAL_TARGETS = require('../models/credentialTargets');

/** Returns how many documents needed (or, unless [dryRun], got) changes. */
async function encryptExistingCredentials({ dryRun = false, log = console.log } = {}) {
  let total = 0;
  for (const { Model, fields } of CREDENTIAL_TARGETS) {
    let changed = 0;
    let unreadable = 0;
    // The raw collection: no getters or setters, so values are exactly as
    // stored.
    const projection = Object.fromEntries(fields.map((field) => [field, 1]));
    for await (const raw of Model.collection.find({}, { projection })) {
      const $set = {};
      for (const field of fields) {
        const value = raw[field];
        if (typeof value !== 'string' || value === '') continue;
        if (!isEncrypted(value)) {
          $set[field] = encrypt(value, field);
        } else if (needsRotation(value)) {
          let plaintext;
          try {
            plaintext = decrypt(value, field);
          } catch {
            // AUD-63: a row the keyring can't read (a key id dropped too
            // early) must not abort the backfill of every other row. It
            // is counted and left alone; the startup audit names it.
            unreadable += 1;
            continue;
          }
          $set[field] = encrypt(plaintext, field);
        }
      }
      if (Object.keys($set).length === 0) continue;
      changed += 1;
      if (!dryRun) await Model.collection.updateOne({ _id: raw._id }, { $set });
    }
    log(
      `${Model.modelName}: ${changed} document(s) ${dryRun ? 'to update' : 'updated'}` +
        (unreadable > 0 ? `, ${unreadable} secret(s) not readable` : ''),
    );
    total += changed;
  }
  return total;
}

async function main() {
  require('dotenv').config({ path: path.join(__dirname, '../.env') });
  const dryRun = process.argv.includes('--dry-run');
  try {
    loadKeys(); // Fail before touching anything if the keys are unusable.
    await mongoose.connect(process.env.MONGODB_URI, { dbName: 'jobtrigger' });
    const total = await encryptExistingCredentials({ dryRun });
    console.log(`${dryRun ? 'Dry run' : 'Done'}: ${total} document(s).`);
    process.exitCode = 0;
  } catch (err) {
    console.error('Encryption backfill failed:', err.message);
    process.exitCode = 1;
  } finally {
    await mongoose.disconnect();
  }
}

if (require.main === module) main();

module.exports = { encryptExistingCredentials };
