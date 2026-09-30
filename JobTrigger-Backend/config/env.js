/**
 * AUD-25: configuration read once at startup.
 */

const REQUIRED = ['JWT_SECRET', 'MONGODB_URI'];

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

module.exports = { missingConfig, corsOrigins };
