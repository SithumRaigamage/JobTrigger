import "server-only";

import { fail, type Result } from "@/domain/result";

import { refresh } from "./auth-api";
import { isSignedIn, setTokens, type Session } from "./session";

/**
 * Runs [call] with the session's access token. On a 401 it refreshes once,
 * saves the new pair and replays the call — the app's interceptor
 * behaviour (docs/api-reference.md `/api/auth/refresh`):
 *
 * - refresh 401 (expired, revoked): the session ends, AuthFailure;
 * - any other refresh failure (network, 5xx, 429): the session is kept and
 *   that failure returned (NFR-SEC-07), so a backend blip doesn't sign
 *   anyone out.
 *
 * Only for server actions and route handlers, which can write cookies.
 * Server components read the session as-is; the proxy keeps it fresh
 * (src/session-upkeep.ts).
 */
export async function authed<T>(
  session: Session,
  call: (accessToken: string) => Promise<Result<T>>,
): Promise<Result<T>> {
  if (!isSignedIn(session)) return fail({ kind: "auth" });

  const first = await call(session.accessToken);
  if (first.ok || first.failure.kind !== "auth") return first;

  const renewed = await refresh(session.refreshToken);
  if (!renewed.ok) {
    if (renewed.failure.kind === "auth") session.destroy();
    return renewed.failure.kind === "auth" ? first : fail(renewed.failure);
  }
  setTokens(session, renewed.value);
  await session.save();
  return call(renewed.value.token);
}
