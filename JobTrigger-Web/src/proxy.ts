import { NextResponse, type NextRequest } from "next/server";

import {
  contentSecurityPolicy,
  createNonce,
  isNoStorePath,
  isProtectedPath,
} from "./security-headers";
import { upkeepSession } from "./session-upkeep";

/**
 * Per-request headers, plus session upkeep on portal paths. Sets the CSP
 * nonce everywhere, and on portal paths renews the session and applies the
 * idle timeout (src/session-upkeep.ts) and sends `no-store` + `noindex`.
 *
 * Never the place an access check lives: the proxy is skipped for
 * prefetches and assets, so the portal layout and every server action check
 * the session themselves (P15-15).
 */
export async function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl;
  const portal = isNoStorePath(pathname);
  // Before the headers are copied below, so this request's render reads
  // the renewed session.
  const upkeep = portal ? await upkeepSession(request) : { cookies: [], ended: null };

  // A page visit whose session just ended goes to sign-in with the reason
  // (US-WEB-20). Server actions aren't redirected here: they check the
  // session themselves and answer accordingly.
  if (upkeep.ended && request.method === "GET" && isProtectedPath(pathname)) {
    const signIn = new URL("/sign-in", request.url);
    signIn.searchParams.set("notice", upkeep.ended);
    signIn.searchParams.set("next", pathname);
    const redirect = NextResponse.redirect(signIn);
    for (const cookie of upkeep.cookies)
      redirect.cookies.set(cookie.name, cookie.value, cookie.options);
    redirect.headers.set("Cache-Control", "no-store");
    return redirect;
  }

  const nonce = createNonce();
  const csp = contentSecurityPolicy(nonce, process.env.NODE_ENV === "development");

  // Next.js reads the nonce from the request's CSP header while rendering
  // and stamps it on its own scripts and styles.
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("Content-Security-Policy", csp);

  const response = NextResponse.next({ request: { headers: requestHeaders } });
  response.headers.set("Content-Security-Policy", csp);
  for (const cookie of upkeep.cookies) {
    response.cookies.set(cookie.name, cookie.value, cookie.options);
  }
  if (portal) {
    response.headers.set("Cache-Control", "no-store");
    // US-WEB-07: portal pages are never indexed, even if linked from outside.
    response.headers.set("X-Robots-Tag", "noindex, nofollow");
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
