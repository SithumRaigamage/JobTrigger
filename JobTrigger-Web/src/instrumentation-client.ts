import * as Sentry from "@sentry/nextjs";

import { reportingConfig } from "./error-reporting/config";
import { scrubEvent } from "./error-reporting/scrub";

/*
 * E3, PE-22: crash reporting in the browser. Off without a DSN. Unsent
 * events wait in IndexedDB (at most 30) and are retried by the SDK's offline
 * transport. No breadcrumbs, no replay, no feedback widget: nothing that
 * could capture what someone typed into a portal form.
 */
const config = reportingConfig({
  // Written out so Next.js can inline the public values at build time.
  NEXT_PUBLIC_SENTRY_DSN: process.env.NEXT_PUBLIC_SENTRY_DSN,
  NEXT_PUBLIC_SENTRY_ENVIRONMENT: process.env.NEXT_PUBLIC_SENTRY_ENVIRONMENT,
  NEXT_PUBLIC_SENTRY_RELEASE: process.env.NEXT_PUBLIC_SENTRY_RELEASE,
  NODE_ENV: process.env.NODE_ENV,
});

if (config) {
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
    defaultIntegrations: false,
    integrations: [
      Sentry.globalHandlersIntegration(),
      Sentry.browserApiErrorsIntegration(),
      Sentry.dedupeIntegration(),
      Sentry.linkedErrorsIntegration(),
      Sentry.httpContextIntegration(),
    ],
    beforeSend: (event) => scrubEvent(event),
    beforeBreadcrumb: () => null,
    transport: Sentry.makeBrowserOfflineTransport(Sentry.makeFetchTransport),
  });
}

export const onRouterTransitionStart = Sentry.captureRouterTransitionStart;
