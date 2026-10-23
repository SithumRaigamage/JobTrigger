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

/**
 * A problem with configuration that is present but unusable, or null:
 * the encryption keys (AUD-03), or `TRUST_PROXY` (AUD-44).
 */
function invalidConfig(env = process.env) {
  if (trustProxyHops(env) === undefined) {
    return 'TRUST_PROXY must be the number of proxy hops in front of the server (e.g. 1)';
  }
  if (!env.CREDENTIALS_ENCRYPTION_KEY) return null; // Reported as missing.
  try {
    loadKeys(env);
    return null;
  } catch (err) {
    return err.message;
  }
}

module.exports = { missingConfig, invalidConfig, corsOrigins, trustProxyHops };
