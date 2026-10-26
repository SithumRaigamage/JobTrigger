import type { NextRequest } from "next/server";
import type { CookieJar } from "iron-session";

import { refresh } from "./server/auth-api";
import { tokenExpiresAt } from "./server/jwt";
import { getSessionFromJar, isIdle, isSignedIn, setTokens } from "./server/session";

/*
 * Session upkeep in the proxy, for portal paths (US-WEB-10, US-WEB-20).
 * Server components can't set cookies, so this is where an access token
 * about to expire is renewed and the idle timeout is applied, before the
 * page renders. It is upkeep, not access control: the portal layout and
 * every server action still check the session themselves.
 */

/** Renew when the access token has less than this left. */
const RENEW_WITHIN_MS = 60_000;

type CookieOptions = Parameters<CookieJar["write"]>[2];

export type PendingCookie = { name: string; value: string; options: CookieOptions };

/**
 * A cookie jar that writes to the incoming request (so this request's render
 * sees the new session) and records the write for the response.
 */
function requestJar(request: NextRequest, pending: PendingCookie[]): CookieJar {
  return {
    read: (name) => request.cookies.get(name)?.value,
    names: () => request.cookies.getAll().map((cookie) => cookie.name),
    write: (name, value, options) => {
      if (value) request.cookies.set(name, value);
      else request.cookies.delete(name);
      pending.push({ name, value, options });
    },
  };
}

export type Upkeep = {
  /** Cookies to set on the response. */
  cookies: PendingCookie[];
  /** Why the session ended during this request, if it did. */
  ended: "idle" | "expired" | null;
};

/**
 * Applies the idle timeout and renews the access token if needed. The
 * caller builds the response from `request.headers` afterwards, so the
 * render sees the same session.
 */
export async function upkeepSession(
  request: NextRequest,
  now: number = Date.now(),
): Promise<Upkeep> {
  const pending: PendingCookie[] = [];
  let session;
  try {
    session = await getSessionFromJar(requestJar(request, pending));
  } catch {
    // No SESSION_SECRET configured: there is no portal session to keep.
    return { cookies: pending, ended: null };
  }
  if (!isSignedIn(session)) return { cookies: pending, ended: null };

  if (isIdle(session, now)) {
    session.destroy();
    return { cookies: pending, ended: "idle" };
  }

  const expiresAt = tokenExpiresAt(session.accessToken);
  if (expiresAt !== null && expiresAt - now < RENEW_WITHIN_MS) {
    const renewed = await refresh(session.refreshToken);
    if (renewed.ok) {
      setTokens(session, renewed.value, now);
    } else if (renewed.failure.kind === "auth") {
      // Expired or revoked (e.g. "sign out of all devices" elsewhere).
      session.destroy();
      return { cookies: pending, ended: "expired" };
    }
    // Any other failure keeps the session (NFR-SEC-07).
  }

  session.lastActivity = now;
  await session.save();
  return { cookies: pending, ended: null };
}
