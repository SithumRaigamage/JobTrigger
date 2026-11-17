import "server-only";

import { z } from "zod";

import type { Result } from "@/domain/result";
import type { StudentApplication } from "@/domain/student";

import { callBackend } from "./backend-client";
import { ok } from "@/domain/result";

/*
 * Phase 21: the student plan's backend calls (docs/api-reference.md
 * `/api/student`). All opt in to the backend's own error sentences, so
 * "That code has expired" or "File too large, max 5 MB" reach the user as
 * the backend wrote them.
 */

const status = z.enum(["none", "pending", "approved", "rejected", "expired"]).catch("none");
const method = z.enum(["email", "document"]).nullable().catch(null);

const applicationDto = z.object({
  status,
  method: method.optional().default(null),
  universityEmail: z.string().nullable().optional().default(null),
  rejectionReason: z.string().nullable().optional().default(null),
  approvedAt: z.string().nullable().optional().default(null),
  expiresAt: z.string().nullable().optional().default(null),
});

export function getStudent(accessToken: string): Promise<Result<StudentApplication>> {
  return callBackend({ path: "/api/student", accessToken, explain: true }, applicationDto);
}

const startDto = z.object({ message: z.string().optional() });

/** Sends the 6-digit code. A domain not on the list is `code: domain_not_listed`. */
export async function startStudentEmail(
  accessToken: string,
  universityEmail: string,
): Promise<Result<null>> {
  const result = await callBackend(
    {
      method: "POST",
      path: "/api/student/email/start",
      body: { universityEmail },
      accessToken,
      explain: true,
    },
    startDto,
  );
  return result.ok ? ok(null) : result;
}

export function confirmStudentEmail(
  accessToken: string,
  code: string,
): Promise<Result<StudentApplication>> {
  return callBackend(
    {
      method: "POST",
      path: "/api/student/email/confirm",
      body: { code },
      accessToken,
      explain: true,
    },
    applicationDto,
  );
}

/** Sends the document (base64) and the name as printed on the ID. */
export function uploadStudentDocument(
  accessToken: string,
  fullName: string,
  base64: string,
): Promise<Result<StudentApplication>> {
  return callBackend(
    {
      method: "POST",
      path: "/api/student/document",
      body: { fullName, data: base64 },
      accessToken,
      explain: true,
    },
    applicationDto,
  );
}
