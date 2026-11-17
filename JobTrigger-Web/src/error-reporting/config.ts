/*
 * E3: where crash reports go, from the environment. The DSN is public by
 * design (it only lets a client *send* events), so it is a NEXT_PUBLIC_
 * variable: the browser needs it too. With no DSN reporting is off.
 *
 * Exception to docs/web-architecture.md §8 ("config is read in
 * src/server/config.ts only"): that file is server-only and the browser
 * needs these values, so they are read here, and are not secrets.
 */

import { version } from "../../package.json";

export type ReportingConfig = {
  dsn: string;
  environment: "development" | "production" | (string & {});
  release: string;
};

type Env = Record<string, string | undefined>;

const blank = (value: string | undefined) => !value || !value.trim();

/** The reporting settings in [env], or null when reporting is off. */
export function reportingConfig(env: Env): ReportingConfig | null {
  const dsn = env.NEXT_PUBLIC_SENTRY_DSN;
  if (blank(dsn)) return null;
  const environment = blank(env.NEXT_PUBLIC_SENTRY_ENVIRONMENT)
    ? env.NODE_ENV === "production"
      ? "production"
      : "development"
    : env.NEXT_PUBLIC_SENTRY_ENVIRONMENT!.trim();
  const release = blank(env.NEXT_PUBLIC_SENTRY_RELEASE)
    ? version
    : env.NEXT_PUBLIC_SENTRY_RELEASE!.trim();
  return { dsn: dsn!.trim(), environment, release };
}

/** The origin events are sent to (for the CSP), or null. */
export function reportingOrigin(dsn: string | undefined): string | null {
  if (blank(dsn)) return null;
  try {
    return new URL(dsn!.trim()).origin;
  } catch {
    return null;
  }
}
