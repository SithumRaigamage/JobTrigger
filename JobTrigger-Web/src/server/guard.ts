import "server-only";

import { headers } from "next/headers";
import { redirect } from "next/navigation";

import { getSession, isSignedIn, type Session } from "./session";

/**
 * The signed-in session, or a redirect to sign-in. Every portal page (via
 * the portal layout) and every server action calls this: the proxy only
 * keeps sessions fresh, it never grants access (docs/web-architecture.md §5).
 */
export async function requireSession(): Promise<Session & { accessToken: string; email: string }> {
  const session = await getSession();
  if (isSignedIn(session)) return session as Session & { accessToken: string; email: string };

  const pathname = (await headers()).get("x-pathname");
  redirect(pathname ? `/sign-in?next=${encodeURIComponent(pathname)}` : "/sign-in");
}
