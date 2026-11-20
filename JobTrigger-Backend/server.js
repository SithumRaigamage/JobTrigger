const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
require('dotenv').config();

const {
  corsOrigins,
  errorReportingConfig,
  invalidConfig,
  missingConfig,
  trustProxyHops,
} = require('./config/env');
const errorReporting = require('./lib/errorReporting');
const { errorHandler, notFound } = require('./middleware/errorHandler');
const requestId = require('./middleware/requestId');
const requestLogger = require('./middleware/requestLogger');
const { logger } = require('./lib/logger');
const { connectDatabase, connectionHint } = require('./lib/database');
const { auditKeyIds } = require('./security/keyIdAudit');
const CREDENTIAL_TARGETS = require('./models/credentialTargets');
const studentJobs = require('./lib/studentJobs');

// AUD-04: defence in depth. Query filters built from request data treat
// `$`-operators as literal values, so `{"$gt": ""}` can't match every row
// even if a handler forgets a type check.
mongoose.set('sanitizeFilter', true);

// E3 / PE-20: before anything that can fail. A no-op without SENTRY_DSN.
errorReporting.init(errorReportingConfig());

const app = express();

// AUD-05: behind a load balancer or reverse proxy, the rate limiter must
// see the client's IP, not the proxy's. TRUST_PROXY is the number of
// proxy hops (e.g. 1). Unset means direct connections. Anything else is
// refused at startup (AUD-44, see invalidConfig).
const proxyHops = trustProxyHops();
if (proxyHops) {
  app.set('trust proxy', proxyHops);
}

// Middleware
// §19: the request id first, before anything that can fail, so every
// response carries it and every later log line can be tied to it.
app.use(requestId);
app.use(requestLogger);

// AUD-25: security headers, and CORS only for origins listed in
// CORS_ORIGINS (none by default; the mobile app doesn't need CORS).
app.use(helmet());
const origins = corsOrigins();
app.use(cors({ origin: origins.length > 0 ? origins : false }));
// Paddle signs the exact bytes it sends, so its webhook gets the raw body.
// Registered first: express.json() then leaves that request alone.
app.use('/api/billing/paddle/webhook', express.raw({ type: '*/*', limit: '1mb' }));
// Phase 21 (SP-30): a student document arrives as base64 in JSON, so this one
// route reads up to ~7 MB (a 5 MB file is a third larger in base64). Registered
// first: the global express.json() below then leaves this request alone.
app.use('/api/student/document', express.json({ limit: '7mb' }));
app.use(express.json());

// Routes
app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/credentials', require('./routes/credentialRoutes'));
app.use('/api/github-credentials', require('./routes/githubCredentialRoutes'));
app.use('/api/sonarqube-credentials', require('./routes/sonarqubeCredentialRoutes'));
app.use('/api/appinfo', require('./routes/appInfoRoutes'));
// NR-06 (BACKLOG-02): push-token registration. Off until FCM is configured.
app.use('/api/devices', require('./routes/deviceRoutes'));
app.use('/api/subscription', require('./routes/subscriptionRoutes'));
app.use('/api/team', require('./routes/teamRoutes'));
// Development-only sandbox store (404 everywhere else). Mounted before the
// real billing routes so it owns its own prefix.
app.use('/api/billing/sandbox', require('./routes/sandboxBillingRoutes'));
app.use('/api/billing', require('./routes/billingRoutes'));
app.use('/api/student', require('./routes/studentRoutes'));
app.use('/api/admin/students', require('./routes/adminStudentRoutes'));
// Release 1.0.0: the owner's subscription console (grant/revoke test Pro).
app.use('/api/admin/subscriptions', require('./routes/adminSubscriptionRoutes'));
// Phase 25: support and issue tickets, and their owner-only triage.
app.use('/api/support', require('./routes/supportRoutes'));
app.use('/api/admin/support', require('./routes/adminSupportRoutes'));

app.get('/', (req, res) => {
  res.json({ message: 'JobTrigger Backend API is running' });
});

// AUD-17: the container HEALTHCHECK. Unhealthy while MongoDB isn't
// connected, so an orchestrator can restart or hold traffic.
app.get('/healthz', (req, res) => {
  const up = mongoose.connection.readyState === 1;
  res.status(up ? 200 : 503).json({ status: up ? 'ok' : 'unavailable' });
});

// AUD-06: after every route. JSON 404s, and errors logged server-side
// with a generic body to the client.
app.use(notFound);
app.use(errorHandler);

/**
 * AUD-63: name the key ids the database still uses that the keyring
 * can't decrypt. Loud, but not fatal: the server starts anyway, and the
 * affected credentials are flagged one by one when they're read.
 */
async function auditCredentialKeyIds() {
  try {
    const { missing } = await auditKeyIds(CREDENTIAL_TARGETS);
    if (missing.length > 0) {
      logger.error('credential.key_ids_missing', { missing });
    }
  } catch (err) {
    logger.error('credential.key_id_audit_failed', { error: err.message });
  }
}

// Database Connection (start server after DB connection)
async function startServer() {
  // AUD-25: refuse to start half-configured rather than fail per request.
  const missing = missingConfig();
  if (missing.length > 0) {
    logger.error('config.missing', { missing });
    process.exit(1);
  }
  const invalid = invalidConfig();
  if (invalid) {
    logger.error('config.invalid', { error: invalid });
    process.exit(1);
  }
  try {
    await connectDatabase();
    logger.info('server.mongo_connected');
    await auditCredentialKeyIds();
    studentJobs.start();
    const PORT = process.env.PORT || 5001;
    const HOST = process.env.HOST || '0.0.0.0';
    const server = app.listen(PORT, HOST, () => {
      logger.info('server.listening', { host: HOST, port: Number(PORT) });
    });
    return server;
  } catch (err) {
    // P17-03: the hint says what to check (Atlas user, IP, DNS); the URI
    // itself is never logged, since it carries the password.
    const hint = connectionHint(err);
    logger.error('server.mongo_connect_failed', {
      error: err.message,
      ...(hint && { hint }),
    });
    process.exit(1);
  }
}

// Only start server when this file is run directly. This allows tests to
// require the module, set environment variables (in-memory mongo) and then
// call `startServer()` explicitly.
if (require.main === module) {
  startServer();
}

module.exports = { app, startServer, auditCredentialKeyIds };
