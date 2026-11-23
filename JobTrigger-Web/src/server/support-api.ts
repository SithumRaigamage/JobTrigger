import "server-only";

import { z } from "zod";

import type {
  AdminSupportTicket,
  SupportArea,
  SupportCategory,
  SupportImpact,
  SupportStatus,
} from "@/domain/support";
import { ok, type Result } from "@/domain/result";

import { callBackend, callBackendBytes } from "./backend-client";

/*
 * The website's support calls (docs/api-reference.md). Every call goes
 * through the one backend client: the app's x-auth-token header, Results not
 * thrown errors, and 413/415 explained in the backend's own words when the
 * caller opts in. Screenshot bytes travel as base64 in the JSON body, exactly
 * as they do from the Flutter app.
 */

const created = z.object({ ticket: z.object({ id: z.string() }) });

const screenshotMeta = z.object({
  index: z.number(),
  mime: z.string(),
  size: z.number(),
  hash: z.string(),
  createdAt: z.string().nullable().optional().default(null),
  deletedAt: z.string().nullable().optional().default(null),
});

const ticket = z.object({
  id: z.string(),
  category: z.string(),
  subject: z.string(),
  message: z.string(),
  areas: z.array(z.string()).optional().default([]),
  impact: z.string().optional().default("minor"),
  // Older tickets predate this field; the backend now always sends it, but
  // the site stays tolerant the way admin-students-api is with new fields.
  screenshotCount: z.number().optional().default(0),
  status: z.string(),
  createdAt: z.string().optional().default(""),
  updatedAt: z.string().optional().default(""),
  replyEmail: z.string().nullable().optional().default(null),
  userEmail: z.string().nullable().optional().default(null),
  appVersion: z.string().nullable().optional().default(null),
  buildNumber: z.string().nullable().optional().default(null),
  tool: z.string().nullable().optional().default(null),
  platform: z.string().nullable().optional().default(null),
  serverHost: z.string().nullable().optional().default(null),
  // Detail only; the queue omits it entirely.
  screenshots: z.array(screenshotMeta).optional(),
});

const list = z.object({ tickets: z.array(ticket) });
const one = z.object({ ticket });

export type SupportScreenshotUpload = { name: string; data: string };

export type NewSupportTicket = {
  category: SupportCategory;
  subject: string;
  message: string;
  areas: SupportArea[];
  impact: SupportImpact;
  replyEmail: string;
  screenshots: SupportScreenshotUpload[];
};

/**
 * US-WEB-04 (owner decision 2026-11-21): a tool request from the website
 * files the same Support ticket as the app's "Need another tool?"
 * (`POST /api/support/tickets`, US-SUP-03), so requests land in one place.
 */
export async function createToolRequest(
  accessToken: string,
  subject: string,
  message: string,
): Promise<Result<{ id: string }>> {
  const result = await callBackend(
    {
      method: "POST",
      path: "/api/support/tickets",
      accessToken,
      body: { category: "tool_request", subject, message },
    },
    created,
  );
  return result.ok ? ok({ id: result.value.ticket.id }) : result;
}

/** Phase 31 (US-SUP-05/06): the signed-in form's rich ticket. */
export function createSupportTicket(
  accessToken: string,
  input: NewSupportTicket,
): Promise<Result<{ id: string }>> {
  return callBackend(
    {
      method: "POST",
      path: "/api/support/tickets",
      accessToken,
      explain: true,
      body: {
        category: input.category,
        subject: input.subject,
        message: input.message,
        areas: input.areas,
        impact: input.impact,
        replyEmail: input.replyEmail,
        screenshots: input.screenshots.map((shot) => ({ name: shot.name, data: shot.data })),
      },
    },
    created,
  ).then((result) => (result.ok ? ok({ id: result.value.ticket.id }) : result));
}

export type SupportStatusFilter = SupportStatus | "all";

/** The owner's queue, newest first; the backend ignores an "all" status. */
export function listSupportTickets(
  accessToken: string,
  status: SupportStatusFilter,
): Promise<Result<AdminSupportTicket[]>> {
  return callBackend(
    { path: `/api/admin/support/tickets?status=${status}`, accessToken },
    list,
  ).then((result) => (result.ok ? ok(result.value.tickets) : result));
}

const OBJECT_ID = /^[a-f0-9]{24}$/i;

/** Ids are built into a path, so only the backend's own id shape is allowed. */
export const isTicketId = (value: string): boolean => OBJECT_ID.test(value);

/** The owner's full detail, with screenshot metadata (never bytes). */
export function getSupportTicket(
  accessToken: string,
  id: string,
): Promise<Result<AdminSupportTicket>> {
  return callBackend({ path: `/api/admin/support/tickets/${id}`, accessToken }, one).then(
    (result) => (result.ok ? ok(result.value.ticket) : result),
  );
}

/** Move a ticket to triaged or closed. */
export function updateSupportStatus(
  accessToken: string,
  id: string,
  status: SupportStatus,
): Promise<Result<AdminSupportTicket>> {
  return callBackend(
    {
      method: "PATCH",
      path: `/api/admin/support/tickets/${id}`,
      body: { status },
      accessToken,
    },
    one,
  ).then((result) => (result.ok ? ok(result.value.ticket) : result));
}

/** One decrypted screenshot, for the route that streams it to the owner. */
export function fetchSupportScreenshot(accessToken: string, id: string, index: number) {
  return callBackendBytes({
    path: `/api/admin/support/tickets/${id}/screenshots/${index}`,
    accessToken,
  });
}
