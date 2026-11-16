const { MongoMemoryServer } = require('mongodb-memory-server');
const mongoose = require('mongoose');

// The suites sign up and log in far more often than a real client. The
// limiter itself is tested with its own small limits (rate_limit.test.js).
// Set before the server (and so the limiters) load.
process.env.LOGIN_RATE_LIMIT = '10000';
process.env.LOGIN_EMAIL_RATE_LIMIT = '10000';
process.env.SIGNUP_RATE_LIMIT = '10000';
process.env.REFRESH_RATE_LIMIT = '10000';
// Every test runs with every tool released (the shipped manifest is release
// 1.0, Jenkins only), so tools a release hides stay tested. The suites about
// the release gate set their own manifest and restore this one.
const releasedTools = require('../lib/releasedTools');
releasedTools.useManifest(releasedTools.allToolsManifest());

process.env.PASSWORD_RESET_RATE_LIMIT = '10000';
process.env.PASSWORD_RESET_EMAIL_RATE_LIMIT = '10000';
process.env.PASSWORD_RESET_CONFIRM_RATE_LIMIT = '10000';
process.env.SUBSCRIPTION_REFRESH_RATE_LIMIT = '10000';
process.env.BILLING_WEBHOOK_RATE_LIMIT = '10000';
process.env.STUDENT_EMAIL_START_RATE_LIMIT = '10000';
process.env.STUDENT_EMAIL_CONFIRM_RATE_LIMIT = '10000';
process.env.STUDENT_DOCUMENT_RATE_LIMIT = '10000';
process.env.ADMIN_RATE_LIMIT = '10000';
// The daily student job is started by the real server only.
process.env.STUDENT_JOBS_ENABLED = 'false';
// AUD-03: a throwaway key per run; secrets are encrypted at rest.
process.env.CREDENTIALS_ENCRYPTION_KEY = require('crypto').randomBytes(32).toString('base64');
// P20-72/73/78: optional features configured in a developer's .env (SMTP,
// reset link, Umami) must not leak into the suites. dotenv never overrides
// a variable that is already set, so blank ones here keep them out; the
// suites that need these features inject fakes instead.
for (const name of [
  'SMTP_HOST', 'SMTP_PORT', 'SMTP_SECURE', 'SMTP_USER', 'SMTP_PASS', 'MAIL_FROM',
  'RESET_PASSWORD_URL', 'UMAMI_URL', 'UMAMI_WEBSITE_ID',
  // E3: the suites never report to a real host.
  'SENTRY_DSN', 'SENTRY_ENVIRONMENT', 'SENTRY_RELEASE',
  // P20-17: billing is off in the suites unless a test turns it on.
  'BILLING_ENABLED', 'REVENUECAT_SECRET_API_KEY', 'REVENUECAT_WEBHOOK_AUTH',
  // Phase 21: no owner address or renewal unless a test sets them.
  'STUDENT_ADMIN_EMAIL', 'STUDENT_RENEWAL_ENABLED',
  'PADDLE_API_KEY', 'PADDLE_WEBHOOK_SECRET', 'PADDLE_PRICE_MONTHLY', 'PADDLE_PRICE_YEARLY', 'PADDLE_ENV',
]) {
  process.env[name] = '';
}
// §19: the server logs a line per request; the suites make hundreds of
// requests, so the log is off unless a test asks for it.
process.env.LOG_LEVEL = 'silent';

const serverModule = require('../server');

let mongoServer;
let serverInstance;

before(async function() {
  this.timeout(20000);
  mongoServer = await MongoMemoryServer.create();
  process.env.MONGODB_URI = mongoServer.getUri();
  process.env.JWT_SECRET = process.env.JWT_SECRET || 'test_jwt_secret';

  // Start the server which will connect mongoose to the in-memory mongo
  serverInstance = await serverModule.startServer();
  require('./support/api').useServer(serverInstance);
});

after(async function() {
  await mongoose.disconnect();
  if (serverInstance && serverInstance.close) {
    serverInstance.close();
  }
  if (mongoServer) await mongoServer.stop();
});
