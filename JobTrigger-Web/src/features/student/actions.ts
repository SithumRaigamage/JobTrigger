"use server";

import { revalidatePath } from "next/cache";

import { failureMessage } from "@/domain/app-failure";
import { isValidEmail } from "@/domain/auth-validation";
import {
  MAX_NAME_LENGTH,
  MIN_NAME_LENGTH,
  checkDocumentMeta,
  documentProblemMessage,
  looksLikeStudentDocument,
  tidyName,
  type StudentStep,
} from "@/domain/student";
import { authed } from "@/server/authed";
import { requireSession } from "@/server/guard";
import {
  confirmStudentEmail,
  startStudentEmail,
  uploadStudentDocument,
} from "@/server/student-api";

/*
 * Phase 21 (SP-50): the student verification on the Account page. Every
 * action checks the session itself and only forwards to the backend, which
 * decides (the code, the 5 MB and type limits, one grant per person). The
 * checks here repeat the backend's so a wrong file never travels.
 */

export type StudentActionState = {
  error?: string;
  /** Where the flow goes next, when this call moved it. */
  step?: StudentStep;
  /** Approved, or sent for review: the page now shows the new state. */
  done?: boolean;
};

const CODE = /^\d{6}$/;
const text = (form: FormData, key: string) => {
  const value = form.get(key);
  return typeof value === "string" ? value : "";
};

async function startFor(email: string): Promise<StudentActionState> {
  const session = await requireSession();
  if (!isValidEmail(email)) return { error: "Enter your university email address." };
  const result = await authed(session, (token) => startStudentEmail(token, email));
  if (result.ok) return { step: { step: "code", email } };
  if (result.failure.kind === "explained" && result.failure.code === "domain_not_listed") {
    return { step: { step: "document", domainNotListed: true } };
  }
  return { error: failureMessage(result.failure) };
}

/** Sends the code to the university email, or moves to the document step. */
export async function startStudentEmailAction(
  _previous: StudentActionState,
  form: FormData,
): Promise<StudentActionState> {
  return startFor(text(form, "email").trim());
}

/** A new code for the email already entered. */
export async function resendStudentCodeAction(email: string): Promise<StudentActionState> {
  return startFor(email.trim());
}

/** The right code grants the student year at once. */
export async function confirmStudentCodeAction(
  _previous: StudentActionState,
  form: FormData,
): Promise<StudentActionState> {
  const session = await requireSession();
  const code = text(form, "code").trim();
  if (!CODE.test(code)) return { error: "Enter the 6-digit code." };
  const result = await authed(session, (token) => confirmStudentEmail(token, code));
  if (!result.ok) return { error: failureMessage(result.failure) };
  revalidatePath("/account");
  return { done: true };
}

/** A student ID or enrolment letter, for review by hand. */
export async function uploadStudentDocumentAction(
  _previous: StudentActionState,
  form: FormData,
): Promise<StudentActionState> {
  const session = await requireSession();
  const fullName = tidyName(text(form, "fullName"));
  if (fullName.length < MIN_NAME_LENGTH || fullName.length > MAX_NAME_LENGTH) {
    return { error: "Enter your full name as it appears on your student ID." };
  }
  const file = form.get("file");
  if (!(file instanceof File)) return { error: "Choose a file to upload." };
  const meta = checkDocumentMeta(file.name, file.size);
  if (meta) return { error: documentProblemMessage(meta) };

  const bytes = new Uint8Array(await file.arrayBuffer());
  if (!looksLikeStudentDocument(bytes)) return { error: documentProblemMessage("wrongType") };

  const base64 = Buffer.from(bytes).toString("base64");
  const result = await authed(session, (token) => uploadStudentDocument(token, fullName, base64));
  if (!result.ok) return { error: failureMessage(result.failure) };
  revalidatePath("/account");
  return { done: true };
}
