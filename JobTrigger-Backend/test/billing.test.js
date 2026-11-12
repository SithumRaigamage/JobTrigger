const { api } = require('./support/api');
const { expect } = require('chai');
const mongoose = require('mongoose');
const Subscription = require('../models/Subscription');
const BillingEvent = require('../models/BillingEvent');
const { setRevenueCatClientForTests } = require('../billing/revenuecatClient');
const { fromSubscriber } = require('../billing/syncSubscription');
const { describe: describePlan, isPro } = require('../billing/entitlements');
const { PRIMARY_COOLDOWN_MS } = require('../controllers/subscriptionController');
const { accountIds } = require('../controllers/billingWebhookController');
const { parseArgs } = require('../scripts/grant-plan');

const WEBHOOK_AUTH = 'test-webhook-secret';
const DAY = 24 * 60 * 60 * 1000;

let counter = 0;
async function signup() {
  counter += 1;
  const email = `billing${counter}@example.com`;
  const res = await api().post('/api/auth/signup').send({ email, password: 'password' });
  return { ...res.body, email, id: res.body.user._id };
}
const authed = (method, path, token) => api()[method](path).set('x-auth-token', token);
const addJenkins = (token, name = 'ci') =>
  authed('post', '/api/credentials', token).send({
    serverName: name, jenkinsURL: 'https://ci.example.com', username: 'u', password: 'p',
  });
const addGitHub = (token) => authed('post', '/api/github-credentials', token).send({ label: 'gh', token: 't' });

function enableBilling() {
  process.env.BILLING_ENABLED = 'true';
  process.env.REVENUECAT_SECRET_API_KEY = 'sk_test';
  process.env.REVENUECAT_WEBHOOK_AUTH = WEBHOOK_AUTH;
}
function disableBilling() {
  process.env.BILLING_ENABLED = '';
  process.env.REVENUECAT_SECRET_API_KEY = '';
  process.env.REVENUECAT_WEBHOOK_AUTH = '';
}

/** A RevenueCat subscriber with an active `pro` entitlement. */
function proSubscriber({ expires = new Date(Date.now() + 30 * DAY), periodType = 'normal', extra = {} } = {}) {
  return {
    entitlements: { pro: { expires_date: expires && expires.toISOString(), product_identifier: 'jobtrigger_pro_yearly' } },
    subscriptions: {
      jobtrigger_pro_yearly: { store: 'app_store', period_type: periodType, expires_date: expires && expires.toISOString(), ...extra },
    },
  };
}

describe('Plans and entitlements (P20-10)', function() {
  it('treats the subscription statuses as Pro only inside the period', function() {
    const now = new Date();
    const later = new Date(now.getTime() + DAY);
    const earlier = new Date(now.getTime() - DAY);
    expect(isPro(null, now)).to.equal(false);
    expect(isPro({ plan: 'pro', status: 'active', periodEnd: later }, now)).to.equal(true);
    expect(isPro({ plan: 'pro', status: 'cancelled', periodEnd: later }, now)).to.equal(true);
    expect(isPro({ plan: 'pro', status: 'active', periodEnd: earlier }, now)).to.equal(false);
    expect(isPro({ plan: 'pro', status: 'active', periodEnd: null }, now)).to.equal(true);
    expect(isPro({ plan: 'pro', status: 'expired', periodEnd: later }, now)).to.equal(false);
  });

  it('gives everyone Pro while billing is off', function() {
    const body = describePlan(null, { enabled: false });
    expect(body.plan).to.equal('pro');
    expect(body.billingEnabled).to.equal(false);
    expect(body.limits.maxCredentialsTotal).to.equal(null);
    expect(body.features.multiTool).to.equal(true);
  });

  it('describes Free with its limits when billing is on', function() {
    const body = describePlan(null, { enabled: true });
    expect(body).to.deep.include({ plan: 'free', status: 'none' });
    expect(body.limits).to.deep.equal({ maxCredentialsTotal: 1, maxCredentialsPerTool: 1, maxPinnedJobs: 3 });
    expect(body.features).to.deep.equal({ multiTool: false, backgroundWatch: false, homeWidget: false, insights: false });
  });
});

