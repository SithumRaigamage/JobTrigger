const { api } = require('./support/api');
const { expect } = require('chai');
const Subscription = require('../models/Subscription');
const { invalidConfig } = require('../config/env');

const DAY = 24 * 60 * 60 * 1000;
let counter = 0;

async function signup() {
  counter += 1;
  const email = `sandbox${counter}@example.com`;
  const res = await api().post('/api/auth/signup').send({ email, password: 'password' });
  return { ...res.body, email, id: res.body.user._id };
}
const authed = (method, path, token) => api()[method](path).set('x-auth-token', token);

function enableSandbox() {
  process.env.BILLING_ENABLED = 'true';
  process.env.SANDBOX_BILLING = 'true';
}
function disableSandbox() {
  process.env.BILLING_ENABLED = '';
  process.env.SANDBOX_BILLING = '';
}

describe('Sandbox billing (development only)', function() {
  afterEach(disableSandbox);

  it('is a plain 404 unless SANDBOX_BILLING is on', async function() {
    process.env.BILLING_ENABLED = 'true';
    process.env.SANDBOX_BILLING = '';
    const me = await signup();
    const res = await authed('post', '/api/billing/sandbox/purchase', me.token)
      .send({ period: 'monthly' });
    expect(res.status).to.equal(404);
  });

  it('refuses SANDBOX_BILLING in production, and validates the value', function() {
    expect(invalidConfig({ NODE_ENV: 'production', SANDBOX_BILLING: 'true' }))
      .to.match(/never be enabled in production/);
    expect(invalidConfig({ SANDBOX_BILLING: 'yes' })).to.match(/true or false/);
  });

  it('buys monthly on Google Play without calling a store', async function() {
    enableSandbox();
    const me = await signup();
    const res = await authed('post', '/api/billing/sandbox/purchase', me.token)
      .send({ period: 'monthly', platform: 'play_store' });

    expect(res.status).to.equal(200);
    expect(res.headers['cache-control']).to.equal('no-store');
    expect(res.body).to.include({ plan: 'pro', source: 'play_store', status: 'active' });
    expect(Date.parse(res.body.periodEnd)).to.be.greaterThan(Date.now() + 29 * DAY);
    expect(res.body).to.not.have.property('subscription');
  });

  it('starts the yearly plan with its 7-day trial', async function() {
    enableSandbox();
    const me = await signup();
    const res = await authed('post', '/api/billing/sandbox/purchase', me.token)
      .send({ period: 'yearly', platform: 'app_store' });

    expect(res.body).to.include({ plan: 'pro', source: 'app_store', status: 'trialing' });
    const left = Date.parse(res.body.periodEnd) - Date.now();
    expect(left).to.be.greaterThan(6 * DAY);
    expect(left).to.be.lessThan(8 * DAY);
  });

  it('cancels but keeps Pro until the period ends, then expires to Free', async function() {
    enableSandbox();
    const me = await signup();
    await authed('post', '/api/billing/sandbox/purchase', me.token)
      .send({ period: 'monthly' });

    const cancelled = await authed('post', '/api/billing/sandbox/cancel', me.token);
    expect(cancelled.status).to.equal(200);
    expect(cancelled.body).to.include({ plan: 'pro', status: 'cancelled', willRenew: false });

    const expired = await authed('post', '/api/billing/sandbox/expire', me.token);
    expect(expired.body.plan).to.equal('free');
    expect(expired.body.status).to.equal('expired');
  });

  it('resubscribes after cancelling and after expiring', async function() {
    enableSandbox();
    const me = await signup();
    await authed('post', '/api/billing/sandbox/purchase', me.token).send({ period: 'monthly' });
    await authed('post', '/api/billing/sandbox/cancel', me.token);

    const resumed = await authed('post', '/api/billing/sandbox/resubscribe', me.token);
    expect(resumed.body).to.include({ plan: 'pro', status: 'active', willRenew: true });

    await authed('post', '/api/billing/sandbox/expire', me.token);
    const again = await authed('post', '/api/billing/sandbox/resubscribe', me.token);
    expect(again.body).to.include({ plan: 'pro', source: 'play_store', status: 'active' });
    expect(Date.parse(again.body.periodEnd)).to.be.greaterThan(Date.now() + 29 * DAY);
  });

  it('refuses a second renewing purchase, and says when there is nothing to act on', async function() {
    enableSandbox();
    const me = await signup();

    expect((await authed('post', '/api/billing/sandbox/cancel', me.token)).status).to.equal(409);
    expect((await authed('post', '/api/billing/sandbox/resubscribe', me.token)).status).to.equal(409);
    expect((await authed('post', '/api/billing/sandbox/expire', me.token)).status).to.equal(409);

    await authed('post', '/api/billing/sandbox/purchase', me.token).send({ period: 'monthly' });
    const twice = await authed('post', '/api/billing/sandbox/purchase', me.token)
      .send({ period: 'yearly' });
    expect(twice.status).to.equal(409);
    expect(twice.body.code).to.equal('ALREADY_SUBSCRIBED');
  });

  it('rejects an unknown period and needs a session', async function() {
    enableSandbox();
    const me = await signup();
    expect((await authed('post', '/api/billing/sandbox/purchase', me.token).send({ period: 'weekly' })).status)
      .to.equal(400);
    expect((await api().post('/api/billing/sandbox/purchase').send({ period: 'monthly' })).status)
      .to.equal(401);
  });

  it('writes the store source only, never touching a web or grant plan', async function() {
    enableSandbox();
    const me = await signup();
    await Subscription.create({
      userId: me.id,
      grant: { plan: 'pro', status: 'active', source: 'admin', willRenew: false },
    });
    await authed('post', '/api/billing/sandbox/purchase', me.token).send({ period: 'monthly' });
    const sub = await Subscription.findOne({ userId: me.id }).lean();
    expect(sub.store).to.include({ plan: 'pro', status: 'active', source: 'play_store' });
    expect(sub.grant).to.include({ plan: 'pro', status: 'active', source: 'admin' });
  });
});
