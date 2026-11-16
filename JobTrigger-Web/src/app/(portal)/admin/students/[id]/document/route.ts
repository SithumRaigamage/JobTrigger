import { fetchStudentDocument, isStudentId } from "@/server/admin-students-api";
import { authed } from "@/server/authed";
import { getSession, isSignedIn } from "@/server/session";

/*
 * Phase 21 (note 7): the student's document, fetched from the backend with
 * the admin's own session and passed to the admin's browser. There is no
 * public URL: without an admin session, or for anyone else, this is a plain
 * 404. Never cached, never sniffed, sandboxed, and a PDF is a download so the
 * browser's PDF viewer never runs on it.
 */

const IMAGE_TYPES = new Set(["image/jpeg", "image/png"]);

const notFoundResponse = () =>
  new Response("Not found", { status: 404, headers: { "Cache-Control": "no-store" } });

export async function GET(
  _request: Request,
  { params }: RouteContext<"/admin/students/[id]/document">,
) {
  const { id } = await params;
  if (!isStudentId(id)) return notFoundResponse();

  const session = await getSession();
  if (!isSignedIn(session)) return notFoundResponse();

  const result = await authed(session, (token) => fetchStudentDocument(token, id));
  if (!result.ok) {
    if (result.failure.kind === "explained" && result.failure.status === 410) {
      return new Response("This document was deleted.", {
        status: 410,
        headers: { "Cache-Control": "no-store" },
      });
    }
    return notFoundResponse();
  }

  const type = result.value.contentType.split(";")[0]!.trim().toLowerCase();
  const image = IMAGE_TYPES.has(type);
  return new Response(result.value.bytes, {
    headers: {
      "Content-Type": image ? type : "application/pdf",
      "Content-Disposition": image
        ? 'inline; filename="student-document"'
        : 'attachment; filename="student-document.pdf"',
      "Cache-Control": "no-store",
      "X-Content-Type-Options": "nosniff",
      "Content-Security-Policy": "default-src 'none'; sandbox",
    },
  });
}
