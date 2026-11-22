const mongoose = require('mongoose');
const { encrypt, decrypt, isEncrypted } = require('../../security/secretCipher');
const { blindIndex } = require('../../security/blindIndex');
const { logger } = require('../../lib/logger');

/**
 * AUD-03 / NFR-SEC-08: stores [fields] encrypted (security/secretCipher.js)
 * and hands back plaintext when read, so the API contract is unchanged.
 * Design: docs/design/NFR-SEC-08-pii-at-rest.md.
 *
 * A field is a name (`'token'`) or a spec:
 *   { path, hash?, normalize?, maxLength?, minLength? }
 * - `path` may reach into a subdocument array (`'invites.email'`).
 * - `hash` names a sibling field kept equal to a keyed hash of the
 *   plaintext (security/blindIndex.js). A query filter on the encrypted
 *   field is rewritten to it, so `findOne({ email })` keeps working. Any
 *   other kind of query on an encrypted field throws instead of silently
 *   matching nothing.
 * - `normalize` runs before encrypting and before hashing.
 * - `maxLength`/`minLength` are checked on the plaintext (mongoose's own
 *   validators would see the ciphertext).
 *
 * Setters also run on update queries, so `$set`s are encrypted too.
 * Non-strings pass through untouched so mongoose's cast rejects them (a
 * 400), and empty strings stay empty (nothing to protect, and `required`
 * still sees them).
 *
 * `.lean()` skips getters, so a post-query hook decrypts lean results
 * (and `populate`, which runs a lean query of its own when asked to).
 *
 * AUD-63: the read side is tolerant. A value whose key id is gone or
 * whose GCM tag doesn't check out reads as null and is logged once, and
 * credentials (`flagUnreadable`) carry `needsReentry: true` in JSON so the
 * client asks for that one secret again.
 */
const QUERY_OPS = [
  'countDocuments', 'deleteMany', 'deleteOne', 'distinct', 'find', 'findOne',
  'findOneAndDelete', 'findOneAndReplace', 'findOneAndUpdate', 'replaceOne',
  'updateMany', 'updateOne',
];
const UPDATE_OPS = ['findOneAndUpdate', 'findOneAndReplace', 'replaceOne', 'updateMany', 'updateOne'];
const RESULT_OPS = ['find', 'findOne', 'findOneAndDelete', 'findOneAndReplace', 'findOneAndUpdate'];

/** The spec for [field]: a bare name becomes `{ path }`. */
const toSpec = (field) => (typeof field === 'string' ? { path: field } : { ...field });

/** The schema type for [path], following one level of subdocument array. */
function schemaTypeAt(schema, path) {
  const direct = schema.path(path);
  if (direct) return direct;
  const [head, ...rest] = path.split('.');
  const parent = schema.path(head);
  const inner = parent?.schema?.path(rest.join('.'));
  if (!inner) throw new Error(`encryptedFields: no path '${path}'`);
  return inner;
}

/** Decrypts [value] for [field] or returns null when it can't be read. */
function readable(value, field) {
  if (typeof value !== 'string' || value === '') return { value, ok: true };
  try {
    return { value: decrypt(value, field), ok: true };
  } catch {
    return { value: null, ok: false };
  }
}

