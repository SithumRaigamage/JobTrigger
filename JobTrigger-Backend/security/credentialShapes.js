/**
 * The shapes of credential material, in one place (PE-00 / E3).
 *
 * Two users read these: the repository guard (`secretMaterialScan.js`),
 * which looks for them in tracked files, and the crash-report scrubber
 * (`lib/errorReporting/scrub.js`), which looks for them in an event before
 * it leaves the process. The Dart and TypeScript scrubbers mirror them; the
 * list is in `docs/error-reporting.md`.
 *
 * The regular expressions are global, so a caller that uses `exec` must
 * reset `lastIndex` first (or build its own copy with `new RegExp(re)`).
 */

'use strict';

// A Jenkins credential value: 32 hex characters (legacy) or the modern
// 11-prefixed form -- the same shape `looksLikeJenkinsApiToken` uses in
// the app. The lookarounds keep a 40-character git SHA from matching:
// only a value that is *not* part of a longer hex string is a token.
const TOKEN_SHAPE = /(?<![0-9a-f])((?:11)?[0-9a-f]{32})(?![0-9a-f])/g;

// The same shape, anchored, for a whole value.
const TOKEN_VALUE = /^(11)?[0-9a-f]{32}$/;

// Keys whose value is a credential. Compared after normalising the key
// (lower-cased, non-letters removed), so `apiToken`, `api_token` and
// `API-TOKEN` are all the same key.
const CREDENTIAL_KEYS = new Set([
  'password',
  'passwd',
  'pass',
  'token',
  'apitoken',
  'accesstoken',
  'authtoken',
  'bearertoken',
  'jenkinstoken',
  'personalaccesstoken',
  'pat',
  'secret',
  'paramtoken',
  'credential',
  'credentials',
  'auth',
  'authorization',
  'apikey',
  'apisecret',
  'privatekey',
]);

// `key: "value"`, `key = "value"`, `'key': "value"`.
const KEY_VALUE = /["']?([A-Za-z_][A-Za-z0-9_.-]*)["']?\s*[:=]\s*["']([^"'\n]+)["']/g;

// `Authorization: Basic <base64>`.
const BASIC_HEADER = /Basic\s+([A-Za-z0-9+/]{12,}={0,2})/g;

// `Authorization: Bearer <token>`.
const BEARER_HEADER = /Bearer\s+([A-Za-z0-9._-]{16,})/g;

// `mongodb://<user>:<password>@<host>` or `mongodb+srv://…`: the password.
const MONGODB_URI = /mongodb(?:\+srv)?:\/\/[^:@/\s'"`]+:([^@/\s'"`]+)@/g;

// A password that is obviously a placeholder: `<password>`, `${DB_PASS}`,
// `***`. Docs and tests write these; anything else is treated as real.
const PLACEHOLDER_PASSWORD = /^(<[^<>]*>|\$\{[^{}]*\}|\*+)$/;

function normaliseKey(key) {
  return key.toLowerCase().replace(/[^a-z]/g, '');
}

module.exports = {
  BASIC_HEADER,
  BEARER_HEADER,
  CREDENTIAL_KEYS,
  KEY_VALUE,
  MONGODB_URI,
  PLACEHOLDER_PASSWORD,
  TOKEN_SHAPE,
  TOKEN_VALUE,
  normaliseKey,
};
