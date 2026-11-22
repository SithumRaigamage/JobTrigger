/**
 * AUD-03 / NFR-SEC-08 backfill and key rotation. Encrypts every field the
 * models encrypt (tool secrets and personal data) that was written before
 * encryption, re-encrypts values written with an older key, fills in the
 * lookup hashes (`User.emailHash`, …), moves student email claims to the
 * keyed hash, and drops the old plain-email unique index. Safe to re-run:
 * a second run changes nothing.
 *
 *   node scripts/encrypt-credentials.js --dry-run         # count only, writes nothing
 *   node scripts/encrypt-credentials.js                   # back up, then write
 *   node scripts/encrypt-credentials.js --restore <file>  # put a backup back
 *
 * Before writing, every affected collection is saved to
 * `backups/pii-<timestamp>.enc`: Extended JSON encrypted with the current
 * key (a backup is as sensitive as the database, so it is never plaintext
 * on disk). Needs MONGODB_URI and the same CREDENTIALS_ENCRYPTION_* (and
 * PII_INDEX_KEY, if set) as the server. Design:
 * docs/design/NFR-SEC-08-pii-at-rest.md.
 */
const fs = require('fs');
const path = require('path');
const mongoose = require('mongoose');
const { encrypt, decrypt, isEncrypted, needsRotation, loadKeys } = require('../security/secretCipher');
const { blindIndex, loadIndexKey } = require('../security/blindIndex');
const { valuesAt } = require('../security/keyIdAudit');
// The same list the startup key-id audit uses (AUD-63), so a new
// encrypted model can't be left out of the backfill.
const ENCRYPTED_TARGETS = require('../models/encryptedTargets');
const StudentClaim = require('../models/StudentClaim');
const StudentVerification = require('../models/StudentVerification');
const User = require('../models/User');
const student = require('../lib/student');
const { connectDatabase, connectionHint } = require('../lib/database');

const { EJSON } = mongoose.mongo.BSON;
const BACKUP_DIR = path.join(__dirname, '..', 'backups');
const BACKUP_FIELD = 'pii-backup';
const normalizeEmail = (value) => value.trim().toLowerCase();

/**
 * [stored] encrypted under the current key, or null when it already is (or
 * holds nothing). `unreadable` when an old value can't be decrypted.
 */
function reencrypt(stored, field) {
  if (typeof stored !== 'string' || stored === '') return { next: null };
  if (!isEncrypted(stored)) return { next: encrypt(stored, field) };
  if (!needsRotation(stored)) return { next: null };
  try {
    return { next: encrypt(decrypt(stored, field), field) };
  } catch {
    // AUD-63: a row the keyring can't read (a key id dropped too early)
    // must not abort the backfill of every other row. It is counted and
    // left alone; the startup audit names it.
    return { next: null, unreadable: true };
  }
}

/** Plaintext of [stored], or null when it can't be read. */
function plaintextOf(stored, field) {
  if (typeof stored !== 'string' || stored === '') return null;
  try {
    return decrypt(stored, field);
  } catch {
    return null;
  }
}

/** The `$set` that brings one raw document up to date (may be empty). */
function updateFor(raw, { fields, hashes = {} }) {
  const $set = {};
  let unreadable = 0;
  for (const field of fields) {
    const [head, ...rest] = field.split('.');
    if (rest.length === 0) {
      const { next, unreadable: bad } = reencrypt(raw[head], field);
      if (bad) unreadable += 1;
      if (next) $set[head] = next;
      continue;
    }
    // A field inside a subdocument array: one `$set` per item.
    valuesAt(raw, field).forEach((value, index) => {
      const { next, unreadable: bad } = reencrypt(value, field);
      if (bad) unreadable += 1;
      if (next) $set[`${head}.${index}.${rest.join('.')}`] = next;
    });
  }
  for (const [field, hashField] of Object.entries(hashes)) {
    if (typeof raw[hashField] === 'string') continue;
    const plain = plaintextOf(raw[field], field);
    if (plain) $set[hashField] = blindIndex(field, normalizeEmail(plain));
  }
  return { $set, unreadable };
}

/** Returns how many documents needed (or, unless [dryRun], got) changes. */
async function encryptExistingCredentials({ dryRun = false, log = console.log, targets = ENCRYPTED_TARGETS } = {}) {
  let total = 0;
  for (const target of targets) {
    const { Model, fields, hashes = {} } = target;
    let changed = 0;
    let unreadable = 0;
    // The raw collection: no getters or setters, so values are exactly as
    // stored.
    const projection = Object.fromEntries(
      [...fields.map((field) => field.split('.')[0]), ...Object.values(hashes)].map((name) => [name, 1]),
    );
    for await (const raw of Model.collection.find({}, { projection })) {
      const { $set, unreadable: bad } = updateFor(raw, target);
      unreadable += bad;
      if (Object.keys($set).length === 0) continue;
      changed += 1;
      if (!dryRun) await Model.collection.updateOne({ _id: raw._id }, { $set });
    }
    log(
      `${Model.modelName}: ${changed} document(s) ${dryRun ? 'to update' : 'updated'}` +
        (unreadable > 0 ? `, ${unreadable} value(s) not readable` : ''),
    );
    total += changed;
  }
  return total;
}

