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

/**
 * Hosts where plain http stays on the machine or a private network:
 * loopback, and single-label names (`backend`, `jobtrigger-backend`), which
 * resolve only as Docker/Kubernetes service names, never on the internet
 * (P15-23: the website container next to the backend). Anything with a
 * dot must be https.
 */
function isPrivateHost(url: string): boolean {
  const { hostname } = new URL(url);
  if (hostname === "localhost" || hostname === "127.0.0.1" || hostname === "[::1]") return true;
  return /^[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$/i.test(hostname);
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
    // does a private host in production (loopback for tests, a container
    // service name next to the backend), where nothing crosses the internet.
    if (
      env.NODE_ENV === "production" &&
      !env.JOBTRIGGER_BACKEND_URL.startsWith("https://") &&
      !isPrivateHost(env.JOBTRIGGER_BACKEND_URL)
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

/**
 * Whether the portal can run: its config is present and valid. Marketing
 * pages work without it (a marketing-only deploy); portal pages check this
 * first and say the portal is unavailable instead of failing.
 */
export function isPortalConfigured(): boolean {
  try {
    getConfig();
    return true;
  } catch (error) {
    console.warn(`portal unavailable — ${error instanceof Error ? error.message : "config error"}`);
    return false;
  }
}

const siteUrlSchema = z.url().default("http://localhost:3000");

/**
 * Just the public site URL, for metadata, the sitemap and robots.txt. Kept
 * apart from getConfig() so marketing pages work on a deploy that has no
 * portal secrets yet.
 */
export function getSiteUrl(env: Record<string, string | undefined> = process.env): string {
  const result = siteUrlSchema.safeParse(env.SITE_URL);
  if (!result.success) throw new Error("Invalid website configuration — SITE_URL: invalid URL");
  return result.data.replace(/\/+$/, "");
}
