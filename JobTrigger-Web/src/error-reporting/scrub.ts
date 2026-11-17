/*
 * The scrubber every crash event passes through before it is sent or
 * written anywhere (E3, PE-22). Mirrors
 * JobTrigger-Backend/lib/errorReporting/scrub.js; the rules are in
 * docs/error-reporting.md.
 *
 * `scrubEvent` returns a scrubbed copy, or null (drop the event) when it
 * cannot be sure the copy is clean. It never returns the original.
 */

import {
  BASIC_HEADER,
  BEARER_HEADER,
  CREDENTIAL_KEYS,
  MONGODB_URI,
  PLACEHOLDER_PASSWORD,
  TOKEN_SHAPE,
  TOKEN_VALUE,
  normaliseKey,
} from "./credential-shapes";

export const REDACTED = "[redacted]";

const SENSITIVE_HEADERS = new Set([
  "authorization",
  "x-auth-token",
  "cookie",
  "set-cookie",
  "private-token",
  "proxy-authorization",
]);

/** True for a header or field name that must never leave the process. */
export function isSensitiveName(name: string): boolean {
  const lower = name.toLowerCase();
  if (SENSITIVE_HEADERS.has(lower)) return true;
  if (/token|secret|key|password|passwd|credential/.test(lower)) return true;
  return CREDENTIAL_KEYS.has(normaliseKey(lower));
}

const URL_IN_TEXT =
  /\b([a-z][a-z0-9+.-]*:\/\/)([^\s/?#@"'<>]*@)?([^\s?#"'<>]*)(\?[^\s#"'<>]*)?(#[^\s"'<>]*)?/gi;
const NAMED_VALUE = /(["']?)([A-Za-z_][\w.-]*)\1(\s*[:=]\s*)(["']?)([^"'\s,&;}]+)\4/g;
const AUTH_SCHEME = /\b(Basic|Bearer)\s+[A-Za-z0-9+/._~=-]{8,}/gi;

/** [text] with every credential shape and URL secret removed. */
export function scrubString(text: string): string {
  return text
    .replace(URL_IN_TEXT, (_m, scheme: string, _user, rest: string) => `${scheme}${rest}`)
    .replace(AUTH_SCHEME, (_m, scheme: string) => `${scheme} ${REDACTED}`)
    .replace(
      NAMED_VALUE,
      (match, q1: string, name: string, sep: string, q2: string, value: string) =>
        isSensitiveName(name) && value !== REDACTED
          ? `${q1}${name}${q1}${sep}${q2}${REDACTED}${q2}`
          : match,
    )
    .replace(new RegExp(TOKEN_SHAPE.source, "g"), REDACTED);
}

/** A URL without credentials, query or fragment. */
export function scrubUrl(url: string): string {
  return scrubString(url.replace(/[?#].*$/, ""));
}

export function scrubHeaders(
  headers: Record<string, unknown> | undefined,
): Record<string, unknown> {
  const kept: Record<string, unknown> = {};
  for (const [name, value] of Object.entries(headers ?? {})) {
    if (isSensitiveName(name)) continue;
    kept[name] = typeof value === "string" ? scrubString(value) : value;
  }
  return kept;
}

/** Deep copy of [value] with every string scrubbed and sensitive keys redacted. */
function scrubValue(value: unknown, depth = 0): unknown {
  if (typeof value === "string") return scrubString(value);
  if (value === null || typeof value !== "object") return value;
  if (depth > 12) return REDACTED;
  if (Array.isArray(value)) return value.map((item) => scrubValue(item, depth + 1));
  const copy: Record<string, unknown> = {};
  for (const [key, item] of Object.entries(value)) {
    copy[key] = isSensitiveName(key) ? REDACTED : scrubValue(item, depth + 1);
  }
  return copy;
}

/** True when [text] still holds something the repository guard would flag. */
function hasResidue(text: string): boolean {
  for (const source of [TOKEN_SHAPE, BASIC_HEADER, BEARER_HEADER, MONGODB_URI]) {
    const re = new RegExp(source.source, "g");
    let match: RegExpExecArray | null;
    while ((match = re.exec(text)) !== null) {
      const captured = match[1] ?? "";
      if (source === TOKEN_SHAPE) return true;
      if (source === MONGODB_URI) {
        if (!PLACEHOLDER_PASSWORD.test(captured) && captured !== REDACTED) return true;
      } else if (captured !== REDACTED && TOKEN_VALUE.test(captured)) {
        return true;
      }
    }
  }
  return false;
}

type EventLike = {
  request?: { method?: string; url?: string; headers?: Record<string, unknown> };
  user?: { id?: string | number };
  [key: string]: unknown;
};

/** Scrub [event]. Returns the clean copy, or null when it must be dropped. */
export function scrubEvent<T extends object>(event: T): T | null {
  try {
    const source = event as EventLike;
    const clean = scrubValue(event) as EventLike;

    delete clean.server_name;
    delete clean.breadcrumbs;
    if (clean.request) {
      const method = source.request?.method;
      const url = source.request?.url;
      clean.request = {
        ...(method ? { method } : {}),
        ...(url ? { url: scrubUrl(url) } : {}),
        headers: scrubHeaders(source.request?.headers),
      };
    }
    if (clean.user) {
      if (source.user?.id) clean.user = { id: String(source.user.id) };
      else delete clean.user;
    }

    if (hasResidue(JSON.stringify(clean))) return null;
    return clean as T;
  } catch {
    return null;
  }
}
