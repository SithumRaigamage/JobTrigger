const { api } = require('./support/api');
const { expect } = require('chai');
const User = require('../models/User');
const Subscription = require('../models/Subscription');

let counter = 0;
async function signup(prefix = 'subadmin') {
  counter += 1;
  const email = `${prefix}${counter}@example.com`;
  const res = await api().post('/api/auth/signup').send({ email, password: 'password' });
  return { ...res.body, email, id: res.body.user._id };
}
const authed = (method, path, token) => api()[method](path).set('x-auth-token', token);

async function superAdmin() {
  const me = await signup('boss');
  await User.updateOne({ _id: me.id }, { $set: { role: 'superAdmin' } });
  return me;
}

describe('Admin subscriptions (release 1.0.0)', function() {
  it('is a plain 404 for a normal account, on every call', async function() {
    const me = await signup();
    expect((await authed('get', '/api/admin/subscriptions', me.token)).status).to.equal(404);
    expect((await authed('post', `/api/admin/subscriptions/${me.id}/grant`, me.token)).status)
      .to.equal(404);
    expect((await authed('post', `/api/admin/subscriptions/${me.id}/revoke`, me.token)).status)
      .to.equal(404);
  });

  it('checks the role in the database, so revoking it takes effect at once', async function() {
    const me = await superAdmin();
    expect((await authed('get', '/api/admin/subscriptions', me.token)).status).to.equal(200);
    await User.updateOne({ _id: me.id }, { $set: { role: 'user' } });
    expect((await authed('get', '/api/admin/subscriptions', me.token)).status).to.equal(404);
  });

  it('lists accounts with their derived plan, newest first, never cached', async function() {
    const admin = await superAdmin();
    const free = await signup();
    const res = await authed(
      'get',
      `/api/admin/subscriptions?q=${encodeURIComponent(free.email)}`,
      admin.token,
    );
    expect(res.status).to.equal(200);
    expect(res.headers['cache-control']).to.equal('no-store');
    expect(res.body.items).to.have.length(1);
    expect(res.body.items[0]).to.include({
      userId: free.id,
      email: free.email,
      plan: 'free',
      status: 'none',
      source: null,
    });
    expect(res.body.items[0].sources.grant).to.equal(null);
  });

  it('grants tester Pro for a number of days, filters by plan, then revokes it', async function() {
    const admin = await superAdmin();
    const tester = await signup('tester');

    const granted = await authed(
      'post',
      `/api/admin/subscriptions/${tester.id}/grant`,
      admin.token,
    ).send({ days: 30 });
    expect(granted.status).to.equal(200);
    expect(granted.body).to.include({ plan: 'pro', source: 'admin', willRenew: false });
    expect(granted.body.sources.grant).to.include({ plan: 'pro', status: 'active' });

    const pro = await authed(
      'get',
      `/api/admin/subscriptions?plan=pro&q=${encodeURIComponent(tester.email)}`,
      admin.token,
    );
    expect(pro.body.items.map((i) => i.email)).to.deep.equal([tester.email]);

    const free = await authed(
      'get',
      `/api/admin/subscriptions?plan=free&q=${encodeURIComponent(tester.email)}`,
      admin.token,
    );
    expect(free.body.items).to.deep.equal([]);

    const revoked = await authed(
      'post',
      `/api/admin/subscriptions/${tester.id}/revoke`,
      admin.token,
    );
    expect(revoked.status).to.equal(200);
    expect(revoked.body).to.include({ plan: 'free', source: null });
    expect(revoked.body.sources.grant).to.equal(null);
  });

  it('grants Pro with no end when days is left empty', async function() {
    const admin = await superAdmin();
    const tester = await signup('forever');
    const res = await authed(
      'post',
      `/api/admin/subscriptions/${tester.id}/grant`,
      admin.token,
    ).send({});
    expect(res.status).to.equal(200);
    expect(res.body).to.include({ plan: 'pro', periodEnd: null });
  });

  it('rejects days that are not a bounded whole number', async function() {
    const admin = await superAdmin();
    const tester = await signup();
    for (const days of [0, -1, 1.5, 3651, 'soon']) {
      const res = await authed(
        'post',
        `/api/admin/subscriptions/${tester.id}/grant`,
        admin.token,
      ).send({ days });
      expect(res.status, String(days)).to.equal(400);
    }
    expect(await Subscription.exists({ userId: tester.id })).to.equal(null);
  });

  it('answers 404 for an unknown or malformed account id', async function() {
    const admin = await superAdmin();
    for (const id of ['64b0000000000000000000aa', '../../x']) {
      expect(
        (await authed('post', `/api/admin/subscriptions/${id}/grant`, admin.token)).status,
      ).to.equal(404);
      expect(
        (await authed('post', `/api/admin/subscriptions/${id}/revoke`, admin.token)).status,
      ).to.equal(404);
    }
  });

  it('revoking a grant never touches a paid source', async function() {
    const admin = await superAdmin();
    const tester = await signup('paid');
    await Subscription.create({
      userId: tester.id,
      store: { plan: 'pro', status: 'active', source: 'app_store', willRenew: true },
      grant: { plan: 'pro', status: 'active', source: 'admin', willRenew: false },
    });
    const res = await authed(
      'post',
      `/api/admin/subscriptions/${tester.id}/revoke`,
      admin.token,
    );
    expect(res.status).to.equal(200);
    expect(res.body).to.include({ plan: 'pro', source: 'app_store' });
    expect(res.body.sources.grant).to.equal(null);
    expect(res.body.sources.store).to.include({ plan: 'pro', status: 'active' });
  });
});
