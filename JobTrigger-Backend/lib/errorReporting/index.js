/**
 * E3 / PE-20: crash and error reporting for the backend.
 *
 * `@sentry/node` pointed at GlitchTip (a Sentry-compatible server). With no
 * DSN configured everything here is a no-op, so tests and local development
 * send nothing. Every event passes through `scrubEvent`; if the host is
 * unreachable it waits in the crash outbox (`outbox.js`).
 */

'use strict';

const path = require('path');
const Sentry = require('@sentry/node');
const { scrubEvent } = require('./scrub');
const { createOutbox, withOutbox } = require('./outbox');

let active = false;
let activeTransport;

/** True once `init` has started the SDK. */
const isEnabled = () => active;

/**
 * @param {object|null} config from `errorReportingConfig()`; null = off.
 * @param {object} [overrides] tests inject `transport` (a Sentry transport
 *   factory) and `outboxDir`.
 */
function init(config, overrides = {}) {
  if (!config?.dsn || active) return false;

  const outboxDir = overrides.outboxDir ?? path.join(__dirname, '..', '..', 'crash-outbox');
  const makeInner = overrides.transport ?? Sentry.makeNodeTransport;

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
    // Only the integrations that report crashes. No request-data, console,
    // http or local-variable capture: nothing that could carry a secret.
    defaultIntegrations: false,
    integrations: [
      Sentry.onUncaughtExceptionIntegration(),
      Sentry.onUnhandledRejectionIntegration(),
      Sentry.dedupeIntegration(),
      Sentry.linkedErrorsIntegration(),
    ],
    beforeSend: (event) => scrubEvent(event),
    beforeBreadcrumb: () => null,
    transport: (options) => {
      const outbox = createOutbox({ dir: outboxDir, dsn: config.dsn });
      activeTransport = withOutbox(makeInner(options), outbox, overrides.outbox);
      return activeTransport;
    },
  });
  active = true;
  return true;
}

/**
 * Report an unexpected server error. [context] holds only what is safe:
 * the request id, method and route path (never the query string).
 */
function captureServerError(err, { requestId, method, path: routePath } = {}) {
  if (!active) return;
  Sentry.withScope((scope) => {
    if (requestId) scope.setTag('request_id', requestId);
    if (method) scope.setTag('method', method);
    if (routePath) scope.setTag('route', routePath);
    Sentry.captureException(err);
  });
}

/** Wait for pending events to be sent (or stored). */
const flush = (timeoutMs = 2000) => (active ? Sentry.flush(timeoutMs) : Promise.resolve(true));

/** Stop reporting. Used by tests. */
async function shutdown() {
  if (!active) return;
  await Sentry.close(2000);
  activeTransport?.stop?.();
  active = false;
}

module.exports = { captureServerError, flush, init, isEnabled, shutdown };
