const { rateLimit } = require('express-rate-limit');

const MINUTE = 60 * 1000;

/**
 * AUD-05: throttles password guessing and account creation per client IP.
 * Limits come from env so tests (and unusual deployments) can change them.
 * Behind a proxy, set TRUST_PROXY (server.js) so the IP is the client's,
 * not the proxy's.
 */
function authLimiter({ windowMs, limit, skipSuccessfulRequests = false }) {
  return rateLimit({
    windowMs,
    limit,
    skipSuccessfulRequests,
    standardHeaders: 'draft-8', // A combined `RateLimit` header.
    legacyHeaders: false,
    message: { message: 'Too many attempts. Please wait a few minutes and try again.' },
  });
}

const fromEnv = (name, fallback) => Number(process.env[name]) || fallback;

// Only failed logins count, so someone who types their password right is
// never locked out by an attacker guessing at the same IP's quota.
const loginLimiter = authLimiter({
  windowMs: 15 * MINUTE,
  limit: fromEnv('LOGIN_RATE_LIMIT', 10),
  skipSuccessfulRequests: true,
});

const signupLimiter = authLimiter({
  windowMs: 60 * MINUTE,
  limit: fromEnv('SIGNUP_RATE_LIMIT', 5),
});

module.exports = { authLimiter, loginLimiter, signupLimiter };
