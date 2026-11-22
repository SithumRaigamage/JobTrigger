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

/**
 * P20-10: whether plans apply. Off (the default) means everyone gets Pro:
 * development, beta, and every deployment until the stores are live.
 */
function billingEnabled(env = process.env) {
  return env.BILLING_ENABLED === 'true';
}

/**
 * Development-only sandbox store (`/api/billing/sandbox`): it writes plans
 * without Apple, Google or RevenueCat so the purchase → cancel → expiry →
 * resubscribe flow can be tested before the stores exist. Never available
 * in production, whatever the flag says.
 */
/**
 * US-SUB-11 (release 1.0.1; off in 1.0.0): the team plan. Off unless TEAM_PLAN_ENABLED=true;
 * every /api/team route is then a plain 404.
 */
function teamPlanEnabled(env = process.env) {
  return env.TEAM_PLAN_ENABLED === 'true';
}

/** US-SUB-11: Paddle per-seat prices, or null when either is unset. */
function paddleTeamPrices(env = process.env) {
  if (blank(env.PADDLE_PRICE_TEAM_MONTHLY) || blank(env.PADDLE_PRICE_TEAM_YEARLY)) return null;
  return { monthly: env.PADDLE_PRICE_TEAM_MONTHLY.trim(), yearly: env.PADDLE_PRICE_TEAM_YEARLY.trim() };
}

function sandboxBillingEnabled(env = process.env) {
  return env.NODE_ENV !== 'production' && env.SANDBOX_BILLING === 'true';
}

/** P20-15/16: RevenueCat's server key and webhook secret, or null. */
function revenueCatConfig(env = process.env) {
  if (blank(env.REVENUECAT_SECRET_API_KEY) || blank(env.REVENUECAT_WEBHOOK_AUTH)) return null;
  return {
    secretApiKey: env.REVENUECAT_SECRET_API_KEY.trim(),
    webhookAuth: env.REVENUECAT_WEBHOOK_AUTH.trim(),
  };
}

const PADDLE_VARS = [
  'PADDLE_API_KEY', 'PADDLE_WEBHOOK_SECRET', 'PADDLE_PRICE_MONTHLY', 'PADDLE_PRICE_YEARLY',
];

/**
 * Website checkout (Paddle Billing, merchant of record), or null when not
 * set up. `PADDLE_ENV` picks sandbox (default) or production; the API key
 * must match it. Price ids are Paddle's `pri_…` for Pro monthly/yearly.
 */
function paddleConfig(env = process.env) {
  if (PADDLE_VARS.some((name) => blank(env[name]))) return null;
  const production = env.PADDLE_ENV === 'production';
  return {
    apiKey: env.PADDLE_API_KEY.trim(),
    webhookSecret: env.PADDLE_WEBHOOK_SECRET.trim(),
    prices: { monthly: env.PADDLE_PRICE_MONTHLY.trim(), yearly: env.PADDLE_PRICE_YEARLY.trim() },
    environment: production ? 'production' : 'sandbox',
    apiBase: production ? 'https://api.paddle.com' : 'https://sandbox-api.paddle.com',
  };
}

/**
 * NR-06 (BACKLOG-02): the Firebase service account for server push, or null
 * when push is off. Parsed here so a malformed value fails closed (no push)
 * rather than at send time.
 */
function pushConfig(env = process.env) {
  if (blank(env.FCM_SERVICE_ACCOUNT)) return null;
  let account;
  try {
    account = JSON.parse(env.FCM_SERVICE_ACCOUNT);
  } catch {
    return null;
  }
  if (!account || typeof account !== 'object') return null;
  const projectId = account.project_id;
  const clientEmail = account.client_email;
  const privateKey = typeof account.private_key === 'string'
    ? account.private_key.replace(/\\n/g, '\n')
    : null;
  if (blank(projectId) || blank(clientEmail) || blank(privateKey)) return null;
  return { projectId: String(projectId), clientEmail: String(clientEmail), privateKey };
}

