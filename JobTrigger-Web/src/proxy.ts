import { NextResponse, type NextRequest } from "next/server";

import { contentSecurityPolicy, createNonce, isNoStorePath } from "./security-headers";

/**
 * Sets the per-request CSP nonce (and `no-store` on portal paths). Headers
 * only: the proxy is skipped for prefetches and assets, so it must never be
 * the place an access check lives — server actions check the session
 * themselves (P15-13, P15-15).
 */
export function proxy(request: NextRequest) {
  const nonce = createNonce();
  const csp = contentSecurityPolicy(nonce, process.env.NODE_ENV === "development");

  // Next.js reads the nonce from the request's CSP header while rendering
  // and stamps it on its own scripts and styles.
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("Content-Security-Policy", csp);

  const response = NextResponse.next({ request: { headers: requestHeaders } });
  response.headers.set("Content-Security-Policy", csp);
  if (isNoStorePath(request.nextUrl.pathname)) {
    response.headers.set("Cache-Control", "no-store");
  }
  return response;
}

export const config = {
  matcher: [
    {
      // Pages only: not build assets, the image optimiser or metadata files.
      source: "/((?!_next/static|_next/image|icon.png|apple-icon.png|favicon.ico).*)",
      missing: [
        { type: "header", key: "next-router-prefetch" },
        { type: "header", key: "purpose", value: "prefetch" },
      ],
    },
  ],
};
