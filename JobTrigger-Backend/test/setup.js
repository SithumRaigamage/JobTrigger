const { MongoMemoryServer } = require('mongodb-memory-server');
const mongoose = require('mongoose');

// The suites sign up and log in far more often than a real client. The
// limiter itself is tested with its own small limits (rate_limit.test.js).
// Set before the server (and so the limiters) load.
process.env.LOGIN_RATE_LIMIT = '10000';
process.env.LOGIN_EMAIL_RATE_LIMIT = '10000';
process.env.SIGNUP_RATE_LIMIT = '10000';
process.env.REFRESH_RATE_LIMIT = '10000';
process.env.PASSWORD_RESET_RATE_LIMIT = '10000';
process.env.PASSWORD_RESET_EMAIL_RATE_LIMIT = '10000';
process.env.PASSWORD_RESET_CONFIRM_RATE_LIMIT = '10000';
// AUD-03: a throwaway key per run; secrets are encrypted at rest.
process.env.CREDENTIALS_ENCRYPTION_KEY = require('crypto').randomBytes(32).toString('base64');
// P20-72/73/78: optional features configured in a developer's .env (SMTP,
// reset link, Umami) must not leak into the suites. dotenv never overrides
// a variable that is already set, so blank ones here keep them out; the
// suites that need these features inject fakes instead.
for (const name of [
  'SMTP_HOST', 'SMTP_PORT', 'SMTP_SECURE', 'SMTP_USER', 'SMTP_PASS', 'MAIL_FROM',
  'RESET_PASSWORD_URL', 'UMAMI_URL', 'UMAMI_WEBSITE_ID',
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