module.exports = function encryptedFields(schema, {
  fields,
  flagUnreadable = true,
  logEvent = 'credential.decrypt_failed',
}) {
  const specs = fields.map(toSpec);
  const hashed = specs.filter((spec) => spec.hash);
  const byPath = new Map(specs.map((spec) => [spec.path, spec]));
  const clean = (spec, value) => (spec.normalize ? spec.normalize(value) : value);
  const hashOf = (spec, plain) => blindIndex(spec.path, clean(spec, plain));

  for (const spec of hashed) {
    if (spec.path.includes('.')) throw new Error(`encryptedFields: no hash on nested '${spec.path}'`);
    if (!schema.path(spec.hash)) throw new Error(`encryptedFields: declare '${spec.hash}' in the schema`);
  }

  for (const spec of specs) {
    // The field name is the cipher's associated data; a bare name keeps
    // the AUD-03 values (`password`, `token`, …) readable as they are.
    const field = spec.path;
    const type = schemaTypeAt(schema, field);
    type.set((value) => {
      if (typeof value !== 'string' || value === '' || isEncrypted(value)) return value;
      const plain = clean(spec, value);
      return plain === '' ? plain : encrypt(plain, field);
    });
    // Mongoose calls a path getter with the document as `this`, which is
    // how the failure is recorded for the toJSON transform below.
    type.get(function (value) {
      const read = readable(value, field);
      if (!read.ok) recordUnreadable(this, field, logEvent);
      return read.value;
    });
    if (spec.maxLength || spec.minLength) {
      type.validate({
        validator(value) {
          const { value: plain } = readable(value, field);
          if (typeof plain !== 'string' || plain === '') return true;
          return (!spec.maxLength || plain.length <= spec.maxLength) &&
            (!spec.minLength || plain.length >= spec.minLength);
        },
        message: `${field} has the wrong length`,
      });
    }
  }

  // Hash fields follow the plaintext on save…
  if (hashed.length > 0) {
    schema.pre('validate', function () {
      for (const spec of hashed) {
        if (!this.isNew) {
          // A document loaded without the field (a projection) must not
          // have its hash wiped on save.
          if (!this.isSelected(spec.path)) continue;
          const hashKnown = this.isSelected(spec.hash) && this.get(spec.hash) != null;
          if (!this.isModified(spec.path) && (hashKnown || !this.isSelected(spec.hash))) continue;
        }
        const plain = this.get(spec.path);
        // Missing rather than null, so a unique sparse index allows many.
        this.set(spec.hash, typeof plain === 'string' && plain !== '' ? hashOf(spec, plain) : undefined);
      }
    });

    // …and on update queries.
    schema.pre(UPDATE_OPS, { document: false, query: true }, function () {
      const update = this.getUpdate();
      if (!update || Array.isArray(update)) return;
      for (const spec of hashed) {
        for (const holder of [update, update.$set]) {
          if (!holder || !Object.hasOwn(holder, spec.path)) continue;
          const { value } = readable(holder[spec.path], spec.path);
          if (typeof value === 'string' && value !== '') {
            update.$set ??= {};
            update.$set[spec.hash] = hashOf(spec, value);
          } else {
            update.$unset ??= {};
            update.$unset[spec.hash] = '';
          }
        }
        if (update.$unset && Object.hasOwn(update.$unset, spec.path)) update.$unset[spec.hash] = '';
      }
      this.setUpdate(update);
    });
  }

  // Filters on an encrypted field become filters on its hash.
  function hashCondition(spec, value) {
    if (value === null) return null;
    if (typeof value === 'string') return hashOf(spec, value);
    if (value && typeof value === 'object' && !Array.isArray(value)) {
      const keys = Object.keys(value);
      if (keys.length === 1 && keys[0] === '$eq' && typeof value.$eq === 'string') {
        return hashOf(spec, value.$eq);
      }
      if (keys.length === 1 && keys[0] === '$in' && Array.isArray(value.$in) &&
          value.$in.every((v) => typeof v === 'string')) {
        // Our own operator, built from strings: trusted (AUD-04).
        return mongoose.trusted({ $in: value.$in.map((v) => hashOf(spec, v)) });
      }
    }
    throw new Error(`${spec.path} is encrypted: only an exact match can be queried`);
  }

  function rewriteFilter(filter) {
    if (!filter || typeof filter !== 'object') return;
    for (const op of ['$and', '$or', '$nor']) {
      if (Array.isArray(filter[op])) filter[op].forEach(rewriteFilter);
    }
    for (const key of Object.keys(filter)) {
      const spec = byPath.get(key);
      if (!spec) continue;
      if (!spec.hash) throw new Error(`${key} is encrypted and can't be queried`);
      const condition = hashCondition(spec, filter[key]);
      delete filter[key];
      filter[spec.hash] = condition;
    }
  }

  schema.pre(QUERY_OPS, { document: false, query: true }, function () {
    const filter = this.getFilter();
    rewriteFilter(filter);
    this.setQuery(filter);
  });

  // Lean results skip getters: decrypt them here.
  function decryptPlain(doc) {
    if (!doc || typeof doc !== 'object') return;
    for (const spec of specs) {
      const [head, ...rest] = spec.path.split('.');
      if (rest.length === 0) {
        if (Object.hasOwn(doc, head)) {
          const read = readable(doc[head], spec.path);
          if (!read.ok) logger.error(logEvent, { credentialId: doc._id?.toString(), field: spec.path });
          doc[head] = read.value;
        }
        continue;
      }
      const leaf = rest.join('.');
      for (const item of Array.isArray(doc[head]) ? doc[head] : []) {
        if (item && Object.hasOwn(item, leaf)) item[leaf] = readable(item[leaf], spec.path).value;
      }
    }
  }

  schema.post(RESULT_OPS, function (result) {
    if (!this.mongooseOptions().lean || !result) return;
    for (const doc of Array.isArray(result) ? result : [result]) decryptPlain(doc);
  });

  // JSON and plain objects read through the getters; hash fields stay in.
  const extra = (doc, ret) => {
    if (flagUnreadable) ret.needsReentry = Boolean(doc?.$locals?.unreadableSecrets?.size);
    for (const spec of hashed) delete ret[spec.hash];
    return ret;
  };
  for (const name of ['toJSON', 'toObject']) {
    const existing = schema.get(name) ?? {};
    const prior = existing.transform;
    schema.set(name, {
      ...existing,
      getters: true,
      virtuals: existing.virtuals ?? false,
      transform(doc, ret, options) {
        const out = typeof prior === 'function' ? (prior(doc, ret, options) ?? ret) : ret;
        return extra(doc, out);
      },
    });
  }
};

/**
 * Records that [doc]'s [field] could not be decrypted, and says so in the
 * log. The line names the model, the document and the field, and nothing
 * else: not the ciphertext, not the plaintext, not a part of the secret.
 */
function recordUnreadable(doc, field, logEvent) {
  const locals = doc?.$locals;
  if (!locals) return;
  const failures = locals.unreadableSecrets ??= new Set();
  // Once per field per document: the getter runs again on every read.
  if (failures.has(field)) return;
  failures.add(field);
  logger.error(logEvent, {
    model: doc.constructor?.modelName,
    credentialId: doc._id?.toString(),
    field,
  });
}
