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
 * A problem with configuration that is present but unusable (AUD-03: the
 * encryption keys), or null.
 */
function invalidConfig(env = process.env) {
  if (!env.CREDENTIALS_ENCRYPTION_KEY) return null; // Reported as missing.
  try {
    loadKeys(env);
    return null;
  } catch (err) {
    return err.message;
  }
}

module.exports = { missingConfig, invalidConfig, corsOrigins };
