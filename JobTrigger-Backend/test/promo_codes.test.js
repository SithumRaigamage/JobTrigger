const { api } = require('./support/api');
const { expect } = require('chai');
const Subscription = require('../models/Subscription');
const PromoRedemption = require('../models/PromoRedemption');
const User = require('../models/User');
const { writeSource, clearSource } = require('../billing/combine');
const { entitlementsFor } = require('../billing/entitlements');
const { invalidConfig } = require('../config/env');

const DAY = 24 * 60 * 60 * 1000;

const CODES = [
  { code: 'LAUNCH30', days: 30 },
  { code: 'TWICE', days: 7, maxRedemptions: 2 },
  { code: 'OLD', days: 7, expiresAt: '2020-01-01' },
  { code: 'FUTURE', days: 365, expiresAt: '2099-12-31' },
];

let counter = 0;
async function signup() {
  counter += 1;
  const email = `promo${counter}@example.com`;
  const res = await api().post('/api/auth/signup').send({ email, password: 'password' });
  return { ...res.body, email, id: res.body.user._id, token: res.body.token ?? res.body.accessToken };
}
const authed = (method, path, token) => api()[method](path).set('x-auth-token', token);
const redeem = (me, code) => authed('post', '/api/subscription/promo', me.token).send({ code });
const plan = async (token) => (await authed('get', '/api/subscription', token)).body;

