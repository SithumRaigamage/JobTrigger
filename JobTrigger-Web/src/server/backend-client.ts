import "server-only";

import { randomBytes } from "node:crypto";

import { z } from "zod";

import type { AppFailure } from "@/domain/app-failure";
import { fail, ok, type Result } from "@/domain/result";

import { getConfig } from "./config";

/*
 * The one place the website calls JobTrigger-Backend
 * (docs/web-architecture.md §2, §5). Every call returns a Result; no fetch
 * error or status code escapes. Auth is the backend's `x-auth-token`
 * header, never `Authorization: Bearer` (docs/api-reference.md).
 */

const TIMEOUT_MS = 10_000;

/** The backend's x-request-id format (AUD-63). */
const REQUEST_ID = /^[A-Za-z0-9._-]{1,64}$/;

/** 16 hex characters, like the app's core/network/request_id.dart. */
export function newRequestId(): string {
  return randomBytes(8).toString("hex");
}

const errorBody = z.object({ message: z.string() });

const toolUnavailableBody = z.object({ code: z.literal("TOOL_NOT_AVAILABLE") });

const alreadySubscribedBody = z.object({ code: z.literal("ALREADY_SUBSCRIBED") });

const planLimitBody = z.object({ code: z.literal("PLAN_LIMIT"), limit: z.string().optional() });

/** Maps a non-2xx backend response to an AppFailure. */
export function failureFor(status: number, body: unknown, requestId: string | null): AppFailure {
  if (status === 401) return { kind: "auth" };
  if (status === 404) return { kind: "notFound" };
  if (status === 403) {
    if (toolUnavailableBody.safeParse(body).success) return { kind: "toolUnavailable" };
    // Only a PLAN_LIMIT 403 is special; any other 403 stays a server failure
    // exactly as before.
    const parsed = planLimitBody.safeParse(body);
    if (parsed.success) return { kind: "planLimit", limit: parsed.data.limit ?? "unknown" };
  }
  if (status === 409 && alreadySubscribedBody.safeParse(body).success)
    return { kind: "alreadySubscribed" };
  if (status === 503) return { kind: "billingUnavailable" };
  if (status === 400) {
    const parsed = errorBody.safeParse(body);
    // A 400's message is written for users and never carries internals
    // (AUD-06), so it's shown as-is, as the app does (AUD-65).
    return parsed.success
      ? { kind: "rejected", message: parsed.data.message }
      : { kind: "server", status };
  }
  return {
    kind: "server",
    status,
    ...(requestId && REQUEST_ID.test(requestId) ? { requestId } : {}),
  };
}

/** Statuses a student-plan call explains in its own words. */
const EXPLAINED_STATUSES = new Set([400, 409, 413, 415, 429, 503]);
const explainedBody = z.object({ message: z.string().min(1), code: z.string().optional() });

/**
 * Phase 21: the failure for a call that opted into `explain`: the backend's
 * own sentence and code for the statuses above, else null (fall back to
 * [failureFor]). The messages are written for users (AUD-06).
 */
export function explainedFailureFor(status: number, body: unknown): AppFailure | null {
  if (!EXPLAINED_STATUSES.has(status)) return null;
  const parsed = explainedBody.safeParse(body);
  if (!parsed.success) return null;
  return {
    kind: "explained",
    status,
    message: parsed.data.message,
    ...(parsed.data.code ? { code: parsed.data.code } : {}),
  };
}

export type BackendCall = {
  method?: "GET" | "POST" | "PUT" | "DELETE";
  path: `/api/${string}`;
  body?: unknown;
  /** The JobTrigger access token, for authenticated endpoints. */
  accessToken?: string;
  /** Phase 21: show the backend's own sentence for 400/409/413/415/429/503. */
  explain?: boolean;
};

/**
 * Calls the backend and parses the JSON response with [schema]. Failure
 * details go to the server log by kind only — never a body, token or URL
 * query (WEB-B3).
 */
export async function callBackend<S extends z.ZodType>(
  call: BackendCall,
  schema: S,
): Promise<Result<z.infer<S>>> {
  const requestId = newRequestId();
  let response: Response;
  try {
    response = await fetch(`${getConfig().backendUrl}${call.path}`, {
      method: call.method ?? "GET",
      headers: {
        accept: "application/json",
        "x-request-id": requestId,
        ...(call.body !== undefined ? { "content-type": "application/json" } : {}),
        ...(call.accessToken ? { "x-auth-token": call.accessToken } : {}),
      },
      body: call.body !== undefined ? JSON.stringify(call.body) : undefined,
      signal: AbortSignal.timeout(TIMEOUT_MS),
      cache: "no-store",
    });
  } catch (error) {
    const name = error instanceof Error ? error.name : "unknown";
    console.warn(
      `backend: ${call.method ?? "GET"} ${call.path} unreachable (${name}) [${requestId}]`,
    );
    return fail({ kind: "network" });
  }

  let body: unknown = null;
  try {
    body = await response.json();
  } catch {
    // Non-JSON: a proxy or login page. Handled below by status and schema.
  }

  if (!response.ok) {
    const explained = call.explain ? explainedFailureFor(response.status, body) : null;
    if (explained) return fail(explained);
    const failure = failureFor(response.status, body, response.headers.get("x-request-id"));
    if (failure.kind === "server") {
      console.warn(
        `backend: ${call.method ?? "GET"} ${call.path} → ${response.status} [${requestId}]`,
      );
    }
    return fail(failure);
  }

  const parsed = schema.safeParse(body);
  if (!parsed.success) {
    console.warn(
      `backend: ${call.method ?? "GET"} ${call.path} unexpected response shape [${requestId}]`,
    );
    return fail({ kind: "unexpected" });
  }
  return ok(parsed.data);
}

const MAX_BINARY_BYTES = 8 * 1024 * 1024;

/**
 * Phase 21: GET a file from the backend (a student document, for the admin
 * page's server to pass on). Same headers, timeout and failure mapping as
 * [callBackend]; the body is returned as bytes with its content type, and is
 * never logged.
 */
export async function callBackendBytes(call: {
  path: `/api/${string}`;
  accessToken: string;
}): Promise<Result<{ bytes: ArrayBuffer; contentType: string }>> {
  const requestId = newRequestId();
  let response: Response;
  try {
    response = await fetch(`${getConfig().backendUrl}${call.path}`, {
      headers: { "x-request-id": requestId, "x-auth-token": call.accessToken },
      signal: AbortSignal.timeout(TIMEOUT_MS),
      cache: "no-store",
    });
  } catch (error) {
    const name = error instanceof Error ? error.name : "unknown";
    console.warn(`backend: GET ${call.path} unreachable (${name}) [${requestId}]`);
    return fail({ kind: "network" });
  }
  if (!response.ok) {
    let body: unknown = null;
    try {
      body = await response.json();
    } catch {
      // Not JSON; the status decides.
    }
    if (response.status === 410) {
      return fail({ kind: "explained", status: 410, message: errorMessageOf(body) });
    }
    return fail(failureFor(response.status, body, response.headers.get("x-request-id")));
  }
  const bytes = await response.arrayBuffer();
  if (bytes.byteLength > MAX_BINARY_BYTES) return fail({ kind: "unexpected" });
  return ok({ bytes, contentType: response.headers.get("content-type") ?? "" });
}

function errorMessageOf(body: unknown): string {
  const parsed = errorBody.safeParse(body);
  return parsed.success ? parsed.data.message : "That document is no longer available.";
}
