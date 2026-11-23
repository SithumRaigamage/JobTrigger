"use server";

import { z } from "zod";

import { failureMessage } from "@/domain/app-failure";
import {
  MAX_SCREENSHOTS,
  SUPPORT_AREAS,
  SUPPORT_CATEGORIES,
  SUPPORT_IMPACTS,
  checkScreenshotMeta,
  looksLikeScreenshot,
  screenshotProblemMessage,
} from "@/domain/support";
import { authed } from "@/server/authed";
import { requireSession } from "@/server/guard";
import { createSupportTicket, createToolRequest } from "@/server/support-api";

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

export type SupportFormState = {
  error?: string;
  category?: string;
  subject?: string;
  message?: string;
  impact?: string;
  areas?: string[];
  sent?: { ticketId: string; replyEmail: string };
};

// The backend's limits and the app's copy (US-SUP-01/05/06).
const supportForm = z.object({
  category: z.enum(SUPPORT_CATEGORIES, "Choose what kind of report this is."),
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
  impact: z.enum(SUPPORT_IMPACTS, "Choose a known impact."),
  areas: z.array(z.enum(SUPPORT_AREAS)).max(SUPPORT_AREAS.length),
});

const strings = (form: FormData, key: string): string[] =>
  form.getAll(key).filter((value): value is string => typeof value === "string");

/**
 * US-SUP-05/06: the signed-in form's rich ticket. Screenshots are checked
 * here (size, extension, magic bytes) before anything travels; the backend
 * repeats every check. Text survives a refusal; the browser keeps the picked
 * files in its own state for a retry.
 */
export async function submitSupportAction(
  _previous: SupportFormState,
  form: FormData,
): Promise<SupportFormState> {
  const session = await requireSession();
  const typed = {
    category: String(form.get("category") ?? ""),
    subject: String(form.get("subject") ?? ""),
    message: String(form.get("message") ?? ""),
    impact: String(form.get("impact") ?? ""),
    areas: strings(form, "areas"),
  };
  const parsed = supportForm.safeParse(typed);
  if (!parsed.success) {
    return { ...typed, error: parsed.error.issues[0]?.message ?? "Check the form." };
  }

  const files = form.getAll("screenshots").filter((value): value is File => value instanceof File);
  if (files.length > MAX_SCREENSHOTS) {
    return { ...typed, error: `Attach at most ${MAX_SCREENSHOTS} screenshots.` };
  }
  const screenshots: { name: string; data: string }[] = [];
  for (const file of files) {
    const problem = checkScreenshotMeta(file.name, file.size);
    if (problem) return { ...typed, error: screenshotProblemMessage(problem) };
    const head = new Uint8Array(await file.slice(0, 16).arrayBuffer());
    if (!looksLikeScreenshot(head)) {
      return { ...typed, error: screenshotProblemMessage("wrongType") };
    }
    screenshots.push({
      name: file.name,
      data: Buffer.from(await file.arrayBuffer()).toString("base64"),
    });
  }

  const result = await authed(session, (token) =>
    createSupportTicket(token, {
      category: parsed.data.category,
      subject: parsed.data.subject,
      message: parsed.data.message,
      areas: parsed.data.areas,
      impact: parsed.data.impact,
      replyEmail: session.email,
      screenshots,
    }),
  );
  if (!result.ok) return { ...typed, error: failureMessage(result.failure) };
  return { sent: { ticketId: result.value.id, replyEmail: session.email } };
}