/** P20-78: Umami settings, or null when analytics is off. */
function analyticsConfig(env = process.env) {
  if (blank(env.UMAMI_URL) || blank(env.UMAMI_WEBSITE_ID)) return null;
  return { url: env.UMAMI_URL.trim().replace(/\/+$/, ''), websiteId: env.UMAMI_WEBSITE_ID.trim() };
}

/**
 * SP-22: where the owner is told about every student application
 * (`STUDENT_ADMIN_EMAIL`), or null when unset (no notification, logged).
 */
function studentAdminEmail(env = process.env) {
  return blank(env.STUDENT_ADMIN_EMAIL) ? null : env.STUDENT_ADMIN_EMAIL.trim();
}

/**
 * Phase 21: yearly renewal of the student grant. Off (the default): one
 * grant per person, ever, and on expiry the account drops to Free.
 */
function studentRenewalEnabled(env = process.env) {
  return env.STUDENT_RENEWAL_ENABLED === 'true';
}

/**
 * US-PROMO-01: one `PROMO_CODES` entry as the server uses it, or a sentence
 * saying what is wrong with it. `code` is normalized (trimmed, upper case);
 * a date-only `expiresAt` is usable through the end of that UTC day.
 *
 * US-PROMO-04: an entry is one kind of offer — `days` for free Pro time, or
 * `discountId` for a Paddle discount taken off a website checkout.
 */
const PROMO_CODE_PATTERN = /^[A-Za-z0-9_-]{3,64}$/;
const PROMO_DISCOUNT_PATTERN = /^dsc_[A-Za-z0-9]{4,64}$/;
const PROMO_MAX_DAYS = 3650;

function readPromoEntry(entry, index) {
  const at = `entry ${index + 1}`;
  if (!entry || typeof entry !== 'object' || Array.isArray(entry)) {
    return `${at} must be an object like { "code": "LAUNCH30", "days": 30 } or { "code": "SAVE20", "discountId": "dsc_..." }`;
  }
  const code = typeof entry.code === 'string' ? entry.code.trim() : '';
  if (!PROMO_CODE_PATTERN.test(code)) {
    return `${at} needs a code of 3-64 letters, digits, "_" or "-"`;
  }
  // One kind or the other: `days` adds Pro time, `discountId` takes a
  // percentage off a checkout. A code that did both would need a rule for
  // which happens when, so it is refused instead.
  const hasDays = entry.days !== undefined && entry.days !== null;
  const hasDiscount = entry.discountId !== undefined && entry.discountId !== null && entry.discountId !== '';
  if (hasDays === hasDiscount) {
    return `${at} needs either days (Pro time) or discountId (a Paddle discount), not both`;
  }
  let days = null;
  if (hasDays) {
    if (!Number.isInteger(entry.days) || entry.days < 1 || entry.days > PROMO_MAX_DAYS) {
      return `${at} needs days as a whole number from 1 to ${PROMO_MAX_DAYS}`;
    }
    days = entry.days;
  }
  let discountId = null;
  if (hasDiscount) {
    const raw = String(entry.discountId).trim();
    if (!PROMO_DISCOUNT_PATTERN.test(raw)) {
      return `${at} has a discountId that is not a Paddle discount id (dsc_...)`;
    }
    discountId = raw;
  }
  let maxRedemptions = null;
  if (entry.maxRedemptions !== undefined && entry.maxRedemptions !== null) {
    // Paddle counts the redemptions of its own discount; a second counter here
    // would only disagree with it, so a cap on a discount code is refused.
    if (discountId) {
      return `${at} sets maxRedemptions on a discount code; set the cap on the Paddle discount instead`;
    }
    if (!Number.isInteger(entry.maxRedemptions) || entry.maxRedemptions < 1) {
      return `${at} has a maxRedemptions that is not a positive whole number`;
    }
    maxRedemptions = entry.maxRedemptions;
  }
  let expiresAt = null;
  if (entry.expiresAt !== undefined && entry.expiresAt !== null && entry.expiresAt !== '') {
    const raw = String(entry.expiresAt).trim();
    const dateOnly = /^\d{4}-\d{2}-\d{2}$/.test(raw);
    const parsed = new Date(dateOnly ? `${raw}T23:59:59.999Z` : raw);
    if (Number.isNaN(parsed.getTime())) return `${at} has an expiresAt that is not a date`;
    expiresAt = parsed;
  }
  return { code: code.toUpperCase(), days, discountId, maxRedemptions, expiresAt };
}

