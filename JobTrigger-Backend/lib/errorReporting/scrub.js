/**
 * E3 / PE-20: the scrubber every crash event passes through before it is
 * sent or written to disk. The rules are in `docs/error-reporting.md`;
 * the Dart and TypeScript scrubbers mirror this file.
 *
 *   - no request or response bodies, no cookies
 *   - sensitive headers removed (Authorization, x-auth-token, Cookie,
 *     Set-Cookie, PRIVATE-TOKEN, anything with token/secret/key in its name)
 *   - query strings and `user:pass@` removed from every URL
 *   - credential shapes (Jenkins token, Basic/Bearer, MongoDB URI,
 *     key/value secrets) redacted from every string
 *   - the user is an opaque id at most, never an email or an address
 *
 * `scrubEvent` returns the scrubbed event, or null (drop it) when it cannot
 * be sure the event is clean. An unscrubbed event is never returned.
 */

'use strict';

const crypto = require('crypto');
const {
  BASIC_HEADER,
  BEARER_HEADER,
  CREDENTIAL_KEYS,
  MONGODB_URI,
  PLACEHOLDER_PASSWORD,
  TOKEN_SHAPE,
  TOKEN_VALUE,
  normaliseKey,
} = require('../../security/credentialShapes');

const REDACTED = '[redacted]';

const SENSITIVE_HEADERS = new Set([
  'authorization',
  'x-auth-token',
  'cookie',
  'set-cookie',
  'private-token',
  'proxy-authorization',
]);

/** True for a header or field name that must never leave the process. */
function isSensitiveName(name) {
  const lower = String(name).toLowerCase();
  if (SENSITIVE_HEADERS.has(lower)) return true;
  if (/token|secret|key|password|passwd|credential/.test(lower)) return true;
  return CREDENTIAL_KEYS.has(normaliseKey(lower));
}

// scheme://[userinfo@]rest[?query][#fragment] inside free text.
const URL_IN_TEXT = /\b([a-z][a-z0-9+.-]*:\/\/)([^\s/?#@"'<>]*@)?([^\s?#"'<>]*)(\?[^\s#"'<>]*)?(#[^\s"'<>]*)?/gi;
// `name=value`, `"name": "value"` where the name is sensitive.
const NAMED_VALUE = /(["']?)([A-Za-z_][\w.-]*)\1(\s*[:=]\s*)(["']?)([^"'\s,&;}]+)\4/g;
const AUTH_SCHEME = /\b(Basic|Bearer)\s+[A-Za-z0-9+/._~=-]{8,}/gi;

/** [text] with every credential shape and URL secret removed. */
function scrubString(text) {
  let out = String(text);
  out = out.replace(URL_IN_TEXT, (_m, scheme, _user, rest) => `${scheme}${rest}`);
  out = out.replace(AUTH_SCHEME, (_m, scheme) => `${scheme} ${REDACTED}`);
  out = out.replace(NAMED_VALUE, (match, q1, name, sep, q2, value) =>
    isSensitiveName(name) && value !== REDACTED ? `${q1}${name}${q1}${sep}${q2}${REDACTED}${q2}` : match,
  );
  out = out.replace(new RegExp(TOKEN_SHAPE.source, 'g'), REDACTED);
  return out;
}

/** A URL without credentials, query or fragment. */
function scrubUrl(url) {
  if (typeof url !== 'string') return url;
  return scrubString(url.replace(/[?#].*$/, ''));
}

function scrubHeaders(headers) {
  const kept = {};
  for (const [name, value] of Object.entries(headers ?? {})) {
    if (isSensitiveName(name)) continue;
    kept[name] = typeof value === 'string' ? scrubString(value) : value;
  }
  return kept;
}

/** Deep copy of [value] with every string scrubbed and sensitive keys redacted. */
function scrubValue(value, depth = 0) {
  if (typeof value === 'string') return scrubString(value);
  if (value === null || typeof value !== 'object') return value;
  if (depth > 12) return REDACTED;
  if (Array.isArray(value)) return value.map((item) => scrubValue(item, depth + 1));
  const copy = {};
  for (const [key, item] of Object.entries(value)) {
    copy[key] = isSensitiveName(key) ? REDACTED : scrubValue(item, depth + 1);
  }
  return copy;
}

/**
 * True when [text] still holds something the repository guard would flag.
 * The last line of defence: redaction should make this always false.
 */
function hasResidue(text) {
  for (const re of [TOKEN_SHAPE, BASIC_HEADER, BEARER_HEADER, MONGODB_URI]) {
    const copy = new RegExp(re.source, 'g');
    let match;
    while ((match = copy.exec(text)) !== null) {
      const captured = match[1];
      if (re === TOKEN_SHAPE) return true;
      if (re === MONGODB_URI) {
        if (!PLACEHOLDER_PASSWORD.test(captured) && captured !== REDACTED) return true;
      } else if (captured !== REDACTED && TOKEN_VALUE.test(captured)) {
        return true;
      }
    }
  }
  return false;
}

/** A short, opaque id for [accountId]: never reversible to an email. */
function hashUserId(accountId) {
  return crypto.createHash('sha256').update(String(accountId)).digest('hex').slice(0, 16);
}

/**
 * Scrub [event] (a Sentry event). Returns the clean event or null.
 */
function scrubEvent(event) {
  try {
    const clean = scrubValue(event);

    delete clean.server_name;
    delete clean.breadcrumbs;
    if (clean.request) {
      const { method } = clean.request;
      const url = scrubUrl(event.request?.url);
      clean.request = {
        ...(method ? { method } : {}),
        ...(url ? { url } : {}),
        headers: scrubHeaders(event.request?.headers),
      };
    }
    if (clean.user) {
      clean.user = event.user?.id ? { id: String(event.user.id) } : undefined;
      if (!clean.user) delete clean.user;
    }

    if (hasResidue(JSON.stringify(clean))) return null;
    return clean;
  } catch {
    return null;
  }
}

module.exports = {
  REDACTED,
  hashUserId,
  isSensitiveName,
  scrubEvent,
  scrubHeaders,
  scrubString,
  scrubUrl,
};
