import "server-only";

/**
 * When a JWT expires, in ms since the epoch, read from its payload without
 * verifying it. Only for timing a refresh — the backend verifies every
 * token it receives. Null when the token isn't a readable JWT.
 */
export function tokenExpiresAt(token: string): number | null {
  const payload = token.split(".")[1];
  if (!payload) return null;
  try {
    const { exp } = JSON.parse(Buffer.from(payload, "base64url").toString("utf8")) as {
      exp?: unknown;
    };
    return typeof exp === "number" ? exp * 1000 : null;
  } catch {
    return null;
  }
}
