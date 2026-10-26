import "server-only";

import {
  getIronSession,
  type CookieJar,
  type IronSession,
  type SessionOptions,
} from "iron-session";
import { cookies } from "next/headers";

import { getConfig } from "./config";

/*
 * The portal session (docs/web-architecture.md §2, §5): the JobTrigger
 * access and refresh tokens in one encrypted, HttpOnly, SameSite=Lax
 * cookie. Browser JavaScript can never read it.
 */

export type SessionData = {
  accessToken: string;
  refreshToken: string;
  email: string;
  /** ms since the epoch of the last portal request (idle timeout). */
  lastActivity: number;
};

export type Session = IronSession<SessionData>;

export const SESSION_COOKIE = "jt_session";

/** US-WEB-20: signed out after 30 minutes without activity. */
export const IDLE_TIMEOUT_MS = 30 * 60_000;

/** The refresh token lasts 30 days (AUD-26); the cookie no longer. */
const SESSION_TTL_S = 30 * 24 * 60 * 60;

export function sessionOptions(): SessionOptions {
  return {
    password: getConfig().sessionSecret,
    cookieName: SESSION_COOKIE,
    ttl: SESSION_TTL_S,
    cookieOptions: {
      httpOnly: true,
      // Browsers treat http://localhost as secure, so this holds locally too.
      secure: true,
      sameSite: "lax",
      path: "/",
    },
    onUnsealError: (reason) => {
      if (reason !== "expired") console.warn(`session: cookie rejected (${reason})`);
    },
  };
}

/**
 * The session from the request cookies. In a server component it is
 * read-only (Next can't set cookies while rendering); server actions and
 * route handlers may save or destroy it.
 */
export async function getSession(): Promise<Session> {
  return getIronSession<SessionData>(await cookies(), sessionOptions());
}

/** The session through a custom cookie jar (the proxy). */
export async function getSessionFromJar(jar: CookieJar): Promise<Session> {
  return getIronSession<SessionData>(jar, sessionOptions());
}

/** Whether [session] holds a signed-in user. */
export function isSignedIn(
  session: Partial<SessionData>,
): session is Partial<SessionData> & Pick<SessionData, "accessToken" | "refreshToken" | "email"> {
  return Boolean(session.accessToken && session.refreshToken && session.email);
}

/** Whether [session] has been idle past the timeout at [now]. */
export function isIdle(session: Partial<SessionData>, now: number): boolean {
  return now - (session.lastActivity ?? 0) > IDLE_TIMEOUT_MS;
}

/** Stores a fresh token pair (sign-in, refresh, password change). */
export function setTokens(
  session: Session,
  tokens: { token: string; refreshToken: string; email: string },
  now: number = Date.now(),
) {
  session.accessToken = tokens.token;
  session.refreshToken = tokens.refreshToken;
  session.email = tokens.email;
  session.lastActivity = now;
}
