/**
 * AUD-25: configuration read once at startup.
 */

const { loadKeys } = require('../security/secretCipher');

const REQUIRED = ['JWT_SECRET', 'MONGODB_URI', 'CREDENTIALS_ENCRYPTION_KEY'];

/** Names of required variables that are missing or blank in [env]. */
function missingConfig(env = process.env) {
  return REQUIRED.filter((name) => !env[name] || !env[name].trim());
}

/**
 * Browser origins allowed by CORS, from comma-separated `CORS_ORIGINS`.
 * Empty (the default) means no CORS at all: the mobile app sends no
 * `Origin`, so only a browser page on another site is affected.
 */
function corsOrigins(env = process.env) {
  return (env.CORS_ORIGINS ?? '')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);
}

/**
 * AUD-44: the number of reverse-proxy hops in front of the server, for
 * Express's `trust proxy`, or null when unset (direct connections). Only a
 * positive whole number is accepted: `true`, a subnet list, or a typo would
 * make Express trust client-supplied `X-Forwarded-For` hops, letting a
 * client choose the IP the login rate limiter keys on.
 */
function trustProxyHops(env = process.env) {
  const raw = env.TRUST_PROXY?.trim();
  if (!raw) return null;
  return /^[1-9][0-9]?$/.test(raw) ? Number(raw) : undefined;
}

const blank = (value) => !value || !String(value).trim();

/**
 * P20-72: SMTP settings, or null when mail is off (SMTP_HOST unset).
 * Development uses the lab's Mailpit: SMTP_HOST=localhost, SMTP_PORT=1025.
 */
function mailConfig(env = process.env) {
  if (blank(env.SMTP_HOST)) return null;
  return {
    host: env.SMTP_HOST.trim(),
    port: Number(env.SMTP_PORT) || 587,
    secure: env.SMTP_SECURE === 'true',
    user: blank(env.SMTP_USER) ? null : env.SMTP_USER,
    pass: blank(env.SMTP_PASS) ? null : env.SMTP_PASS,
    from: blank(env.MAIL_FROM) ? 'JobTrigger <no-reply@jobtrigger.local>' : env.MAIL_FROM.trim(),
  };
}

/** Why the SMTP settings can't be used, or null. */
function mailProblem(env = process.env) {
  const others = ['SMTP_PORT', 'SMTP_SECURE', 'SMTP_USER', 'SMTP_PASS', 'MAIL_FROM'];
  if (blank(env.SMTP_HOST)) {
    const set = others.filter((name) => !blank(env[name]));
    return set.length > 0 ? `SMTP_HOST is required when ${set.join(', ')} is set` : null;
  }
  if (!blank(env.SMTP_PORT) && !/^[1-9][0-9]{0,4}$/.test(env.SMTP_PORT.trim())) {
    return 'SMTP_PORT must be a port number';
  }
  if (!blank(env.SMTP_SECURE) && !['true', 'false'].includes(env.SMTP_SECURE)) {
    return 'SMTP_SECURE must be true or false';
  }
  if (blank(env.SMTP_USER) !== blank(env.SMTP_PASS)) {
    return 'SMTP_USER and SMTP_PASS must be set together';
  }
  return null;
}

/** P20-78: Umami settings, or null when analytics is off. */
function analyticsConfig(env = process.env) {
  if (blank(env.UMAMI_URL) || blank(env.UMAMI_WEBSITE_ID)) return null;
  return { url: env.UMAMI_URL.trim().replace(/\/+$/, ''), websiteId: env.UMAMI_WEBSITE_ID.trim() };
}

/**
 * P20-73: where reset links point. The website page is optional (the app
 * deep link is always included); unset means the email has no web link.
 */
function resetLinkConfig(env = process.env) {
  return {
    webUrl: blank(env.RESET_PASSWORD_URL) ? null : env.RESET_PASSWORD_URL.trim(),
    appUrl: 'jobtrigger://app/reset-password',
  };
}

/**
 * A problem with configuration that is present but unusable, or null:
 * the encryption keys (AUD-03), `TRUST_PROXY` (AUD-44), SMTP (P20-72),
 * or the reset link base (P20-73).
 */
function invalidConfig(env = process.env) {
  if (trustProxyHops(env) === undefined) {
    return 'TRUST_PROXY must be the number of proxy hops in front of the server (e.g. 1)';
  }
  const mail = mailProblem(env);
  if (mail) return mail;
  if (!blank(env.RESET_PASSWORD_URL) && !/^https?:\/\/[^\s?#]+$/.test(env.RESET_PASSWORD_URL.trim())) {
    return 'RESET_PASSWORD_URL must be an http(s) URL without a query string';
  }
  if (!blank(env.UMAMI_URL) && !/^https?:\/\/\S+$/.test(env.UMAMI_URL.trim())) {
    return 'UMAMI_URL must be an http(s) URL';
  }
  if (!env.CREDENTIALS_ENCRYPTION_KEY) return null; // Reported as missing.
  try {
    loadKeys(env);
    return null;
  } catch (err) {
    return err.message;
  }
}

module.exports = {
  missingConfig,
  invalidConfig,
  corsOrigins,
  trustProxyHops,
  mailConfig,
  analyticsConfig,
  resetLinkConfig,
};
