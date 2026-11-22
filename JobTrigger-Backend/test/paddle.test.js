const crypto = require('crypto');
const { api } = require('./support/api');
const { expect } = require('chai');
const Subscription = require('../models/Subscription');
const { verifySignature, fromPaddleSubscription, PAST_DUE_GRACE_MS } = require('../billing/paddle');
const { derive } = require('../billing/combine');
const { setPaddleClientForTests } = require('../billing/paddleClient');
const { setRevenueCatClientForTests } = require('../billing/revenuecatClient');
const { invalidConfig } = require('../config/env');

const SECRET = 'pdl_ntfset_test_secret';
const DAY = 24 * 60 * 60 * 1000;

const sign = (raw, { ts = Math.floor(Date.now() / 1000), secret = SECRET } = {}) =>
  `ts=${ts};h1=${crypto.createHmac('sha256', secret).update(`${ts}:${raw}`).digest('hex')}`;

let counter = 0;
async function signup() {
  counter += 1;
  const email = `paddle${counter}@example.com`;
  const res = await api().post('/api/auth/signup').send({ email, password: 'password' });
  return { ...res.body, email, id: res.body.user._id };
}
const authed = (method, path, token) => api()[method](path).set('x-auth-token', token);

function enablePaddle() {
  process.env.BILLING_ENABLED = 'true';
  process.env.PADDLE_API_KEY = 'pdl_sdbx_apikey';
  process.env.PADDLE_WEBHOOK_SECRET = SECRET;
  process.env.PADDLE_PRICE_MONTHLY = 'pri_monthly';
  process.env.PADDLE_PRICE_YEARLY = 'pri_yearly';
}
function disableAll() {
  for (const name of ['BILLING_ENABLED', 'PADDLE_API_KEY', 'PADDLE_WEBHOOK_SECRET', 'PADDLE_PRICE_MONTHLY',
    'PADDLE_PRICE_YEARLY', 'REVENUECAT_SECRET_API_KEY', 'REVENUECAT_WEBHOOK_AUTH']) {
    process.env[name] = '';
  }
}

/** A Paddle subscription entity. */
function paddleSub({ userId, status = 'active', id = 'sub_01', endsAt = new Date(Date.now() + 30 * DAY), ...extra } = {}) {
  return {
    id,
    status,
    customer_id: 'ctm_01',
    custom_data: userId ? { userId } : null,
    current_billing_period: { starts_at: new Date().toISOString(), ends_at: endsAt.toISOString() },
    items: [{ price: { id: 'pri_yearly' } }],
    ...extra,
  };
}

describe('Paddle webhook signature', function() {
  const raw = Buffer.from('{"event_id":"evt_1"}');

  it('accepts a correct, fresh signature', function() {
    expect(verifySignature(raw, sign(raw), SECRET)).to.equal(true);
  });

  it('refuses a wrong secret, a changed body, an old timestamp or junk', function() {
    expect(verifySignature(raw, sign(raw, { secret: 'other' }), SECRET)).to.equal(false);
    expect(verifySignature(Buffer.from('{"event_id":"evt_2"}'), sign(raw), SECRET)).to.equal(false);
    expect(verifySignature(raw, sign(raw, { ts: Math.floor(Date.now() / 1000) - 3600 }), SECRET)).to.equal(false);
    expect(verifySignature(raw, 'nonsense', SECRET)).to.equal(false);
    expect(verifySignature(raw, undefined, SECRET)).to.equal(false);
    expect(verifySignature('not a buffer', sign(raw), SECRET)).to.equal(false);
  });
});