/** Why `PROMO_CODES` can't be used, or null. Names only, never a value. */
function promoCodeProblems(env = process.env) {
  if (blank(env.PROMO_CODES)) return null;
  let parsed;
  try {
    parsed = JSON.parse(env.PROMO_CODES);
  } catch {
    return 'PROMO_CODES must be JSON: a list of { "code", "days" } or { "code", "discountId" }';
  }
  if (!Array.isArray(parsed)) {
    return 'PROMO_CODES must be JSON: a list of { "code", "days" } or { "code", "discountId" }';
  }
  const seen = new Set();
  for (const [index, entry] of parsed.entries()) {
    const read = readPromoEntry(entry, index);
    if (typeof read === 'string') return `PROMO_CODES: ${read}`;
    if (seen.has(read.code)) return `PROMO_CODES lists ${read.code} twice`;
    seen.add(read.code);
  }
  return null;
}

/**
 * US-PROMO-01: the promo / voucher codes from `PROMO_CODES`, normalized. Empty
 * when unset (the feature is off) or unusable (the server refuses to start
 * through `invalidConfig`, so this never runs in a live deployment). Cached on
 * the raw value, so tests that change it get a fresh answer.
 */
let promoCache = { raw: null, codes: [] };

function promoCodes(env = process.env) {
  const raw = String(env.PROMO_CODES ?? '').trim();
  if (raw === promoCache.raw) return promoCache.codes;
  if (promoCodeProblems(env)) {
    promoCache = { raw, codes: [] };
    return promoCache.codes;
  }
  const codes = raw ? JSON.parse(raw).map((entry, index) => readPromoEntry(entry, index)) : [];
  promoCache = { raw, codes };
  return codes;
}

const DEV_RESET_PASSWORD_URL = 'http://localhost:3000/reset-password';
const DEV_SITE_URL = 'http://localhost:3000';

/**
 * PE-01: the website's base address, for the links the app opens from
 * About JobTrigger (privacy policy, terms). Unset means the local website
 * (`npm run dev` in JobTrigger-Web); `scripts/seedAppInfo.js` refuses that
 * default in production. No trailing slash.
 */
function siteUrl(env = process.env) {
  return blank(env.SITE_URL) ? DEV_SITE_URL : env.SITE_URL.trim().replace(/\/+$/, '');
}

/**
 * P20-73: the website page reset links point to. A password is reset on
 * the web only (US-AUTH-08), so this is the email's one link. Unset means
 * the local website (`npm run dev` in JobTrigger-Web); production must set
 * it whenever mail is on (invalidConfig).
 */
function resetPasswordUrl(env = process.env) {
  return blank(env.RESET_PASSWORD_URL) ? DEV_RESET_PASSWORD_URL : env.RESET_PASSWORD_URL.trim();
}

/**
 * A problem with configuration that is present but unusable, or null:
 * the encryption keys (AUD-03), `TRUST_PROXY` (AUD-44), SMTP (P20-72),
 * or the reset link base (P20-73).
 */
/** A host that only exists on a development machine or private network. */
function isDevHost(hostname) {
  const host = String(hostname || '').toLowerCase().replace(/^\[|\]$/g, '').replace(/\.$/, '');
  if (!host || host === 'localhost' || host === 'host.docker.internal') return true;
  if (/\.(local|lan|home|internal|localhost)$/.test(host)) return true;
  if (/^(127\.|10\.|192\.168\.|169\.254\.|0\.)/.test(host)) return true;
  if (/^172\.(1[6-9]|2\d|3[01])\./.test(host)) return true;
  if (host === '::1' || /^f[cd][0-9a-f]{2}:/.test(host) || /^fe80:/.test(host)) return true;
  return !host.includes('.') && !host.includes(':'); // a bare machine or Docker service name
}