describe('RevenueCat subscriber mapping (P20-15)', function() {
  const now = new Date('2026-11-12T00:00:00Z');
  const future = new Date('2026-12-12T00:00:00Z');
  const past = new Date('2026-11-01T00:00:00Z');

  it('is Free with no entitlement', function() {
    expect(fromSubscriber({ entitlements: {} }, now)).to.include({ plan: 'free', status: 'none' });
    expect(fromSubscriber(undefined, now)).to.include({ plan: 'free', status: 'none' });
  });

  it('maps active, trial, cancelled and billing-issue periods', function() {
    expect(fromSubscriber(proSubscriber({ expires: future }), now))
      .to.include({ plan: 'pro', status: 'active', source: 'app_store', willRenew: true });
    expect(fromSubscriber(proSubscriber({ expires: future, periodType: 'trial' }), now))
      .to.include({ status: 'trialing' });
    expect(fromSubscriber(proSubscriber({ expires: future, extra: { unsubscribe_detected_at: past.toISOString() } }), now))
      .to.include({ status: 'cancelled', willRenew: false });
    expect(fromSubscriber(proSubscriber({ expires: future, extra: { billing_issues_detected_at: past.toISOString() } }), now))
      .to.include({ status: 'billing_issue' });
  });

  it('keeps Pro through the store grace period, then expires', function() {
    const inGrace = proSubscriber({ expires: past, extra: { grace_period_expires_date: future.toISOString() } });
    expect(fromSubscriber(inGrace, now)).to.include({ plan: 'pro', status: 'grace' });
    expect(fromSubscriber(proSubscriber({ expires: past }), now)).to.include({ plan: 'free', status: 'expired' });
  });

  it('treats a refund as the end, and no expiry as lifetime', function() {
    expect(fromSubscriber(proSubscriber({ expires: future, extra: { refunded_at: past.toISOString() } }), now))
      .to.include({ plan: 'free', status: 'expired' });
    expect(fromSubscriber(proSubscriber({ expires: null }), now)).to.include({ plan: 'pro', status: 'active', periodEnd: null });
  });
});

describe('Server limits on saved credentials (P20-12, US-SUB-04)', function() {
  afterEach(disableBilling);

  it('changes nothing while billing is off', async function() {
    const me = await signup();
    expect((await addJenkins(me.token, 'a')).status).to.equal(201);
    expect((await addJenkins(me.token, 'b')).status).to.equal(201);
    expect((await addGitHub(me.token)).status).to.equal(201);
    const list = await authed('get', '/api/credentials', me.token);
    expect(list.body.every((c) => c.locked === false)).to.equal(true);
  });

  it('allows one server on Free, of any tool, and refuses the next with PLAN_LIMIT', async function() {
    enableBilling();
    const me = await signup();
    expect((await addJenkins(me.token)).status).to.equal(201);

    const second = await addJenkins(me.token, 'second');
    expect(second.status).to.equal(403);
    expect(second.body).to.deep.include({ code: 'PLAN_LIMIT', limit: 'maxCredentialsTotal' });

    const otherTool = await addGitHub(me.token);
    expect(otherTool.status).to.equal(403);
    expect(otherTool.body).to.deep.include({ code: 'PLAN_LIMIT', limit: 'multiTool' });
  });

  it('never limits editing or deleting', async function() {
    enableBilling();
    const me = await signup();
    const { body: saved } = await addJenkins(me.token);
    expect((await authed('put', `/api/credentials/${saved._id}`, me.token).send({ serverName: 'renamed' })).status)
      .to.equal(200);
    expect((await authed('delete', `/api/credentials/${saved._id}`, me.token)).status).to.equal(200);
    expect((await addJenkins(me.token)).status).to.equal(201);
  });

  it('lets Pro save every tool, up to 25 per tool', async function() {
    enableBilling();
    const me = await signup();
    await Subscription.create({ userId: me.id, plan: 'pro', status: 'active', source: 'admin' });
    expect((await addJenkins(me.token, 'a')).status).to.equal(201);
    expect((await addGitHub(me.token)).status).to.equal(201);
    expect((await addJenkins(me.token, 'b')).status).to.equal(201);
  });
});

