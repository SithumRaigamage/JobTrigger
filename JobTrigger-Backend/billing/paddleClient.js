/**
 * Paddle Billing API (website checkout), with Node's built-in fetch.
 * Injectable so tests never reach the network. The API key never leaves
 * this server and is never logged.
 */
const { paddleConfig } = require('../config/env');

const TIMEOUT_MS = 10000;

async function call(method, path, body) {
  const config = paddleConfig();
  if (!config) throw new Error('Paddle is not configured');
  const res = await fetch(`${config.apiBase}${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${config.apiKey}`,
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
    body: body === undefined ? undefined : JSON.stringify(body),
    signal: AbortSignal.timeout(TIMEOUT_MS),
  });
  if (!res.ok) throw new Error(`Paddle HTTP ${res.status}`);
  return res.json();
}

const realClient = {
  /**
   * A checkout transaction for one Pro price. `custom_data.userId` is set
   * here, on the server, so a browser can't attach a purchase to another
   * account; Paddle copies it to the subscription the checkout creates.
   */
  async createTransaction({ priceId, userId }) {
    const { data } = await call('POST', '/transactions', {
      items: [{ price_id: priceId, quantity: 1 }],
      custom_data: { userId: String(userId) },
    });
    return { transactionId: data.id };
  },

  /** A one-time link to Paddle's customer portal (card, invoices, cancel). */
  async createPortalSession({ customerId, subscriptionId }) {
    const { data } = await call('POST', `/customers/${encodeURIComponent(customerId)}/portal-sessions`, {
      ...(subscriptionId ? { subscription_ids: [subscriptionId] } : {}),
    });
    return { url: data?.urls?.general?.overview };
  },

  /** Cancels at the end of the paid period (account deletion). */
  async cancelSubscription({ subscriptionId }) {
    await call('POST', `/subscriptions/${encodeURIComponent(subscriptionId)}/cancel`, {
      effective_from: 'next_billing_period',
    });
  },
};

let client = realClient;

/** Tests: a fake with the same methods, or null to restore. */
function setPaddleClientForTests(fake) {
  client = fake ?? realClient;
}

module.exports = {
  createTransaction: (args) => client.createTransaction(args),
  createPortalSession: (args) => client.createPortalSession(args),
  cancelSubscription: (args) => client.cancelSubscription(args),
  setPaddleClientForTests,
};