describe('Paddle subscription mapping', function() {
  const now = new Date('2026-11-12T00:00:00Z');
  const ends = new Date('2026-12-12T00:00:00Z');

  it('maps active, trialing and a scheduled cancellation', function() {
    expect(fromPaddleSubscription(paddleSub({ endsAt: ends }), now))
      .to.include({ plan: 'pro', status: 'active', source: 'web', willRenew: true, paddleCustomerId: 'ctm_01' });
    expect(fromPaddleSubscription(paddleSub({ status: 'trialing', endsAt: ends }), now)).to.include({ status: 'trialing' });
    const cancelling = paddleSub({ endsAt: ends, scheduled_change: { action: 'cancel', effective_at: ends.toISOString() } });
    expect(fromPaddleSubscription(cancelling, now)).to.include({ plan: 'pro', status: 'cancelled', willRenew: false });
  });

  it('keeps Pro for a grace period while past due, then Free when paused or canceled', function() {
    const pastDue = fromPaddleSubscription(paddleSub({ status: 'past_due', endsAt: new Date(now.getTime() - DAY) }), now);
    expect(pastDue).to.include({ plan: 'pro', status: 'billing_issue' });
    expect(pastDue.periodEnd.getTime()).to.equal(now.getTime() + PAST_DUE_GRACE_MS);
    expect(fromPaddleSubscription(paddleSub({ status: 'paused' }), now)).to.include({ plan: 'free', status: 'expired' });
    expect(fromPaddleSubscription(paddleSub({ status: 'canceled' }), now)).to.include({ plan: 'free', status: 'expired' });
  });
});

describe('Combining web, store and grants', function() {
  const now = new Date('2026-11-12T00:00:00Z');
  const proUntil = (days, source) => ({
    plan: 'pro', status: 'active', source, periodEnd: new Date(now.getTime() + days * DAY), willRenew: true,
  });

  it('never lets an empty store record cancel a web subscription', function() {
    const doc = { store: { plan: 'free', status: 'none' }, web: proUntil(30, 'web') };
    expect(derive(doc, now)).to.include({ plan: 'pro', source: 'web' });
  });

  it('picks the Pro source that lasts longer', function() {
    expect(derive({ store: proUntil(5, 'app_store'), web: proUntil(30, 'web') }, now).source).to.equal('web');
    expect(derive({ web: proUntil(30, 'web'), grant: { ...proUntil(0, 'admin'), periodEnd: null } }, now).source)
      .to.equal('admin');
  });

  it('keeps a legacy top-level admin grant', function() {
    expect(derive({ plan: 'pro', status: 'active', source: 'admin', periodEnd: null }, now))
      .to.include({ plan: 'pro', source: 'admin' });
  });

  it('shows an ended subscription as expired, and nothing as none', function() {
    expect(derive({ web: { plan: 'free', status: 'expired', source: 'web', periodEnd: now } }, now))
      .to.include({ plan: 'free', status: 'expired', source: 'web' });
    expect(derive({}, now)).to.include({ plan: 'free', status: 'none' });
  });
});

describe('Paddle configuration', function() {
  it('needs every Paddle variable or none', function() {
    expect(invalidConfig({ PADDLE_API_KEY: 'k' })).to.match(/Paddle needs all of/);
    expect(invalidConfig({ PADDLE_ENV: 'live' })).to.match(/sandbox or production/);
    expect(invalidConfig({
      BILLING_ENABLED: 'true', PADDLE_API_KEY: 'k', PADDLE_WEBHOOK_SECRET: 's',
      PADDLE_PRICE_MONTHLY: 'pri_m', PADDLE_PRICE_YEARLY: 'pri_y',
    })).to.equal(null); // Paddle alone is enough to turn billing on
  });
});

