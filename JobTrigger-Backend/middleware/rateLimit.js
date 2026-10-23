const { rateLimit, ipKeyGenerator } = require('express-rate-limit');
const { verifyToken } = require('../security/tokens');

const MINUTE = 60 * 1000;

/**
 * AUD-05: throttles password guessing and account creation per client IP.
 * Limits come from env so tests (and unusual deployments) can change them.
 * Behind a proxy, set TRUST_PROXY (server.js) so the IP is the client's,
 * not the proxy's.
 */
function authLimiter({ windowMs, limit, skipSuccessfulRequests = false, keyGenerator }) {
  return rateLimit({
    windowMs,
    limit,
    skipSuccessfulRequests,
    ...(keyGenerator ? { keyGenerator } : {}),
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

/**
 * AUD-55: failed logins are also counted per account, so guessing one
 * account's password from many addresses (a botnet, rotating proxies) hits
 * a limit too, not only guessing from one address. Keyed on the email as
 * the login handler normalizes it; a body without a string email counts
 * against the IP.
 */
function loginEmailKey(req) {
  const email = req.body?.email;
  return typeof email === 'string' && email.trim()
    ? `email:${email.trim().toLowerCase()}`
    : `ip:${ipKeyGenerator(req.ip)}`;
}

const loginEmailLimiter = authLimiter({
  windowMs: 15 * MINUTE,
  limit: fromEnv('LOGIN_EMAIL_RATE_LIMIT', 10),
  skipSuccessfulRequests: true,
  keyGenerator: loginEmailKey,
});

const signupLimiter = authLimiter({
  windowMs: 60 * MINUTE,
  limit: fromEnv('SIGNUP_RATE_LIMIT', 5),
});

/**
 * AUD-47: refreshes are counted per user, not per IP. Every signed-in
 * client refreshes about every 15 minutes, so a per-IP quota let one
 * office behind a single NAT address exhaust it, and each 429 signed
 * people out. A request without a valid refresh token can't name a user,
 * so it's counted against its IP, which still stops hammering.
 */
function refreshKey(req) {
  const payload = verifyToken(req.body?.refreshToken, 'refresh');
  return payload ? `user:${payload.id}` : `ip:${ipKeyGenerator(req.ip)}`;
}

const refreshLimiter = authLimiter({
  windowMs: 15 * MINUTE,
  limit: fromEnv('REFRESH_RATE_LIMIT', 30),
  keyGenerator: refreshKey,
});

module.exports = {
  authLimiter,
  loginEmailKey,
  loginEmailLimiter,
  loginLimiter,
  refreshKey,
  refreshLimiter,
  signupLimiter,
};