describe('Promo and voucher codes (US-PROMO-01)', function() {
  before(function() {
    process.env.BILLING_ENABLED = 'true';
    process.env.PROMO_CODES = JSON.stringify(CODES);
  });
  after(function() {
    process.env.BILLING_ENABLED = '';
    process.env.PROMO_CODES = '';
  });

  it('redeems a valid code for Pro for its days, and shows it on the next read', async function() {
    const me = await signup();
    const before = Date.now();
    const res = await redeem(me, 'LAUNCH30');

    expect(res.status).to.equal(200);
    expect(res.body).to.include({
      plan: 'pro',
      status: 'active',
      source: 'promo',
      willRenew: false,
      promoAvailable: true,
    });
    const end = new Date(res.body.periodEnd).getTime();
    expect(end).to.be.greaterThan(before + 30 * DAY - 5000);
    expect(end).to.be.lessThan(Date.now() + 30 * DAY + 5000);

    // The plan on the next read, and the limits that come with it.
    const after = await plan(me.token);
    expect(after).to.include({ plan: 'pro', source: 'promo' });
    expect(after.limits.maxCredentialsTotal).to.equal(null);
    expect(after.periodEnd).to.equal(res.body.periodEnd);

    // The code is kept on the source so the owner console shows it.
    const stored = await Subscription.findOne({ userId: me.id }).lean();
    expect(stored.promo).to.include({ plan: 'pro', source: 'promo', productId: 'LAUNCH30' });
    const redemption = await PromoRedemption.findOne({ code: 'LAUNCH30', userId: me.id }).lean();
    expect(redemption).to.be.an('object');
    expect(redemption.days).to.equal(30);
  });

  it('forgives case and surrounding spaces, and refuses an empty or huge value', async function() {
    const me = await signup();
    const res = await redeem(me, '  launch30  ');
    expect(res.status).to.equal(200);
    expect(res.body).to.include({ plan: 'pro', source: 'promo' });

    const other = await signup();
    const empty = await redeem(other, '   ');
    expect(empty.status).to.equal(400);
    expect(empty.body.code).to.equal('invalid_code');
    const huge = await redeem(other, 'x'.repeat(1000));
    expect(huge.status).to.equal(400);
    expect(huge.body.code).to.equal('invalid_code');
    expect((await plan(other.token)).plan).to.equal('free');
  });

  it('counts one redemption per account per code, and changes nothing the second time', async function() {
    const me = await signup();
    const first = await redeem(me, 'LAUNCH30');
    expect(first.status).to.equal(200);

    const again = await redeem(me, 'launch30');
    expect(again.status).to.equal(409);
    expect(again.body.code).to.equal('already_redeemed');
    expect((await plan(me.token)).periodEnd).to.equal(first.body.periodEnd);
    expect(await PromoRedemption.countDocuments({ code: 'LAUNCH30', userId: me.id })).to.equal(1);
  });

  it('stops a code at its total cap, saying the same thing as an unknown code', async function() {
    const [a, b, c] = [await signup(), await signup(), await signup()];
    expect((await redeem(a, 'TWICE')).status).to.equal(200);
    expect((await redeem(b, 'TWICE')).status).to.equal(200);

    const third = await redeem(c, 'TWICE');
    expect(third.status).to.equal(400);
    expect(third.body.code).to.equal('invalid_code');
    expect(third.body.message).to.equal("That code isn't valid, or it has expired.");
    expect((await plan(c.token)).plan).to.equal('free');
  });

  it('refuses a code past its last day and writes nothing', async function() {
    const me = await signup();
    const res = await redeem(me, 'OLD');
    expect(res.status).to.equal(400);
    expect(res.body.code).to.equal('invalid_code');
    expect(await PromoRedemption.countDocuments({ code: 'OLD' })).to.equal(0);
    expect(await Subscription.findOne({ userId: me.id }).lean()).to.equal(null);

    // The last day itself is still usable (an expiresAt date covers that day).
    const ok = await redeem(me, 'FUTURE');
    expect(ok.status).to.equal(200);
  });

  it('tells a Pro account the code would add nothing', async function() {
    const me = await signup();
    await writeSource(me.id, 'grant', {
      plan: 'pro', status: 'active', source: 'admin', periodEnd: null, willRenew: false,
    });
    const res = await redeem(me, 'LAUNCH30');
    expect(res.status).to.equal(409);
    expect(res.body.code).to.equal('already_pro');
    expect(await PromoRedemption.countDocuments({ userId: me.id })).to.equal(0);
  });

  it('a paid plan outranks the promo period, which comes back when the paid one ends', async function() {
    const me = await signup();
    const redeemed = await redeem(me, 'FUTURE');
    expect(redeemed.status).to.equal(200);

    // A website subscription bought while the promo period runs.
    await writeSource(me.id, 'web', {
      plan: 'pro',
      status: 'active',
      source: 'web',
      periodEnd: new Date(Date.now() + 10 * DAY),
      willRenew: true,
      paddleCustomerId: 'ctm_1',
    });
    expect(await plan(me.token)).to.include({ plan: 'pro', source: 'web' });

    // The paid plan ends: the promo period it never consumed is still there.
    await clearSource(me.id, 'web');
    const back = await plan(me.token);
    expect(back).to.include({ plan: 'pro', source: 'promo' });
    expect(back.periodEnd).to.equal(redeemed.body.periodEnd);
  });

  it('ends by date, not by a job', async function() {
    const me = await signup();
    expect((await redeem(me, 'LAUNCH30')).status).to.equal(200);

    // Time passes: the end date is now in the past.
    const past = new Date(Date.now() - DAY);
    await Subscription.updateOne(
      { userId: me.id },
      { $set: { periodEnd: past, 'promo.periodEnd': past } },
    );

    const ended = await plan(me.token);
    expect(ended.plan).to.equal('free');
    expect(ended.source).to.equal('promo');
    expect(ended.status).to.equal('expired');
    expect(ended.limits.maxCredentialsTotal).to.equal(1);

    // And the code that granted it cannot be used again to get another year.
    expect((await redeem(me, 'LAUNCH30')).body.code).to.equal('already_redeemed');
  });

  it('is unavailable when billing is off, and says so to both clients', async function() {
    const me = await signup();
    process.env.BILLING_ENABLED = '';
    try {
      expect((await plan(me.token)).promoAvailable).to.equal(false);
      const res = await redeem(me, 'LAUNCH30');
      expect(res.status).to.equal(503);
      expect(res.body.code).to.equal('not_available');
    } finally {
      process.env.BILLING_ENABLED = 'true';
    }
  });

  it('is unavailable when no codes are configured', async function() {
    const me = await signup();
    process.env.PROMO_CODES = '';
    try {
      expect((await plan(me.token)).promoAvailable).to.equal(false);
      const res = await redeem(me, 'LAUNCH30');
      expect(res.status).to.equal(503);
      expect(res.body.code).to.equal('not_available');
    } finally {
      process.env.PROMO_CODES = JSON.stringify(CODES);
    }
  });

  it('needs a session', async function() {
    const res = await api().post('/api/subscription/promo').send({ code: 'LAUNCH30' });
    expect(res.status).to.equal(401);
  });

  it('limits attempts per account, so a code list cannot be walked', async function() {
    const me = await signup();
    let last;
    for (let i = 0; i < 11; i += 1) {
      last = await redeem(me, `GUESS${i}`);
    }
    expect(last.status).to.equal(429);
    expect(await PromoRedemption.countDocuments({ userId: me.id })).to.equal(0);
  });

  it('shows the redemption to the owner console', async function() {
    const me = await signup();
    expect((await redeem(me, 'LAUNCH30')).status).to.equal(200);
    await User.updateOne({ _id: me.id }, { $set: { role: 'superAdmin' } });

    const res = await authed('get', '/api/admin/subscriptions', me.token);
    expect(res.status).to.equal(200);
    const item = res.body.items.find((i) => i.userId === String(me.id));
    expect(item.source).to.equal('promo');
    expect(item.sources.promo).to.include({ plan: 'pro', source: 'promo', productId: 'LAUNCH30' });
  });

  it('removes the redemption with the account', async function() {
    const me = await signup();
    expect((await redeem(me, 'LAUNCH30')).status).to.equal(200);
    expect(await PromoRedemption.countDocuments({ userId: me.id })).to.equal(1);

    const del = await authed('delete', '/api/auth/account', me.token).send({ password: 'password' });
    expect(del.status).to.equal(200);
    expect(await PromoRedemption.countDocuments({ userId: me.id })).to.equal(0);
  });

  it('refuses to start with a broken code list, naming only the variable', function() {
    // Billing off here, so this test is about the code list only (a billing
    // build would need a provider set up, which is checked before it).
    const withCodes = (value) =>
      invalidConfig({ ...process.env, BILLING_ENABLED: 'false', PROMO_CODES: value });

    expect(withCodes('not json')).to.include('PROMO_CODES');
    expect(withCodes('{"code":"X","days":1}')).to.include('PROMO_CODES');
    expect(withCodes('[{"code":"OK"}]')).to.include('PROMO_CODES');
    expect(withCodes('[{"code":"OK","days":0}]')).to.include('PROMO_CODES');
    expect(withCodes('[{"code":"OK","days":4000}]')).to.include('PROMO_CODES');
    expect(withCodes('[{"code":"OK","days":3,"maxRedemptions":0}]')).to.include('PROMO_CODES');
    expect(withCodes('[{"code":"OK","days":3,"expiresAt":"soon"}]')).to.include('PROMO_CODES');
    expect(withCodes('[{"code":"BAD CODE","days":3}]')).to.include('PROMO_CODES');
    expect(withCodes('[{"code":"OK","days":3},{"code":"ok","days":3}]')).to.include('PROMO_CODES');
    // The message never echoes a value from the list.
    expect(withCodes('[{"code":"SECRET1","days":0}]')).to.not.include('SECRET1');

    expect(withCodes('')).to.equal(null);
    expect(withCodes(JSON.stringify(CODES))).to.equal(null);
  });

  it('keeps the promo out of the entitlements of a different account', async function() {
    const me = await signup();
    const other = await signup();
    expect((await redeem(me, 'LAUNCH30')).status).to.equal(200);
    expect((await entitlementsFor(other.id)).plan).to.equal('free');
  });
});
