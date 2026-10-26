/*
 * Security headers (WEB-B1–B3, docs/web-architecture.md "Security
 * headers"). Pure functions shared by next.config.ts (static headers on
 * every response, assets included) and proxy.ts (per-request CSP). Not in
 * src/server/ because next.config.ts can't import `server-only`; nothing
 * here is secret.
 */

type Header = { key: string; value: string };

/** Paths whose responses must never be cached (US-WEB-11: `no-store`). */
export const NO_STORE_PATH_PREFIXES = ["/sign-in", "/sign-up", "/servers", "/account"] as const;

export function isNoStorePath(pathname: string): boolean {
  return NO_STORE_PATH_PREFIXES.some(
    (prefix) => pathname === prefix || pathname.startsWith(`${prefix}/`),
  );
}

/** A fresh, unguessable nonce for one response's CSP. */
export function createNonce(): string {
  return btoa(crypto.randomUUID());
}

/**
 * The page CSP. Nonce-based with 'strict-dynamic', so no inline script or
 * style runs unless Next.js rendered it for this request. 'unsafe-eval'
 * only in `next dev`, where React needs it for server error stacks.
 */
export function contentSecurityPolicy(nonce: string, isDev: boolean): string {
  const directives = [
    "default-src 'self'",
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'${isDev ? " 'unsafe-eval'" : ""}`,
    `style-src 'self' 'nonce-${nonce}'`,
    "img-src 'self' data: blob:",
    "font-src 'self'",
    "connect-src 'self'",
    "object-src 'none'",
    "base-uri 'self'",
    "form-action 'self'",
    "frame-ancestors 'none'",
    ...(isDev ? [] : ["upgrade-insecure-requests"]),
  ];
  return directives.join("; ");
}

/** Headers that don't vary per request; set on every path. */
export function staticSecurityHeaders(): Header[] {
  return [
    // Two years. No `preload`: joining the browser preload list is a
    // separate, hard-to-undo decision about the domain.
    { key: "Strict-Transport-Security", value: "max-age=63072000; includeSubDomains" },
    { key: "X-Content-Type-Options", value: "nosniff" },
    { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
    // For browsers that predate CSP frame-ancestors.
    { key: "X-Frame-Options", value: "DENY" },
    {
      key: "Permissions-Policy",
      value: "camera=(), microphone=(), geolocation=(), payment=(), usb=()",
    },
    { key: "Cross-Origin-Opener-Policy", value: "same-origin" },
  ];
}
