import "server-only";

import { z } from "zod";

import type { Result } from "@/domain/result";
import type { AdminStudent } from "@/domain/student";

import { callBackend, callBackendBytes } from "./backend-client";

/*
 * Phase 21: the super admin's review calls (docs/api-reference.md
 * `/api/admin/students`). The role is checked by the backend on every call:
 * anyone else gets its plain 404, which comes back here as a `notFound`
 * failure and is shown as a 404 page, so the pages never reveal that an
 * admin area exists.
 */

const item = z.object({
  id: z.string(),
  userId: z.string(),
  accountEmail: z.string().nullable(),
  method: z.enum(["email", "document"]),
  status: z.enum(["pending", "approved", "rejected", "expired"]),
  fullName: z.string().nullable(),
  universityEmail: z.string().nullable(),
  submittedAt: z.string(),
  reviewedAt: z.string().nullable(),
  approvedAt: z.string().nullable(),
  expiresAt: z.string().nullable(),
  rejectionReason: z.string().nullable(),
  documentMime: z.string().nullable(),
  documentSize: z.number().nullable(),
  hasDocument: z.boolean(),
  documentDeleted: z.boolean(),
  documentDeleteAt: z.string().nullable(),
});

const list = z.object({ items: z.array(item) });

export type AdminStatusFilter = "pending" | "approved" | "rejected" | "expired" | "all";

export async function listStudents(
  accessToken: string,
  { status, q }: { status: AdminStatusFilter; q: string },
): Promise<Result<AdminStudent[]>> {
  const query = new URLSearchParams({ status });
  if (q) query.set("q", q);
  const result = await callBackend(
    { path: `/api/admin/students?${query.toString()}`, accessToken },
    list,
  );
  return result.ok ? { ok: true, value: result.value.items } : result;
}

const OBJECT_ID = /^[a-f0-9]{24}$/i;

/** Ids are built into a path, so only the backend's own id shape is allowed. */
export const isStudentId = (value: string): boolean => OBJECT_ID.test(value);

export function getStudentApplication(
  accessToken: string,
  id: string,
): Promise<Result<AdminStudent>> {
  return callBackend({ path: `/api/admin/students/${id}`, accessToken }, item);
}

export function approveStudent(accessToken: string, id: string): Promise<Result<AdminStudent>> {
  return callBackend(
    { method: "POST", path: `/api/admin/students/${id}/approve`, accessToken, explain: true },
    item,
  );
}

export function rejectStudent(
  accessToken: string,
  id: string,
  reason: string,
): Promise<Result<AdminStudent>> {
  return callBackend(
    {
      method: "POST",
      path: `/api/admin/students/${id}/reject`,
      body: { reason },
      accessToken,
      explain: true,
    },
    item,
  );
}

/** The document, for the route that streams it to the admin page. */
export function fetchStudentDocument(accessToken: string, id: string) {
  return callBackendBytes({ path: `/api/admin/students/${id}/document`, accessToken });
}