describe('Paddle webhook (website checkout)', function() {
  beforeEach(enablePaddle);
  afterEach(disableAll);

  let n = 0;
  const deliver = (type, data, { occurredAt = new Date(), secret = SECRET } = {}) => {
    n += 1;
    const raw = JSON.stringify({ event_id: `evt_${n}_${Date.now()}`, event_type: type, occurred_at: occurredAt.toISOString(), data });
    return api().post('/api/billing/paddle/webhook')
      .set('Content-Type', 'application/json')
      .set('Paddle-Signature', sign(raw, { secret }))
      .send(raw);
  };

  it('refuses a bad signature and stores nothing', async function() {
    const me = await signup();
    expect((await deliver('subscription.created', paddleSub({ userId: me.id }), { secret: 'wrong' })).status)
      .to.equal(401);
    expect(await Subscription.exists({ userId: me.id })).to.equal(null);
  });

  it('turns a web purchase into Pro for the account in the checkout', async function() {
    const me = await signup();
    expect((await deliver('subscription.created', paddleSub({ userId: me.id }))).status).to.equal(200);
    const res = await authed('get', '/api/subscription', me.token);
    expect(res.body).to.include({ plan: 'pro', status: 'active', source: 'web', manageOnWeb: true });
    expect(res.body.limits.maxCredentialsTotal).to.equal(null);
  });

  it('finds the account by subscription id when custom data is missing', async function() {
    const me = await signup();
    await deliver('subscription.created', paddleSub({ userId: me.id, id: 'sub_lookup' }));
    await deliver('subscription.canceled', paddleSub({ id: 'sub_lookup', status: 'canceled' }));
    expect((await authed('get', '/api/subscription', me.token)).body).to.include({ plan: 'free', status: 'expired' });
  });

  it('ignores an older event that arrives late', async function() {
    const me = await signup();
    const later = new Date();
    await deliver('subscription.canceled', paddleSub({ userId: me.id, status: 'canceled' }), { occurredAt: later });
    const stale = await deliver('subscription.updated', paddleSub({ userId: me.id }), {
      occurredAt: new Date(later.getTime() - 60000),
    });
    expect(stale.body.stale).to.equal(true);
    expect((await authed('get', '/api/subscription', me.token)).body.plan).to.equal('free');
  });

  it('keeps a web subscription when the app store has nothing', async function() {
    const me = await signup();
    await deliver('subscription.created', paddleSub({ userId: me.id }));
    process.env.REVENUECAT_SECRET_API_KEY = 'sk';
    process.env.REVENUECAT_WEBHOOK_AUTH = 'w';
    setRevenueCatClientForTests({ getSubscriber: async () => ({ subscriber: { entitlements: {} } }), deleteSubscriber: async () => {} });
    try {
      const res = await authed('post', '/api/subscription/refresh', me.token);
      expect(res.body).to.include({ plan: 'pro', source: 'web' });
    } finally {
      setRevenueCatClientForTests(null);
    }
  });

  it('acknowledges other event types without changes', async function() {
    const res = await deliver('transaction.completed', { id: 'txn_1' });
    expect(res.status).to.equal(200);
    expect(res.body.ignored).to.equal(true);
  });
});

