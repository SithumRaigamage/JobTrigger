import { authed } from "@/server/authed";
import { getSession, isSignedIn } from "@/server/session";
import { fetchSupportScreenshot, isTicketId } from "@/server/support-api";

/*
 * US-SUP-06/07: one decrypted screenshot, fetched from the backend with the
 * owner's own session and passed only to that owner's browser. Without an
 * admin session, or for anyone else, the backend's plain 404 becomes ours.
 * No path or token is exposed, and the bytes are never cached or sniffed.
 */

const IMAGE_TYPES = new Set(["image/jpeg", "image/png"]);

const notFoundResponse = () =>
  new Response("Not found", { status: 404, headers: { "Cache-Control": "no-store" } });

export async function GET(
  _request: Request,
  { params }: RouteContext<"/admin/support/[id]/screenshots/[index]">,
) {
  const { id, index: rawIndex } = await params;
  if (!isTicketId(id) || !/^\d+$/.test(rawIndex)) return notFoundResponse();

  const session = await getSession();
  if (!isSignedIn(session)) return notFoundResponse();

  const result = await authed(session, (token) =>
    fetchSupportScreenshot(token, id, Number(rawIndex)),
  );
  if (!result.ok) return notFoundResponse();

  const type = result.value.contentType.split(";")[0]!.trim().toLowerCase();
  if (!IMAGE_TYPES.has(type)) return notFoundResponse();

  return new Response(result.value.bytes, {
    headers: {
      "Content-Type": type,
      "Cache-Control": "no-store",
      "X-Content-Type-Options": "nosniff",
      "Content-Security-Policy": "default-src 'none'; sandbox",
    },
  });
}
