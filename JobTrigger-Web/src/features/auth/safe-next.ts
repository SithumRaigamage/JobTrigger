import { isProtectedPath } from "@/security-headers";

/**
 * Where to go after signing in: the `next` parameter only when it's a
 * portal path on this site, so it can't be used as an open redirect.
 */
export function safeNext(next: string | null | undefined, fallback = "/servers"): string {
  if (!next || !next.startsWith("/") || next.startsWith("//") || next.includes("\\")) {
    return fallback;
  }
  return isProtectedPath(next.split(/[?#]/)[0]) ? next : fallback;
}
