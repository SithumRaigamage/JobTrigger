/*
 * Phase 21: the student plan as the website sees it (GET /api/student and
 * the admin routes, docs/api-reference.md), and the checks a student
 * document passes in the browser before it is sent. The backend repeats
 * every check; these only save a slow upload.
 */

export type StudentStatus = "none" | "pending" | "approved" | "rejected" | "expired";
export type StudentMethod = "email" | "document";

export type StudentApplication = {
  status: StudentStatus;
  method: StudentMethod | null;
  universityEmail: string | null;
  rejectionReason: string | null;
  /** ISO date-times. */
  approvedAt: string | null;
  expiresAt: string | null;
};

/**
 * [application] with the date applied: an approved year past its end reads
 * as expired even before the backend's daily job marks it so.
 */
export function studentAt(application: StudentApplication, now: Date): StudentApplication {
  return application.status === "approved" &&
    application.expiresAt !== null &&
    new Date(application.expiresAt).getTime() <= now.getTime()
    ? { ...application, status: "expired" }
    : application;
}

export const STUDENT_MAX_BYTES = 5 * 1024 * 1024;
export const STUDENT_EXTENSIONS = ["jpg", "jpeg", "png", "pdf"] as const;
/** For the file input's `accept`. */
export const STUDENT_ACCEPT = ".jpg,.jpeg,.png,.pdf,image/jpeg,image/png,application/pdf";

export const TOO_LARGE = "File too large, max 5 MB";
export const WRONG_TYPE = "Only JPG, PNG or PDF files are accepted";

export type DocumentProblem = "empty" | "tooLarge" | "wrongType";

export function documentProblemMessage(problem: DocumentProblem): string {
  switch (problem) {
    case "empty":
      return "That file is empty. Choose another.";
    case "tooLarge":
      return TOO_LARGE;
    case "wrongType":
      return WRONG_TYPE;
  }
}

/** The cheap check, from the name and size alone (before reading the file). */
export function checkDocumentMeta(name: string, size: number): DocumentProblem | null {
  if (size <= 0) return "empty";
  if (size > STUDENT_MAX_BYTES) return "tooLarge";
  const dot = name.lastIndexOf(".");
  const extension = dot < 0 ? "" : name.slice(dot + 1).toLowerCase();
  return (STUDENT_EXTENSIONS as readonly string[]).includes(extension) ? null : "wrongType";
}

const SIGNATURES: readonly (readonly number[])[] = [
  [0xff, 0xd8, 0xff],
  [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a],
  [0x25, 0x50, 0x44, 0x46, 0x2d],
];

/** True when [bytes] start like a JPG, PNG or PDF; the name can lie. */
export function looksLikeStudentDocument(bytes: Uint8Array): boolean {
  return SIGNATURES.some(
    (signature) =>
      bytes.length > signature.length && signature.every((value, index) => bytes[index] === value),
  );
}

/** The whole check on a chosen file: meta first, then its first bytes. */
export async function checkDocumentFile(file: File): Promise<DocumentProblem | null> {
  const meta = checkDocumentMeta(file.name, file.size);
  if (meta) return meta;
  const head = new Uint8Array(await file.slice(0, 16).arrayBuffer());
  return looksLikeStudentDocument(head) ? null : "wrongType";
}

export const MIN_NAME_LENGTH = 2;
export const MAX_NAME_LENGTH = 100;

/** The name as sent: trimmed, inner whitespace collapsed. */
export const tidyName = (raw: string): string => raw.trim().replace(/\s+/g, " ");

export type StudentStep =
  | { step: "email" }
  | { step: "code"; email: string }
  | { step: "document"; domainNotListed: boolean };

/** One row of the admin queue / detail (never contains the file). */
export type AdminStudent = {
  id: string;
  userId: string;
  accountEmail: string | null;
  method: StudentMethod;
  status: Exclude<StudentStatus, "none">;
  fullName: string | null;
  universityEmail: string | null;
  submittedAt: string;
  reviewedAt: string | null;
  approvedAt: string | null;
  expiresAt: string | null;
  rejectionReason: string | null;
  documentMime: string | null;
  documentSize: number | null;
  hasDocument: boolean;
  documentDeleted: boolean;
  documentDeleteAt: string | null;
};
