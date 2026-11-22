# NFR-SEC-08 — Personal data encrypted at rest (design)

Story: `docs/user-stories/shared/09-non-functional-security.md#nfr-sec-08`.
Owner decision 2026-11-22: option A — encrypt emails too, and accept that
admin search becomes exact-email only.

## Encryption

Reuses `security/secretCipher.js` (AES-256-GCM, random 96-bit IV, field
name as associated data, key id in every value for rotation). Nothing new
is invented here.

`models/plugins/encryptedFields.js` grows from "secrets only" into the one
place that encrypts a field. A field is either a name (`'token'`) or a spec:

```js
{ path: 'email', hash: 'emailHash', normalize: (v) => v.trim().toLowerCase(), maxLength: 254 }
```

- **Setter** — normalize, then encrypt (skips empty strings, non-strings and
  values that are already encrypted).
- **Getter** — decrypt; an unreadable value becomes `null` (AUD-63).
- **`.lean()` and `populate`** — a post-query hook decrypts results, since
  lean skips getters. Without it every `.lean()` call would leak ciphertext
  into responses.
- **Hash field** (`hash`) — HMAC-SHA256 of the normalized plaintext, kept in
  sync on save and on update queries. A query filter on the encrypted field
  (`{ email: 'a@b.c' }`, `$eq`, `$in`) is rewritten to the hash field, so
  existing lookups keep working unchanged. Any other operator (`$regex`,
  `$gt`, …) on an encrypted field throws, because it could never match
  ciphertext and would fail silently.
- **Length limits** (`maxLength`/`minLength`) — checked on the plaintext,
  because mongoose's built-in validators see the ciphertext.
- **Subdocument arrays** — a path like `invites.email` is encrypted inside
  each array item (no hash support there; nothing queries it).

## The hash key (blind index)

`security/blindIndex.js`. HMAC-SHA256 over `"<field>:<normalized value>"`,
with a 32-byte key that is:

1. `PII_INDEX_KEY` (base64, 32 bytes) when set, otherwise
2. derived with HKDF-SHA256 from the encryption key whose id is
   `PII_INDEX_SOURCE_KEY_ID` (default `k1`; the current key if there is no
   `k1`).

So no new secret is needed today. The key must stay the same for the life of
the data, which is why it comes from a fixed key id and not "the current
key": rotating `CREDENTIALS_ENCRYPTION_KEY` to `k2` keeps the hashes valid as
long as `k1` stays in `CREDENTIALS_ENCRYPTION_PREVIOUS_KEYS` (rotation already
requires that until the backfill re-encrypts). To retire `k1` for good, set
`PII_INDEX_KEY` to an explicit value first and re-run the backfill.

## Fields

| Model | Encrypted | Hash for lookups |
|---|---|---|
| User | email | emailHash (unique, sparse) |
| StudentVerification | fullName, universityEmail | universityEmailHash |
| SupportTicket | subject, message, replyEmail, serverHost | — |
| Team | invites[].email | — |
| JenkinsCredential | jenkinsURL, username (+ password, paramToken) | — |
| SonarQubeCredential | baseUrl (+ token) | — |
| GitHubCredential | token (unchanged) | — |

Not encrypted, on purpose: ids, dates, statuses, plan fields, Paddle and
store ids (needed for webhook lookups, not personal), `DeviceToken.token`
(looked up by value on unregister, and not personal data), and the
already-hashed tokens/codes.

`StudentClaim` email hashes move from plain SHA-256 to the keyed hash; the
backfill converts existing claims using the stored university emails.

## Admin search

Both admin lists now take an exact account email (case-insensitive). The
students review list holds document claims, which have no university email,
so there is nothing else to match. Name search and partial matches are
removed (they need plaintext in the database). The website search box placeholder says
"Exact email".

## Passwords and tokens

- bcrypt cost 10 → 12 (`User.BCRYPT_COST`). After a correct password, a hash
  made at a lower cost is replaced (`user.needsRehash()`), so users move over
  without noticing. The AUD-55 dummy hash uses the same constant.
- `jwt.sign`/`jwt.verify` pin `HS256`.

## Migration (`npm run encrypt-credentials`)

1. Writes `backups/pii-<timestamp>.enc` (mode 600, in `.gitignore`): every
   affected collection as Extended JSON, encrypted as one value with the
   current key. A backup is as sensitive as the database, so it is never
   plaintext on disk.
2. For every target: encrypts plain values, re-encrypts old key ids, fills
   missing hash fields.
3. Converts student email claims to the keyed hash.
4. Drops the old `email_1` unique index (meaningless on ciphertext; the
   unique index is now on `emailHash`).

`--dry-run` counts only and writes nothing (no backup either). Re-running
changes nothing. `--restore backups/pii-<timestamp>.enc` replaces those
collections' documents with the backup's.

Until the migration has run, users without an `emailHash` can't sign in, so
it runs as part of each deploy (`docs/deployment.md`), and the server logs
`pii.migration_pending` with a count while any remain.
