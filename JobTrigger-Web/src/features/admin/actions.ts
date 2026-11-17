"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import { failureMessage } from "@/domain/app-failure";
import { authed } from "@/server/authed";
import { approveStudent, isStudentId, rejectStudent } from "@/server/admin-students-api";
import { requireSession } from "@/server/guard";

/*
 * Phase 21 (SP-51): approve or reject a student document. The backend checks
 * the super-admin role on every call; a non-admin who somehow reaches these
 * only gets its plain "not found". The id is checked for shape before it is
 * built into a path.
 */

export type ReviewState = { error?: string };

const MAX_REASON = 500;

export async function approveStudentAction(
  _previous: ReviewState,
  form: FormData,
): Promise<ReviewState> {
  const session = await requireSession();
  const id = String(form.get("id") ?? "");
  if (!isStudentId(id)) return { error: "That application couldn't be found." };

  const result = await authed(session, (token) => approveStudent(token, id));
  if (!result.ok) return { error: failureMessage(result.failure) };
  revalidatePath("/admin/students");
  redirect("/admin/students?notice=approved");
}

export async function rejectStudentAction(
  _previous: ReviewState,
  form: FormData,
): Promise<ReviewState> {
  const session = await requireSession();
  const id = String(form.get("id") ?? "");
  if (!isStudentId(id)) return { error: "That application couldn't be found." };
  const reason = String(form.get("reason") ?? "").trim();
  if (!reason) return { error: "Give a reason. The student sees it." };
  if (reason.length > MAX_REASON) {
    return { error: `Keep the reason under ${MAX_REASON} characters.` };
  }

  const result = await authed(session, (token) => rejectStudent(token, id, reason));
  if (!result.ok) return { error: failureMessage(result.failure) };
  revalidatePath("/admin/students");
  redirect("/admin/students?notice=rejected");
}
