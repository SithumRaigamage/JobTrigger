/**
 * E4 (PE-32): how a saved secret is shown in API responses and on the web:
 * "••••" plus its last four characters, so two tokens can be told apart
 * without the response carrying either. Secrets shorter than eight
 * characters show no characters at all. The website applies the same rule
 * (JobTrigger-Web/src/domain/mask.ts) to what it used to receive in full.
 *
 * @param {string|null|undefined} secret
 * @returns {string|null} null when there is no readable secret.
 */
function maskSecret(secret) {
  if (typeof secret !== 'string' || secret === '') return null;
  return secret.length >= 8 ? `••••${secret.slice(-4)}` : '••••';
}

module.exports = { maskSecret };
