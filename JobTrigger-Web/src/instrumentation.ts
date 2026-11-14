import * as Sentry from "@sentry/nextjs";

import { reportingConfig } from "./error-reporting/config";

/**
 * E3: crash reporting on the server. `register` runs once at startup;
 * `onRequestError` hands Next.js' own errors (server components, route
 * handlers, server actions) to Sentry. Both do nothing without a DSN.
 */
export async function register() {
  if (process.env.NEXT_RUNTIME === "nodejs") {
    const { initServerReporting } = await import("./error-reporting/init-server");
    initServerReporting(reportingConfig(process.env));
  }
}

export const onRequestError = Sentry.captureRequestError;
