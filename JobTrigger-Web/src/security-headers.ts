/*
 * Security headers (WEB-B1–B3, docs/web-architecture.md "Security
 * headers"). Pure functions shared by next.config.ts (static headers on
 * every response, assets included) and proxy.ts (per-request CSP). Not in
 * src/server/ because next.config.ts can't import `server-only`; nothing
 * here is secret.
 */

type Header = { key: string; value: string };

/**
 * P20-83: what Paddle.js needs, for the billing page only. Only the
 * environment in use is allowed, so a production page never trusts the
 * sandbox hosts. Nothing here loosens style-src or adds 'unsafe-inline';
 * the script is loaded with the page's nonce and 'strict-dynamic' lets it
 * load what it needs.
 */
export type PaddleCsp = { environment: "sandbox" | "production" };

const paddleHosts = {
  production: {
    connect: "https://checkout-service.paddle.com",
    frame: "https://buy.paddle.com",
  },
  sandbox: {
    connect: "https://sandbox-checkout-service.paddle.com",
    frame: "https://sandbox-buy.paddle.com",
  },
} as const;

/** Paths whose responses must never be cached (US-WEB-11: `no-store`). */
export const NO_STORE_PATH_PREFIXES = [
  "/sign-in",
  "/sign-up",
  "/forgot-password",
  "/reset-password",
  "/servers",
  "/account",
  "/admin",
] as const;

export function isNoStorePath(pathname: string): boolean {
  return NO_STORE_PATH_PREFIXES.some(
    (prefix) => pathname === prefix || pathname.startsWith(`${prefix}/`),
  );
}

/** Portal pages that need a signed-in user (sign-in and sign-up don't). */
export const PROTECTED_PATH_PREFIXES = ["/servers", "/account", "/admin"] as const;

export function isProtectedPath(pathname: string): boolean {
  return PROTECTED_PATH_PREFIXES.some(
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
export function contentSecurityPolicy(
  nonce: string,
  isDev: boolean,
  /** E3: where crash reports are sent (the DSN's origin), if reporting is on. */
  reportingOrigin: string | null = null,
  /** Set on the billing page only; every other page gets the strict policy. */
  paddle: PaddleCsp | null = null,
): string {
  const hosts = paddle ? paddleHosts[paddle.environment] : null;
  const directives = [
    "default-src 'self'",
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'${hosts ? " https://cdn.paddle.com" : ""}${isDev ? " 'unsafe-eval'" : ""}`,
    `style-src 'self' 'nonce-${nonce}'`,
    "img-src 'self' data: blob:",
    "font-src 'self'",
    `connect-src 'self'${reportingOrigin ? ` ${reportingOrigin}` : ""}${hosts ? ` ${hosts.connect}` : ""}`,
    ...(hosts ? [`frame-src ${hosts.frame}`] : []),
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