describe('Downgrade keeps data, locked (P20-13, US-SUB-05)', function() {
  afterEach(disableBilling);

  async function proWithThree() {
    const me = await signup();
    const a = (await addJenkins(me.token, 'a')).body;
    const b = (await addJenkins(me.token, 'b')).body;
    const g = (await addGitHub(me.token)).body;
    return { me, a, b, g };
  }

  it('lists everything after Pro ends, one usable and the rest locked', async function() {
    const { me, a, b, g } = await proWithThree(); // billing off: all saved
    enableBilling(); // no subscription: Free

    const jenkins = (await authed('get', '/api/credentials', me.token)).body;
    const github = (await authed('get', '/api/github-credentials', me.token)).body;
    expect(jenkins).to.have.length(2);
    expect(github).to.have.length(1);
    const locked = Object.fromEntries([...jenkins, ...github].map((c) => [c._id, c.locked]));
    expect(locked).to.deep.equal({ [a._id]: false, [b._id]: true, [g._id]: true }); // oldest kept
  });

  it('refuses to make a locked server active', async function() {
    const { me, b } = await proWithThree();
    enableBilling();
    const res = await authed('post', `/api/credentials/switch/${b._id}`, me.token);
    expect(res.status).to.equal(403);
    expect(res.body).to.deep.include({ code: 'PLAN_LIMIT', limit: 'locked' });
  });

  it('lets a Free user choose which server stays, once a day', async function() {
    const { me, a, g } = await proWithThree();
    enableBilling();

    const chosen = await authed('post', `/api/subscription/primary/${g._id}`, me.token);
    expect(chosen.status).to.equal(200);
    expect(chosen.body.primaryCredentialId).to.equal(g._id);
    const github = (await authed('get', '/api/github-credentials', me.token)).body;
    expect(github[0].locked).to.equal(false);
    expect((await authed('get', '/api/credentials', me.token)).body.every((c) => c.locked)).to.equal(true);

    const again = await authed('post', `/api/subscription/primary/${a._id}`, me.token);
    expect(again.status).to.equal(403);
    expect(again.body.limit).to.equal('primaryCooldown');

    await Subscription.updateOne(
      { userId: me.id },
      { $set: { primaryChangedAt: new Date(Date.now() - PRIMARY_COOLDOWN_MS - 1000) } },
    );
    expect((await authed('post', `/api/subscription/primary/${a._id}`, me.token)).status).to.equal(200);
  });

  it('refuses someone else\'s credential as the primary', async function() {
    const { a } = await proWithThree();
    const other = await signup();
    const res = await authed('post', `/api/subscription/primary/${a._id}`, other.token);
    expect(res.status).to.equal(404);
  });

  it('unlocks everything again on Pro', async function() {
    const { me } = await proWithThree();
    enableBilling();
    await Subscription.create({ userId: me.id, plan: 'pro', status: 'active', source: 'admin' });
    const jenkins = (await authed('get', '/api/credentials', me.token)).body;
    expect(jenkins.every((c) => c.locked === false)).to.equal(true);
  });
});

describe('GET /api/subscription and refresh (P20-14, US-SUB-01)', function() {
  afterEach(function() {
    disableBilling();
    setRevenueCatClientForTests(null);
  });

  it('needs a session', async function() {
    expect((await api().get('/api/subscription')).status).to.equal(401);
  });

  it('answers the plan, limits and features, never cached', async function() {
    const me = await signup();
    const res = await authed('get', '/api/subscription', me.token);
    expect(res.status).to.equal(200);
    expect(res.headers['cache-control']).to.equal('no-store');
    expect(res.body).to.include({ plan: 'pro', billingEnabled: false });
    expect(res.body).to.have.keys(
      // Changed on purpose (web checkout): `manageOnWeb` added.
      'plan', 'billingEnabled', 'status', 'source', 'productId', 'periodEnd', 'willRenew',
      'manageOnWeb', 'limits', 'features', 'primaryCredentialId',
    );
  });

  it('refresh re-reads RevenueCat for the caller only', async function() {
    enableBilling();
    const me = await signup();
    const asked = [];
    setRevenueCatClientForTests({
      getSubscriber: async (id) => { asked.push(id); return { subscriber: proSubscriber({ periodType: 'trial' }) }; },
      deleteSubscriber: async () => {},
    });
    const res = await authed('post', '/api/subscription/refresh', me.token);
    expect(res.status).to.equal(200);
    expect(asked).to.deep.equal([me.id]);
    expect(res.body).to.include({ plan: 'pro', status: 'trialing', source: 'app_store', willRenew: true });
  });

  it('keeps the stored plan when RevenueCat is down', async function() {
    enableBilling();
    const me = await signup();
    setRevenueCatClientForTests({
      getSubscriber: async () => { throw new Error('down'); },
      deleteSubscriber: async () => {},
    });
    const res = await authed('post', '/api/subscription/refresh', me.token);
    expect(res.status).to.equal(200);
    expect(res.body.plan).to.equal('free');
  });
});

