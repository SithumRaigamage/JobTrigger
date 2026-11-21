"use server";

import { z } from "zod";

import { failureMessage } from "@/domain/app-failure";
import { authed } from "@/server/authed";
import { requireSession } from "@/server/guard";
import { createToolRequest } from "@/server/support-api";

export type RequestToolState = {
  error?: string;
  subject?: string;
  message?: string;
  sent?: { ticketId: string; replyEmail: string };
};

// The backend's limits and the app's copy (US-SUP-01).
const requestForm = z.object({
  subject: z
    .string()
    .trim()
    .min(1, "Add a short subject.")
    .max(120, "Keep the subject under 120 characters."),
  message: z
    .string()
    .trim()
    .min(1, "Describe the issue or request.")
    .max(4000, "Keep the message under 4000 characters."),
});

/** Files a "Tool request" Support ticket (US-WEB-04). */
export async function requestToolAction(
  _previous: RequestToolState,
  form: FormData,
): Promise<RequestToolState> {
  const session = await requireSession();
  const typed = {
    subject: String(form.get("subject") ?? ""),
    message: String(form.get("message") ?? ""),
  };
  const parsed = requestForm.safeParse(typed);
  if (!parsed.success) {
    return { ...typed, error: parsed.error.issues[0]?.message ?? "Check the form." };
  }
  const result = await authed(session, (token) =>
    createToolRequest(token, parsed.data.subject, parsed.data.message),
  );
  if (!result.ok) return { ...typed, error: failureMessage(result.failure) };
  return { sent: { ticketId: result.value.id, replyEmail: session.email } };
}
