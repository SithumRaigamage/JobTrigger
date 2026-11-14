/**
 * Paddle webhooks: signature check and subscription mapping. Pure, so the
 * rules are unit-tested without a database or the network.
 */
const crypto = require('crypto');

/** How old a signed delivery may be (clock skew allowance). */
const SIGNATURE_TOLERANCE_S = 300;
/** Pro is kept this long past the period while Paddle retries a failed charge. */
const PAST_DUE_GRACE_MS = 14 * 24 * 60 * 60 * 1000;

/**
 * Whether [header] (`Paddle-Signature: ts=…;h1=…`) signs [rawBody] with
 * [secret]. Paddle signs `${ts}:${rawBody}` with HMAC-SHA256; the body
 * must be the exact bytes received, not re-serialised JSON.
 */
function verifySignature(rawBody, header, secret, { nowS = Math.floor(Date.now() / 1000) } = {}) {
  if (!Buffer.isBuffer(rawBody) || typeof header !== 'string' || !secret) return false;
  const parts = Object.fromEntries(
    header.split(';').map((part) => part.split('=')).filter((kv) => kv.length === 2),
  );
  const ts = Number(parts.ts);
  if (!Number.isInteger(ts) || !/^[a-f0-9]{64}$/.test(parts.h1 ?? '')) return false;
  if (Math.abs(nowS - ts) > SIGNATURE_TOLERANCE_S) return false;
  const expected = crypto.createHmac('sha256', secret)
    .update(`${ts}:`)
    .update(rawBody)
    .digest();
  return crypto.timingSafeEqual(expected, Buffer.from(parts.h1, 'hex'));
}

const date = (value) => (value ? new Date(value) : null);

/**
 * The `web` source fields for a Paddle subscription entity at [now].
 *
 * - `trialing` / `active`: Pro to the end of the billing period;
 *   `cancelled` when a cancellation is scheduled (auto-renew off).
 * - `past_due`: Pro for a grace period while Paddle retries the charge.
 * - `paused` / `canceled`: Free.
 */
function fromPaddleSubscription(sub, now = new Date()) {
  const periodEnd = date(sub?.current_billing_period?.ends_at) ?? date(sub?.next_billed_at);
  const base = {
    source: 'web',
    productId: sub?.items?.[0]?.price?.id ?? null,
    paddleSubscriptionId: sub?.id ?? null,
    paddleCustomerId: sub?.customer_id ?? null,
  };
  const cancelling = sub?.scheduled_change?.action === 'cancel';
  switch (sub?.status) {
    case 'trialing':
    case 'active':
      return {
        ...base,
        plan: 'pro',
        status: cancelling ? 'cancelled' : sub.status === 'trialing' ? 'trialing' : 'active',
        periodEnd: cancelling ? date(sub.scheduled_change.effective_at) ?? periodEnd : periodEnd,
        willRenew: !cancelling,
      };
    case 'past_due': {
      const from = periodEnd && periodEnd > now ? periodEnd : now;
      return {
        ...base,
        plan: 'pro',
        status: 'billing_issue',
        periodEnd: new Date(from.getTime() + PAST_DUE_GRACE_MS),
        willRenew: true,
      };
    }
    case 'paused':
      return { ...base, plan: 'free', status: 'expired', periodEnd: date(sub.paused_at) ?? now, willRenew: false };
    case 'canceled':
    default:
      return { ...base, plan: 'free', status: 'expired', periodEnd: date(sub?.canceled_at) ?? now, willRenew: false };
  }
}

module.exports = {
  verifySignature,
  fromPaddleSubscription,
  SIGNATURE_TOLERANCE_S,
  PAST_DUE_GRACE_MS,
};
