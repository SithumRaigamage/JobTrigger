/*
 * E3, PE-22: crash reporting for the website's server side (route handlers,
 * server components and server actions), started from instrumentation.ts.
 * `@sentry/nextjs` pointed at GlitchTip. Off without a DSN.
 */

import path from "node:path";

import * as Sentry from "@sentry/nextjs";

import type { ReportingConfig } from "./config";
import { createOutbox, withOutbox } from "./outbox";
import { scrubEvent } from "./scrub";

type Overrides = {
  /** Tests inject the inner transport factory and the outbox folder. */
  transport?: (options: never) => never;
  outboxDir?: string;
};

let started = false;
let stopTransport: (() => void) | undefined;

export function initServerReporting(config: ReportingConfig | null, overrides: Overrides = {}) {
  if (!config || started) return false;
  const outboxDir = overrides.outboxDir ?? path.join(process.cwd(), "crash-outbox");
  const makeInner = (overrides.transport ?? Sentry.makeNodeTransport) as (
    options: unknown,
  ) => never;

  Sentry.init({
    dsn: config.dsn,
    environment: config.environment,
    release: config.release,
    // v11 replaced `sendDefaultPii: false` with `dataCollection`: collect no
    // user info, cookies, headers, bodies or query parameters.
    dataCollection: {
      userInfo: false,
      cookies: false,
      httpHeaders: false,
      httpBodies: [],
      urlQueryParams: false,
    },
    tracesSampleRate: 0,
    maxBreadcrumbs: 0,
    // No request-data, console, http or local-variable capture: nothing that
    // could carry a form value or a token.
    defaultIntegrations: false,
    integrations: [
      Sentry.onUncaughtExceptionIntegration(),
      Sentry.onUnhandledRejectionIntegration(),
      Sentry.dedupeIntegration(),
      Sentry.linkedErrorsIntegration(),
    ],
    beforeSend: (event) => scrubEvent(event),
    beforeBreadcrumb: () => null,
    transport: (options: unknown) => {
      const outbox = createOutbox({ dir: outboxDir, dsn: config.dsn });
      const wrapped = withOutbox(makeInner(options), outbox);
      stopTransport = wrapped.stop;
      return wrapped as never;
    },
  });
  started = true;
  return true;
}

/** Stop reporting. Used by tests. */
export async function shutdownServerReporting() {
  if (!started) return;
  await Sentry.close(2000);
  stopTransport?.();
  started = false;
}
