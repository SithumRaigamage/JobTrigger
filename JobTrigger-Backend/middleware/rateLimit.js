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

/**
 * US-AUTH-08: reset requests send email, so they're limited per IP and per
 * address (the same key as AUD-55), counting every request: a 202 is
 * returned whether or not the account exists.
 */
const passwordResetLimiter = authLimiter({
  windowMs: 15 * MINUTE,
  limit: fromEnv('PASSWORD_RESET_RATE_LIMIT', 5),
});

const passwordResetEmailLimiter = authLimiter({
  windowMs: 60 * MINUTE,
  limit: fromEnv('PASSWORD_RESET_EMAIL_RATE_LIMIT', 3),
  keyGenerator: loginEmailKey,
});

/** Guessing a 256-bit token is hopeless, but cap the attempts anyway. */
const passwordResetConfirmLimiter = authLimiter({
  windowMs: 15 * MINUTE,
  limit: fromEnv('PASSWORD_RESET_CONFIRM_RATE_LIMIT', 10),
});

/** P20-14: a re-sync calls RevenueCat; per user, not per IP. */
const subscriptionRefreshLimiter = authLimiter({
  windowMs: 10 * MINUTE,
  limit: fromEnv('SUBSCRIPTION_REFRESH_RATE_LIMIT', 10),
  keyGenerator: (req) => `user:${req.user?.id ?? ipKeyGenerator(req.ip)}`,
});

/**
 * E4 (PE-32): the decrypted-secret endpoint, per user. The app asks once per
 * saved server (then caches), so this is generous for that and a wall for
 * anything harvesting.
 */
const credentialSecretLimiter = authLimiter({
  windowMs: 10 * MINUTE,
  limit: fromEnv('CREDENTIAL_SECRET_RATE_LIMIT', 30),
  keyGenerator: (req) => `user:${req.user?.id ?? ipKeyGenerator(req.ip)}`,
});

/** P20-16: generous; RevenueCat delivers from a few IPs in bursts. */
const billingWebhookLimiter = authLimiter({
  windowMs: MINUTE,
  limit: fromEnv('BILLING_WEBHOOK_RATE_LIMIT', 120),
});

const perUser = (req) => `user:${req.user?.id ?? ipKeyGenerator(req.ip)}`;

/** Phase 21: each start sends an email, so a few per hour per user. */
const studentEmailStartLimiter = authLimiter({
  windowMs: 60 * MINUTE,
  limit: fromEnv('STUDENT_EMAIL_START_RATE_LIMIT', 5),
  keyGenerator: perUser,
});

/** Phase 21: the code itself also allows 5 tries; this caps the rest. */
const studentEmailConfirmLimiter = authLimiter({
  windowMs: 15 * MINUTE,
  limit: fromEnv('STUDENT_EMAIL_CONFIRM_RATE_LIMIT', 15),
  keyGenerator: perUser,
});

/** Phase 21: an upload is up to 5 MB stored encrypted, so a few per hour. */
const studentDocumentLimiter = authLimiter({
  windowMs: 60 * MINUTE,
  limit: fromEnv('STUDENT_DOCUMENT_RATE_LIMIT', 5),
  keyGenerator: perUser,
});

/** SP-31: the admin routes, per user; generous for a person, a wall for a script. */
const adminLimiter = authLimiter({
  windowMs: MINUTE,
  limit: fromEnv('ADMIN_RATE_LIMIT', 120),
  keyGenerator: perUser,
});

/**
 * Phase 25 (P25-02): filing a ticket is something a person does a handful of
 * times, so a few per hour per account, never per IP (an office behind one
 * NAT address shares an IP).
 */
const supportTicketLimiter = authLimiter({
  windowMs: 60 * MINUTE,
  limit: fromEnv('SUPPORT_TICKET_RATE_LIMIT', 5),
  keyGenerator: perUser,
});

/**
 * US-PROMO-01: a person redeems a code once. The limit is per account (never
 * per IP: an office behind one NAT address shares an IP) and counts every
 * attempt, so a code list can't be walked.
 */
const promoRedeemLimiter = authLimiter({
  windowMs: 15 * MINUTE,
  limit: fromEnv('PROMO_REDEEM_RATE_LIMIT', 10),
  keyGenerator: perUser,
});

module.exports = {
  adminLimiter,
  studentDocumentLimiter,
  authLimiter,
  studentEmailConfirmLimiter,
  studentEmailStartLimiter,
  credentialSecretLimiter,
  billingWebhookLimiter,
  subscriptionRefreshLimiter,
  passwordResetConfirmLimiter,
  passwordResetEmailLimiter,
  passwordResetLimiter,
  promoRedeemLimiter,
  loginEmailKey,
  loginEmailLimiter,
  loginLimiter,
  refreshKey,
  refreshLimiter,
  signupLimiter,
  supportTicketLimiter,
};