/** True when `value` is an https:// URL on a public host. */
function isPublicHttps(value) {
  try {
    const url = new URL(String(value).trim());
    return url.protocol === 'https:' && !isDevHost(url.hostname);
  } catch {
    return false;
  }
}

/**
 * Pre-release audit 2026-11-20: production must not inherit development
 * values. The development lab sets CORS_ORIGINS to the local website, a
 * GlitchTip DSN on the Mac, and short throwaway secrets; each starts fine in
 * production and fails silently later (a browser blocked, crash reports
 * lost, a guessable JWT key). Names only in the message, never a value.
 */
function productionProblem(env) {
  if (env.NODE_ENV !== 'production') return null;
  if (!blank(env.JWT_SECRET) && env.JWT_SECRET.trim().length < 32) {
    return 'JWT_SECRET must be at least 32 characters in production';
  }
  const devOrigin = corsOrigins(env).find((origin) => !isPublicHttps(origin));
  if (devOrigin !== undefined) {
    return 'CORS_ORIGINS must only list https:// public origins in production (no localhost or LAN)';
  }
  // Mail from a .local sender is rejected or filed as spam by real inboxes.
  if (!blank(env.SMTP_HOST)) {
    const from = String(env.MAIL_FROM ?? '');
    const domain = (/@([^\s>]+)>?\s*$/.exec(from) || [])[1] || '';
    if (blank(env.MAIL_FROM) || isDevHost(domain)) {
      return 'MAIL_FROM must be set to a real sender (e.g. JobTrigger <no-reply@jobtrigger.app>) in production when SMTP_HOST is set';
    }
  }
  for (const name of ['SITE_URL', 'SENTRY_DSN', 'UMAMI_URL']) {
    if (!blank(env[name]) && !isPublicHttps(env[name])) {
      return `${name} must be an https:// URL on a public host in production`;
    }
  }
  return null;
}

