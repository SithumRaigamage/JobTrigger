import "server-only";

import { z } from "zod";

/**
 * The website's runtime configuration, read from environment variables
 * (docs/web-architecture.md §8). This is the only file that reads
 * `process.env` for these keys.
 *
 * Validated lazily on first use, not at import: `next build` prerenders
 * marketing pages that never need the backend, so a machine without
 * `SESSION_SECRET` can still build. The first request that does need the
 * config fails loudly with every problem listed — the same idea as the
 * app's AUD-43 release guard.
 */

/** True for http://localhost, 127.0.0.1 and [::1]. */
function isLoopback(url: string): boolean {
  const { hostname } = new URL(url);
  return hostname === "localhost" || hostname === "127.0.0.1" || hostname === "[::1]";
}

const configSchema = z
  .object({
    NODE_ENV: z.enum(["development", "test", "production"]).default("development"),
    JOBTRIGGER_BACKEND_URL: z.url(),
    SESSION_SECRET: z.string().min(32, "must be at least 32 characters"),
    SITE_URL: z.url().default("http://localhost:3000"),
  })
  .superRefine((env, ctx) => {
    // The backend receives account passwords and JWTs, so production must
    // reach it over TLS (WEB-B1). Local development keeps plain http, and so
    // does a loopback address in production (a production build tested
    // against a local or fake backend), where nothing crosses a network.
    if (
      env.NODE_ENV === "production" &&
      !env.JOBTRIGGER_BACKEND_URL.startsWith("https://") &&
      !isLoopback(env.JOBTRIGGER_BACKEND_URL)
    ) {
      ctx.addIssue({
        code: "custom",
        path: ["JOBTRIGGER_BACKEND_URL"],
        message: "must be https:// in production",
      });
    }
  });

export type AppConfig = {
  backendUrl: string;
  sessionSecret: string;
  siteUrl: string;
};

/** Parses [env] into an [AppConfig], or throws listing every problem. */
export function parseConfig(env: Record<string, string | undefined>): AppConfig {
  const result = configSchema.safeParse(env);
  if (!result.success) {
    // Names and reasons only — never the values, which include the secret.
    const problems = result.error.issues
      .map((issue) => `${issue.path.join(".")}: ${issue.message}`)
      .join("; ");
    throw new Error(`Invalid website configuration — ${problems}`);
  }
  return {
    backendUrl: result.data.JOBTRIGGER_BACKEND_URL.replace(/\/+$/, ""),
    sessionSecret: result.data.SESSION_SECRET,
    siteUrl: result.data.SITE_URL.replace(/\/+$/, ""),
  };
}

let cached: AppConfig | undefined;

/** The validated config for this process, parsed on first call. */
export function getConfig(): AppConfig {
  cached ??= parseConfig(process.env);
  return cached;
}
