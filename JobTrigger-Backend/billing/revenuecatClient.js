/**
 * P20-15: RevenueCat's REST API (v1 subscribers), with Node's built-in
 * fetch. Injectable so tests never reach the network. The secret key never
 * leaves this server; it is never logged.
 */
const { revenueCatConfig } = require('../config/env');

const BASE = 'https://api.revenuecat.com/v1';
const TIMEOUT_MS = 10000;

async function request(method, appUserId) {
  const config = revenueCatConfig();
  if (!config) throw new Error('RevenueCat is not configured');
  const res = await fetch(`${BASE}/subscribers/${encodeURIComponent(appUserId)}`, {
    method,
    headers: { Authorization: `Bearer ${config.secretApiKey}`, Accept: 'application/json' },
    signal: AbortSignal.timeout(TIMEOUT_MS),
  });
  if (!res.ok) throw new Error(`RevenueCat HTTP ${res.status}`);
  return method === 'GET' ? res.json() : null;
}

const realClient = {
  /** The subscriber record (`{ subscriber: {...} }`); creates an empty one if new. */
  getSubscriber: (appUserId) => request('GET', appUserId),
  /** Deletes the customer and their purchase history in RevenueCat. */
  deleteSubscriber: (appUserId) => request('DELETE', appUserId),
};

let client = realClient;

/** Tests: a fake with the same two methods, or null to restore. */
function setRevenueCatClientForTests(fake) {
  client = fake ?? realClient;
}

module.exports = {
  getSubscriber: (id) => client.getSubscriber(id),
  deleteSubscriber: (id) => client.deleteSubscriber(id),
  setRevenueCatClientForTests,
};