/**
 * AC5: student email claims move from plain SHA-256 to the keyed hash.
 * The university emails on the verification records say which claim is
 * whose. Returns the number of claims converted (or to convert).
 */
async function convertStudentClaims({ dryRun = false, log = console.log } = {}) {
  let converted = 0;
  const seen = new Set();
  const cursor = StudentVerification.collection.find(
    { universityEmail: { $type: 'string' } },
    { projection: { universityEmail: 1 } },
  );
  for await (const raw of cursor) {
    const plain = plaintextOf(raw.universityEmail, 'universityEmail');
    if (!plain || seen.has(plain)) continue;
    seen.add(plain);
    const legacy = student.legacyEmailHash(plain);
    const keyed = student.emailHash(plain);
    if (!(await StudentClaim.collection.findOne({ kind: 'email', hash: legacy }))) continue;
    converted += 1;
    if (dryRun) continue;
    if (await StudentClaim.collection.findOne({ kind: 'email', hash: keyed })) {
      await StudentClaim.collection.deleteOne({ kind: 'email', hash: legacy });
    } else {
      await StudentClaim.collection.updateOne({ kind: 'email', hash: legacy }, { $set: { hash: keyed } });
    }
  }
  log(`StudentClaim: ${converted} email claim(s) ${dryRun ? 'to convert' : 'converted'}`);
  return converted;
}

/**
 * The old unique index on the plain email means nothing on ciphertext;
 * uniqueness now lives on `emailHash`. Returns true when it was (or would
 * be) dropped.
 */
async function replaceEmailIndex({ dryRun = false, log = console.log } = {}) {
  const indexes = await User.collection.indexes().catch(() => []);
  const legacy = indexes.find((index) => index.name === 'email_1');
  if (!dryRun) {
    if (legacy) await User.collection.dropIndex('email_1');
    await User.createIndexes();
  }
  log(`User: old email index ${legacy ? (dryRun ? 'to drop' : 'dropped') : 'already gone'}`);
  return Boolean(legacy);
}

/** Every collection the backfill writes to. */
const backupCollections = () => [
  ...new Set([...ENCRYPTED_TARGETS.map(({ Model }) => Model.collection), StudentClaim.collection]),
];

/** Writes the encrypted backup and returns its path. */
async function writeBackup({ dir = BACKUP_DIR } = {}) {
  const collections = {};
  for (const collection of backupCollections()) {
    collections[collection.collectionName] = await collection.find({}).toArray();
  }
  const json = EJSON.stringify({ createdAt: new Date(), collections }, { relaxed: false });
  fs.mkdirSync(dir, { recursive: true, mode: 0o700 });
  const file = path.join(dir, `pii-${new Date().toISOString().replace(/[:.]/g, '-')}.enc`);
  fs.writeFileSync(file, encrypt(json, BACKUP_FIELD), { mode: 0o600 });
  return file;
}

/** Replaces the backed-up collections' documents with [file]'s. */
async function restoreBackup(file, { log = console.log } = {}) {
  const { collections } = EJSON.parse(decrypt(fs.readFileSync(file, 'utf8').trim(), BACKUP_FIELD), { relaxed: false });
  const db = mongoose.connection.db;
  for (const [name, docs] of Object.entries(collections)) {
    await db.collection(name).deleteMany({});
    if (docs.length > 0) await db.collection(name).insertMany(docs);
    log(`${name}: ${docs.length} document(s) restored`);
  }
}

/** Backup, backfill, claims, index. Returns the backup path (or null). */
async function migrate({ dryRun = false, log = console.log, backupDir } = {}) {
  const backup = dryRun ? null : await writeBackup({ dir: backupDir });
  if (backup) log(`Backup written: ${backup}`);
  // Claims first: they're found through the university emails, which the
  // backfill then encrypts (both readings work either way).
  await convertStudentClaims({ dryRun, log });
  const total = await encryptExistingCredentials({ dryRun, log });
  await replaceEmailIndex({ dryRun, log });
  log(`${dryRun ? 'Dry run' : 'Done'}: ${total} document(s).`);
  return backup;
}

async function main() {
  require('dotenv').config({ path: path.join(__dirname, '../.env') });
  const dryRun = process.argv.includes('--dry-run');
  const restoreAt = process.argv.indexOf('--restore');
  try {
    // Fail before touching anything if the keys are unusable.
    loadKeys();
    loadIndexKey();
    await connectDatabase();
    if (restoreAt !== -1) {
      const file = process.argv[restoreAt + 1];
      if (!file) throw new Error('--restore needs the backup file');
      await restoreBackup(path.resolve(file));
    } else {
      await migrate({ dryRun });
    }
    process.exitCode = 0;
  } catch (err) {
    console.error('Encryption backfill failed:', err.message);
    const hint = connectionHint(err);
    if (hint) console.error(hint);
    process.exitCode = 1;
  } finally {
    await mongoose.disconnect();
  }
}

if (require.main === module) main();

module.exports = {
  encryptExistingCredentials,
  convertStudentClaims,
  replaceEmailIndex,
  writeBackup,
  restoreBackup,
  migrate,
};
