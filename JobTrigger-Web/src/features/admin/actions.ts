"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import { failureMessage } from "@/domain/app-failure";
import { SUPPORT_STATUSES, type SupportStatus } from "@/domain/support";
import { authed } from "@/server/authed";
import { approveStudent, isStudentId, rejectStudent } from "@/server/admin-students-api";
import { requireSession } from "@/server/guard";
import { isTicketId, updateSupportStatus } from "@/server/support-api";

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

export type SupportStatusState = { error?: string; notice?: string };

/** US-SUP-07: triage a support ticket from its detail page. */
export async function updateSupportStatusAction(
  _previous: SupportStatusState,
  form: FormData,
): Promise<SupportStatusState> {
  const session = await requireSession();
  const id = String(form.get("id") ?? "");
  const status = String(form.get("status") ?? "");
  if (!isTicketId(id)) return { error: "That report couldn't be found." };
  if (!(SUPPORT_STATUSES as readonly string[]).includes(status)) {
    return { error: "Choose a known status." };
  }
  const result = await authed(session, (token) =>
    updateSupportStatus(token, id, status as SupportStatus),
  );
  if (!result.ok) return { error: failureMessage(result.failure) };
  revalidatePath("/admin/support");
  revalidatePath(`/admin/support/${id}`);
  return { notice: `Marked ${status}.` };
}