describe('Paddle checkout and portal', function() {
  let created;
  beforeEach(function() {
    enablePaddle();
    created = [];
    setPaddleClientForTests({
      createTransaction: async (args) => { created.push(args); return { transactionId: 'txn_123' }; },
      createPortalSession: async () => ({ url: 'https://customer-portal.paddle.com/cpl_1' }),
      cancelSubscription: async () => {},
    });
  });
  afterEach(function() {
    disableAll();
    setPaddleClientForTests(null);
  });

  it('creates a transaction for the chosen price, tied to the caller on the server', async function() {
    const me = await signup();
    const res = await authed('post', '/api/billing/paddle/checkout', me.token).send({ interval: 'yearly', userId: 'someone-else' });
    expect(res.status).to.equal(200);
    expect(res.body).to.deep.equal({ transactionId: 'txn_123', environment: 'sandbox' });
    expect(created).to.deep.equal([{ priceId: 'pri_yearly', userId: me.id }]);
  });

  it('applies a discount code to the transaction, and refuses a bad one before Paddle (US-PROMO-04)', async function() {
    process.env.PROMO_CODES = JSON.stringify([
      { code: 'SAVE20', discountId: 'dsc_0123456789abcdef' },
      { code: 'OLD20', discountId: 'dsc_abcdef0123456789', expiresAt: '2020-01-01' },
      { code: 'LAUNCH30', days: 30 },
    ]);
    try {
      const me = await signup();
      const ok = await authed('post', '/api/billing/paddle/checkout', me.token)
        .send({ interval: 'yearly', code: '  save20 ' });
      expect(ok.status).to.equal(200);
      expect(created).to.have.length(1);
      expect(created[0].discountId).to.equal('dsc_0123456789abcdef');

      // Expired, unknown, and a Pro-time code: one neutral sentence, no
      // transaction, so nothing is charged at a price the buyer didn't see.
      for (const code of ['OLD20', 'NOPE', 'LAUNCH30']) {
        const res = await authed('post', '/api/billing/paddle/checkout', me.token)
          .send({ interval: 'yearly', code });
        expect(res.status).to.equal(400);
        expect(res.body.code).to.equal('invalid_code');
        expect(res.body.message).to.equal("That code isn't valid, or it has expired.");
      }
      expect(created).to.have.length(1);
    } finally {
      process.env.PROMO_CODES = '';
    }
  });

  it('refuses a second subscription, whichever store the first is from', async function() {
    const me = await signup();
    await Subscription.create({ userId: me.id, plan: 'pro', status: 'active', source: 'app_store' });
    const res = await authed('post', '/api/billing/paddle/checkout', me.token).send({ interval: 'monthly' });
    expect(res.status).to.equal(409);
    expect(res.body.code).to.equal('ALREADY_SUBSCRIBED');
    expect(created).to.deep.equal([]);
  });

  it('checks the interval and needs a session', async function() {
    const me = await signup();
    expect((await authed('post', '/api/billing/paddle/checkout', me.token).send({ interval: 'weekly' })).status).to.equal(400);
    expect((await api().post('/api/billing/paddle/checkout').send({ interval: 'monthly' })).status).to.equal(401);
  });

  it('is unavailable while billing is off', async function() {
    const me = await signup();
    process.env.BILLING_ENABLED = '';
    expect((await authed('post', '/api/billing/paddle/checkout', me.token).send({ interval: 'monthly' })).status).to.equal(503);
  });

  it('opens the portal only for a web subscriber', async function() {
    const me = await signup();
    expect((await authed('post', '/api/billing/paddle/portal', me.token)).status).to.equal(404);
    await Subscription.create({ userId: me.id, web: { plan: 'pro', status: 'active', source: 'web', paddleCustomerId: 'ctm_9', paddleSubscriptionId: 'sub_9' } });
    const res = await authed('post', '/api/billing/paddle/portal', me.token);
    expect(res.status).to.equal(200);
    expect(res.body.url).to.match(/^https:\/\/customer-portal\.paddle\.com\//);
  });

  it('blocks deleting an account while a web subscription is renewing (changes.md §4)', async function() {
    const cancelled = [];
    setPaddleClientForTests({
      createTransaction: async () => ({}), createPortalSession: async () => ({}),
      cancelSubscription: async ({ subscriptionId }) => { cancelled.push(subscriptionId); },
    });
    const me = await signup();
    await Subscription.create({ userId: me.id, web: { plan: 'pro', status: 'active', source: 'web', willRenew: true, paddleSubscriptionId: 'sub_del', paddleCustomerId: 'ctm_d' } });
    const res = await authed('delete', '/api/auth/account', me.token).send({ password: 'password' });
    expect(res.status).to.equal(403);
    expect(res.body.code).to.equal('SUBSCRIPTION_ACTIVE');
    expect(res.body.message).to.match(/website/i);
    expect(cancelled).to.deep.equal([]);
    // After cancelling in the website portal, deletion is allowed.
    await Subscription.updateOne({ userId: me.id }, { $set: { 'web.willRenew': false } });
    expect((await authed('delete', '/api/auth/account', me.token).send({ password: 'password' })).status).to.equal(200);
  });

  it('still cancels a renewing web subscription at deletion when it is past its period (P20-18 safety net)', async function() {
    const cancelled = [];
    setPaddleClientForTests({
      createTransaction: async () => ({}), createPortalSession: async () => ({}),
      cancelSubscription: async ({ subscriptionId }) => { cancelled.push(subscriptionId); },
    });
    const me = await signup();
    // 'expired' is not a Pro-granting status, so it does not block deletion,
    // but willRenew is still true — the safety net cancels it.
    await Subscription.create({ userId: me.id, web: { plan: 'pro', status: 'expired', source: 'web', willRenew: true, paddleSubscriptionId: 'sub_exp', paddleCustomerId: 'ctm_e' } });
    expect((await authed('delete', '/api/auth/account', me.token).send({ password: 'password' })).status).to.equal(200);
    expect(cancelled).to.deep.equal(['sub_exp']);
  });
});