describe('RevenueCat webhook (P20-16, US-SUB-09)', function() {
  let calls;
  beforeEach(function() {
    enableBilling();
    calls = [];
    setRevenueCatClientForTests({
      getSubscriber: async (id) => { calls.push(id); return { subscriber: proSubscriber() }; },
      deleteSubscriber: async () => {},
    });
  });
  afterEach(function() {
    disableBilling();
    setRevenueCatClientForTests(null);
  });

  let eventCounter = 0;
  const event = (fields) => {
    eventCounter += 1;
    return { event: { id: `evt_${eventCounter}_${Date.now()}`, type: 'INITIAL_PURCHASE', ...fields } };
  };
  const post = (body, auth = WEBHOOK_AUTH) => {
    const req = api().post('/api/billing/revenuecat');
    return (auth === null ? req : req.set('Authorization', auth)).send(body);
  };

  it('refuses a wrong or missing secret and stores nothing', async function() {
    const me = await signup();
    const body = event({ app_user_id: me.id });
    expect((await post(body, 'wrong')).status).to.equal(401);
    expect((await post(body, null)).status).to.equal(401);
    expect(calls).to.deep.equal([]);
    expect(await BillingEvent.exists({ eventId: body.event.id })).to.equal(null);
  });

  it('syncs the named account from RevenueCat, not from the body', async function() {
    const me = await signup();
    const res = await post(event({ app_user_id: me.id, period_type: 'NORMAL' }));
    expect(res.status).to.equal(200);
    expect(calls).to.deep.equal([me.id]);
    const sub = await Subscription.findOne({ userId: me.id }).lean();
    expect(sub).to.include({ plan: 'pro', status: 'active', source: 'app_store' });
  });

  it('applies a duplicate delivery once', async function() {
    const me = await signup();
    const body = event({ app_user_id: me.id });
    expect((await post(body)).status).to.equal(200);
    const again = await post(body);
    expect(again.status).to.equal(200);
    expect(again.body.duplicate).to.equal(true);
    expect(calls).to.have.length(1);
  });

  it('answers 500 and releases the event when RevenueCat fails, so the retry applies', async function() {
    const me = await signup();
    setRevenueCatClientForTests({
      getSubscriber: async () => { throw new Error('down'); },
      deleteSubscriber: async () => {},
    });
    const body = event({ app_user_id: me.id });
    expect((await post(body)).status).to.equal(500);
    expect(await BillingEvent.exists({ eventId: body.event.id })).to.equal(null);
  });

  it('skips anonymous ids and unknown users', async function() {
    const res = await post(event({
      app_user_id: '$RCAnonymousID:abc',
      transferred_to: [new mongoose.Types.ObjectId().toString()],
    }));
    expect(res.status).to.equal(200);
    expect(calls).to.deep.equal([]);
  });

  it('re-syncs both sides of a transfer', function() {
    const a = new mongoose.Types.ObjectId().toString();
    const b = new mongoose.Types.ObjectId().toString();
    expect(accountIds({ app_user_id: '$RCAnonymousID:x', transferred_from: [a], transferred_to: [b] }))
      .to.have.members([a, b]);
  });

  it('rejects a body without an event', async function() {
    expect((await post({})).status).to.equal(400);
  });
});

describe('Account deletion with billing (P20-18)', function() {
  afterEach(function() {
    disableBilling();
    setRevenueCatClientForTests(null);
  });

  it('removes the subscription and asks RevenueCat to delete the customer', async function() {
    enableBilling();
    const deleted = [];
    setRevenueCatClientForTests({
      getSubscriber: async () => ({ subscriber: {} }),
      deleteSubscriber: async (id) => { deleted.push(id); },
    });
    const me = await signup();
    await Subscription.create({ userId: me.id, plan: 'pro', status: 'active', source: 'admin' });
    const res = await authed('delete', '/api/auth/account', me.token).send({ password: 'password' });
    expect(res.status).to.equal(200);
    expect(await Subscription.exists({ userId: me.id })).to.equal(null);
    expect(deleted).to.deep.equal([me.id]);
  });
});

describe('Billing configuration (P20-17) and grant script (P20-19)', function() {
  const { invalidConfig } = require('../config/env');

  it('refuses billing on without RevenueCat', function() {
    expect(invalidConfig({ BILLING_ENABLED: 'true' })).to.match(/REVENUECAT_SECRET_API_KEY/);
    expect(invalidConfig({ BILLING_ENABLED: 'yes' })).to.match(/true or false/);
    expect(invalidConfig({
      BILLING_ENABLED: 'true', REVENUECAT_SECRET_API_KEY: 'sk', REVENUECAT_WEBHOOK_AUTH: 'w',
    })).to.equal(null);
  });

  it('reads the grant script arguments', function() {
    expect(parseArgs(['a@b.com'])).to.deep.equal({ email: 'a@b.com', days: null, revoke: false });
    expect(parseArgs(['a@b.com', '--days', '90'])).to.include({ days: 90 });
    expect(parseArgs(['a@b.com', '--revoke'])).to.include({ revoke: true });
  });
});
