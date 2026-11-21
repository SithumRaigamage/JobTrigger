import { z } from "zod";

import { ok, type Result } from "@/domain/result";

import { callBackend } from "./backend-client";

const created = z.object({ ticket: z.object({ id: z.string() }) });

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
