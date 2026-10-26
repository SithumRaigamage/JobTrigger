import "server-only";

import { z } from "zod";

import { getConfig } from "./config";

/*
 * Public app info from the backend (GET /api/appinfo, docs/api-reference.md).
 * The site needs only the support address, shared with the app so "Request
 * a tool" lands in the same inbox from both. Best-effort: any failure is
 * null and the caller falls back; the details go to the server log only.
 */

const appInfoSchema = z.object({ supportEmail: z.email() });

export type AppInfo = z.infer<typeof appInfoSchema>;

const TTL_MS = 5 * 60_000;
const FAILURE_TTL_MS = 30_000;
const TIMEOUT_MS = 3_000;

let cache: { value: AppInfo | null; expires: number } | undefined;

async function load(): Promise<AppInfo | null> {
  try {
    const response = await fetch(`${getConfig().backendUrl}/api/appinfo`, {
      signal: AbortSignal.timeout(TIMEOUT_MS),
      cache: "no-store",
    });
    if (!response.ok) {
      console.warn(`app-info: backend answered ${response.status}`);
      return null;
    }
    const parsed = appInfoSchema.safeParse(await response.json());
    if (!parsed.success) {
      console.warn("app-info: unexpected response shape");
      return null;
    }
    return parsed.data;
  } catch (error) {
    // Name, message and cause code only. Config errors name variables, never
    // values; fetch errors read like "fetch failed (ECONNREFUSED)".
    const detail =
      error instanceof Error
        ? `${error.name}: ${error.message}${causeCode(error) ? ` (${causeCode(error)})` : ""}`
        : "unknown";
    console.warn(`app-info: unavailable — ${detail}`);
    return null;
  }
}

function causeCode(error: Error): string | undefined {
  const cause = error.cause as { code?: unknown } | undefined;
  return typeof cause?.code === "string" ? cause.code : undefined;
}

/** The backend's public app info, cached for a few minutes; null if unavailable. */
export async function getAppInfo(now: () => number = Date.now): Promise<AppInfo | null> {
  if (cache && cache.expires > now()) return cache.value;
  const value = await load();
  cache = { value, expires: now() + (value ? TTL_MS : FAILURE_TTL_MS) };
  return value;
}

/** Test hook: forget the cached value. */
export function resetAppInfoCache() {
  cache = undefined;
}
