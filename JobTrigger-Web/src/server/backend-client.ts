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

/** Maps a non-2xx backend response to an AppFailure. */
export function failureFor(status: number, body: unknown, requestId: string | null): AppFailure {
  if (status === 401) return { kind: "auth" };
  if (status === 404) return { kind: "notFound" };
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

export type BackendCall = {
  method?: "GET" | "POST" | "PUT" | "DELETE";
  path: `/api/${string}`;
  body?: unknown;
  /** The JobTrigger access token, for authenticated endpoints. */
  accessToken?: string;
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