function invalidConfig(env = process.env) {
  if (trustProxyHops(env) === undefined) {
    return 'TRUST_PROXY must be the number of proxy hops in front of the server (e.g. 1)';
  }
  const mail = mailProblem(env);
  if (mail) return mail;
  if (!blank(env.BILLING_ENABLED) && !['true', 'false'].includes(env.BILLING_ENABLED)) {
    return 'BILLING_ENABLED must be true or false';
  }
  if (!blank(env.SANDBOX_BILLING) && !['true', 'false'].includes(env.SANDBOX_BILLING)) {
    return 'SANDBOX_BILLING must be true or false';
  }
  if (env.SANDBOX_BILLING === 'true' && env.NODE_ENV === 'production') {
    return 'SANDBOX_BILLING must never be enabled in production';
  }
  if (!blank(env.PADDLE_ENV) && !['sandbox', 'production'].includes(env.PADDLE_ENV)) {
    return 'PADDLE_ENV must be sandbox or production';
  }
  const paddleSet = PADDLE_VARS.filter((name) => !blank(env[name]));
  if (paddleSet.length > 0 && paddleSet.length < PADDLE_VARS.length) {
    return `Paddle needs all of ${PADDLE_VARS.join(', ')}`;
  }
  // P20-17: plans with no way to learn about purchases would lock paying
  // users out, so refuse to start half-configured. The development sandbox
  // is a valid source: it writes purchases itself and charges nothing.
  if (billingEnabled(env) && !revenueCatConfig(env) && !paddleConfig(env) && !sandboxBillingEnabled(env)) {
    return 'BILLING_ENABLED=true needs RevenueCat (REVENUECAT_SECRET_API_KEY, '
      + 'REVENUECAT_WEBHOOK_AUTH), Paddle (PADDLE_API_KEY, PADDLE_WEBHOOK_SECRET, prices) '
      + 'or the development sandbox (SANDBOX_BILLING=true)';
  }
  if (!blank(env.TEAM_PLAN_ENABLED) && !['true', 'false'].includes(env.TEAM_PLAN_ENABLED)) {
    return 'TEAM_PLAN_ENABLED must be true or false';
  }
  if (!blank(env.STUDENT_RENEWAL_ENABLED) && !['true', 'false'].includes(env.STUDENT_RENEWAL_ENABLED)) {
    return 'STUDENT_RENEWAL_ENABLED must be true or false';
  }
  if (!blank(env.STUDENT_ADMIN_EMAIL) && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(env.STUDENT_ADMIN_EMAIL.trim())) {
    return 'STUDENT_ADMIN_EMAIL must be an email address';
  }
  const promo = promoCodeProblems(env);
  if (promo) return promo;
  if (!blank(env.PROMO_REDEEM_RATE_LIMIT) && !/^[1-9][0-9]{0,3}$/.test(env.PROMO_REDEEM_RATE_LIMIT.trim())) {
    return 'PROMO_REDEEM_RATE_LIMIT must be a whole number of requests';
  }
  if (!blank(env.MIN_SUPPORTED_APP_VERSION) && !/^\d+\.\d+\.\d+$/.test(env.MIN_SUPPORTED_APP_VERSION.trim())) {
    return 'MIN_SUPPORTED_APP_VERSION must look like 1.0.1';
  }
  if (!blank(env.SUPPORT_EMAIL) && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(env.SUPPORT_EMAIL.trim())) {
    return 'SUPPORT_EMAIL must be an email address';
  }
  if (!blank(env.RESET_PASSWORD_URL) && !/^https?:\/\/[^\s?#]+$/.test(env.RESET_PASSWORD_URL.trim())) {
    return 'RESET_PASSWORD_URL must be an http(s) URL without a query string';
  }
  // Emails with a localhost link would reach real people from production.
  if (env.NODE_ENV === 'production' && !blank(env.SMTP_HOST)) {
    if (blank(env.RESET_PASSWORD_URL)) {
      return 'RESET_PASSWORD_URL is required in production when SMTP_HOST is set';
    }
    if (!env.RESET_PASSWORD_URL.trim().startsWith('https://')) {
      return 'RESET_PASSWORD_URL must be https:// in production';
    }
  }
  if (!blank(env.SITE_URL) && !/^https?:\/\/[^\s/?#]+\/*$/.test(env.SITE_URL.trim())) {
    return 'SITE_URL must be an http(s) origin, e.g. https://jobtrigger.app (no path or query)';
  }
  if (!blank(env.UMAMI_URL) && !/^https?:\/\/\S+$/.test(env.UMAMI_URL.trim())) {
    return 'UMAMI_URL must be an http(s) URL';
  }
  const production = productionProblem(env);
  if (production) return production;
  if (!env.CREDENTIALS_ENCRYPTION_KEY) return null; // Reported as missing.
  try {
    loadKeys(env);
    return null;
  } catch (err) {
    return err.message;
  }
}

/**
 * E3 / PE-20: crash reporting (GlitchTip through the Sentry SDK), or null
 * when SENTRY_DSN is unset (off: tests and local development send nothing).
 * `environment` is `production` or `development`; `release` is the
 * package version, or SENTRY_RELEASE when the deploy sets one.
 */
function errorReportingConfig(env = process.env) {
  if (blank(env.SENTRY_DSN)) return null;
  const environment = blank(env.SENTRY_ENVIRONMENT)
    ? env.NODE_ENV === 'production' ? 'production' : 'development'
    : env.SENTRY_ENVIRONMENT.trim();
  const release = blank(env.SENTRY_RELEASE)
    ? `${require('../package.json').version}`
    : env.SENTRY_RELEASE.trim();
  return { dsn: env.SENTRY_DSN.trim(), environment, release };
}

module.exports = {
  errorReportingConfig,
  missingConfig,
  invalidConfig,
  corsOrigins,
  trustProxyHops,
  mailConfig,
  analyticsConfig,
  pushConfig,
  resetPasswordUrl,
  siteUrl,
  studentAdminEmail,
  studentRenewalEnabled,
  promoCodes,
  billingEnabled,
  sandboxBillingEnabled,
  teamPlanEnabled,
  paddleTeamPrices,
  revenueCatConfig,
  paddleConfig,
};
