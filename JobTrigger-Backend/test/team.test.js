const crypto = require('crypto');
const { api } = require('./support/api');
const { expect } = require('chai');
const Team = require('../models/Team');
const Subscription = require('../models/Subscription');
const { setTransportForTests } = require('../lib/mailer');
const { setPaddleClientForTests } = require('../billing/paddleClient');
const { hashToken } = require('../lib/team');

/**
 * US-SUB-11 team plan, backend criteria AC1–AC11
 * (docs/user-stories/billing/18-subscriptions.md).
 */
const DAY = 24 * 60 * 60 * 1000;
const SECRET = 'pdl_ntfset_team_secret';
const sign = (raw) => {
  const ts = Math.floor(Date.now() / 1000);
  return `ts=${ts};h1=${crypto.createHmac('sha256', SECRET).update(`${ts}:${raw}`).digest('hex')}`;
};

let counter = 0;
async function signup(prefix = 'team') {
  counter += 1;
  const email = `${prefix}${counter}@example.com`;
  const res = await api().post('/api/auth/signup').send({ email, password: 'password' });
  return { token: res.body.token, email, id: res.body.user._id };
}
const authed = (method, path, token) => api()[method](path).set('x-auth-token', token);

const ENV = {
  TEAM_PLAN_ENABLED: 'true',
  BILLING_ENABLED: 'true',
  PADDLE_API_KEY: 'pdl_sdbx_apikey',
  PADDLE_WEBHOOK_SECRET: SECRET,
  PADDLE_PRICE_MONTHLY: 'pri_monthly',
  PADDLE_PRICE_YEARLY: 'pri_yearly',
  PADDLE_PRICE_TEAM_MONTHLY: 'pri_team_monthly',
  PADDLE_PRICE_TEAM_YEARLY: 'pri_team_yearly',
};
const on = () => Object.assign(process.env, ENV);
const off = () => { for (const name of Object.keys(ENV)) process.env[name] = ''; };

let mail;
let paddleCalls;
function fakes() {
  mail = [];
  paddleCalls = [];
  setTransportForTests({ sendMail: async (message) => { mail.push(message); return { messageId: 'm' }; } });
  setPaddleClientForTests({
    createTransaction: async (args) => { paddleCalls.push(['createTransaction', args]); return { transactionId: 'txn_team' }; },
    updateSubscriptionQuantity: async (args) => { paddleCalls.push(['updateSubscriptionQuantity', args]); },
    createPortalSession: async () => ({ url: 'https://portal' }),
    cancelSubscription: async () => {},
  });
}
function restore() {
  off();
  setTransportForTests(null);
  setPaddleClientForTests(null);
}

/** The raw token from the last invite email. */
const tokenFromMail = () => new URL(/https?:\/\/\S+/.exec(mail.at(-1).text)[0]).searchParams.get('token');

let eventCounter = 0;
function webhook(type, data, occurredAt = new Date()) {
  eventCounter += 1;
  const raw = JSON.stringify({ event_id: `evt_team_${eventCounter}_${Date.now()}`, event_type: type, occurred_at: occurredAt.toISOString(), data });
  return api().post('/api/billing/paddle/webhook')
    .set('Content-Type', 'application/json')
    .set('Paddle-Signature', sign(raw))
    .send(raw);
}
const teamSub = (teamId, { status = 'active', quantity = 3, price = 'pri_team_monthly', id = 'sub_team_1', endsAt = new Date(Date.now() + 30 * DAY) } = {}) => ({
  id,
  status,
  customer_id: 'ctm_team',
  custom_data: teamId ? { teamId } : null,
  current_billing_period: { starts_at: new Date().toISOString(), ends_at: endsAt.toISOString() },
  items: [{ price: { id: price }, quantity }],
});

async function ownerWithTeam(name = 'Platform') {
  const owner = await signup('owner');
  const res = await authed('post', '/api/team', owner.token).send({ name });
  return { owner, team: res.body };
}
async function paidTeam(options) {
  const { owner, team } = await ownerWithTeam();
  await webhook('subscription.created', teamSub(team.id, options));
  return { owner, team };
}
async function join(owner, member) {
  await authed('post', '/api/team/invites', owner.token).send({ email: member.email });
  return authed('post', '/api/team/join', member.token).send({ token: tokenFromMail() });
}
const addJenkins = (token, name) => authed('post', '/api/credentials', token).send({
  serverName: name, jenkinsURL: `https://${name}.example.com`, username: 'svc', password: `pw-${name}`,
});

describe('Team plan (US-SUB-11)', function() {
  beforeEach(function() { on(); fakes(); });
  afterEach(restore);

  describe('AC1 off by default', function() {
    it('answers 404 everywhere and adds nothing to the plan', async function() {
      const me = await signup();
      off();
      for (const [method, path] of [['get', '/api/team'], ['post', '/api/team'], ['post', '/api/team/join'], ['get', '/api/team/servers']]) {
        expect((await authed(method, path, me.token)).status, path).to.equal(404);
      }
      const plan = await authed('get', '/api/subscription', me.token);
      expect(plan.body).not.to.have.property('team');
    });
  });

  describe('AC2 create', function() {
    it('makes the creator the owner and allows one team per user', async function() {
      const { owner, team } = await ownerWithTeam('  Platform  ');
      expect(team).to.include({ name: 'Platform', role: 'owner', seats: 2, seatsUsed: 1, active: false });
      expect(team.members).to.deep.equal([{ userId: owner.id, email: owner.email, owner: true, joinedAt: team.members[0].joinedAt }]);
      const again = await authed('post', '/api/team', owner.token).send({ name: 'Second' });
      expect(again.status).to.equal(409);
      expect(again.body.code).to.equal('ALREADY_IN_TEAM');
    });

    it('needs a name of 1 to 60 characters', async function() {
      const me = await signup();
      for (const name of ['', '   ', 'x'.repeat(61), 42]) {
        expect((await authed('post', '/api/team', me.token).send({ name })).body.code).to.equal('INVALID_NAME');
      }
      expect(await authed('get', '/api/team', me.token).then((r) => r.body)).to.equal(null);
    });
  });

  describe('AC3 price, seats and checkout', function() {
    it('creates a Paddle transaction for the seats, carrying the team id', async function() {
      const { owner, team } = await ownerWithTeam();
      const res = await authed('post', '/api/team/checkout', owner.token).send({ period: 'yearly', seats: 5 });
      expect(res.status).to.equal(200);
      expect(res.body).to.deep.equal({ transactionId: 'txn_team', environment: 'sandbox' });
      expect(paddleCalls).to.deep.equal([['createTransaction', {
        priceId: 'pri_team_yearly', quantity: 5, customData: { teamId: team.id },
      }]]);
      expect(team.prices).to.deep.equal({ monthly: 6.99, yearly: 69.9, minSeats: 2, maxSeats: 100 });
    });

    it('refuses bad seats or period, a member, and a missing price', async function() {
      const { owner } = await ownerWithTeam();
      for (const seats of [1, 101, 2.5, 'many']) {
        expect((await authed('post', '/api/team/checkout', owner.token).send({ period: 'monthly', seats })).body.code).to.equal('INVALID_SEATS');
      }
      expect((await authed('post', '/api/team/checkout', owner.token).send({ period: 'weekly', seats: 3 })).status).to.equal(400);
      const member = await signup('member');
      expect((await join(owner, member)).status).to.equal(200);
      expect((await authed('post', '/api/team/checkout', member.token).send({ period: 'monthly', seats: 3 })).body.code).to.equal('NOT_OWNER');
      process.env.PADDLE_PRICE_TEAM_YEARLY = '';
      expect((await authed('post', '/api/team/checkout', owner.token).send({ period: 'monthly', seats: 3 })).status).to.equal(503);
      expect(paddleCalls).to.have.length(0);
    });
  });

  describe('AC4 billing events', function() {
    it('sets status, period, seats; ignores stale events; leaves personal web alone', async function() {
      const { owner, team } = await ownerWithTeam();
      const created = await webhook('subscription.created', teamSub(team.id, { quantity: 4, price: 'pri_team_yearly' }));
      expect(created.body).to.include({ ok: true, team: true });
      let doc = await Team.findById(team.id).lean();
      expect(doc.seats).to.equal(4);
      expect(doc.billing).to.include({ plan: 'pro', status: 'active', period: 'yearly', paddleSubscriptionId: 'sub_team_1', willRenew: true });

      // Matched by subscription id later; an older event changes nothing.
      await webhook('subscription.updated', teamSub(null, { quantity: 6 }), new Date(Date.now() - DAY));
      doc = await Team.findById(team.id).lean();
      expect(doc.seats).to.equal(4);
      await webhook('subscription.updated', teamSub(null, { quantity: 6, price: 'pri_team_yearly' }));
      expect((await Team.findById(team.id).lean()).seats).to.equal(6);

      expect(await Subscription.findOne({ userId: owner.id }).lean()).to.equal(null);
    });
  });

  describe('AC5 invite', function() {
    it('emails a link, stores only the hash, expires in 7 days and holds a seat', async function() {
      const { owner } = await ownerWithTeam();
      const res = await authed('post', '/api/team/invites', owner.token).send({ email: ' New@Example.com ' });
      expect(res.status).to.equal(201);
      expect(res.body.invites).to.have.length(1);
      expect(res.body.invites[0].email).to.equal('new@example.com');
      expect(res.body.seatsUsed).to.equal(2);
      expect(JSON.stringify(res.body)).not.to.match(/token/i);

      expect(mail).to.have.length(1);
      expect(mail[0].to).to.equal('new@example.com');
      expect(mail[0].subject).to.equal("You're invited to Platform on JobTrigger");
      // The link opens the website's join page, under /account (sign-in,
      // no-store, noindex).
      expect(mail[0].text).to.match(/https?:\/\/[^\s]+\/account\/team\/join\?token=/);
      const token = tokenFromMail();
      expect(token).to.have.length.greaterThan(40);
      const stored = (await Team.findOne({ ownerId: owner.id }).lean()).invites[0];
      expect(stored.tokenHash).to.equal(hashToken(token));
      expect(JSON.stringify(stored)).not.to.contain(token);
      const days = (new Date(stored.expiresAt) - Date.now()) / DAY;
      expect(days).to.be.within(6.99, 7.01);
    });

    it('refuses past the seats; inviting the same address again replaces it', async function() {
      const { owner } = await ownerWithTeam(); // 2 seats: owner + one invite
      await authed('post', '/api/team/invites', owner.token).send({ email: 'a@example.com' });
      const again = await authed('post', '/api/team/invites', owner.token).send({ email: 'a@example.com' });
      expect(again.status).to.equal(201);
      expect(again.body.invites).to.have.length(1);
      const full = await authed('post', '/api/team/invites', owner.token).send({ email: 'b@example.com' });
      expect(full.status).to.equal(403);
      expect(full.body.code).to.equal('SEATS_FULL');
      expect((await authed('post', '/api/team/invites', owner.token).send({ email: 'nope' })).body.code).to.equal('INVALID_EMAIL');
    });
  });

  describe('AC6 accept', function() {
    it('joins with the matching account', async function() {
      const { owner } = await ownerWithTeam();
      const member = await signup('member');
      const res = await join(owner, member);
      expect(res.status).to.equal(200);
      expect(res.body).to.include({ role: 'member', seatsUsed: 2 });
      expect(res.body.invites).to.deep.equal([]);
    });

    it('refuses unknown, expired, other-email, already-in-team and full', async function() {
      const { owner } = await ownerWithTeam();
      const member = await signup('member');
      expect((await authed('post', '/api/team/join', member.token).send({ token: 'x'.repeat(43) })).body.code).to.equal('INVITE_UNKNOWN');

      await authed('post', '/api/team/invites', owner.token).send({ email: member.email });
      const token = tokenFromMail();
      const stranger = await signup('stranger');
      const other = await authed('post', '/api/team/join', stranger.token).send({ token });
      expect(other.status).to.equal(403);
      expect(other.body.code).to.equal('INVITE_OTHER_EMAIL');

      await Team.updateOne({ ownerId: owner.id }, { $set: { 'invites.0.expiresAt': new Date(Date.now() - 1000) } });
      expect((await authed('post', '/api/team/join', member.token).send({ token })).body.code).to.equal('INVITE_EXPIRED');

      const { owner: owner2 } = await ownerWithTeam('Other');
      await authed('post', '/api/team/invites', owner2.token).send({ email: owner.email });
      expect((await authed('post', '/api/team/join', owner.token).send({ token: tokenFromMail() })).body.code).to.equal('ALREADY_IN_TEAM');
    });
  });

  describe('AC6 accept when seats were lowered', function() {
    it('refuses with SEATS_FULL when Paddle cut the seats under a pending invite', async function() {
      const { owner, team } = await paidTeam({ quantity: 3 });
      const first = await signup('member');
      await join(owner, first);
      const second = await signup('member');
      await authed('post', '/api/team/invites', owner.token).send({ email: second.email });
      const token = tokenFromMail();
      // The owner lowered the seats in Paddle's portal: 2 seats, 2 members.
      await webhook('subscription.updated', teamSub(team.id, { quantity: 2 }));
      const res = await authed('post', '/api/team/join', second.token).send({ token });
      expect(res.status).to.equal(403);
      expect(res.body.code).to.equal('SEATS_FULL');
    });
  });

  describe('AC7 Pro for members', function() {
    it('gives the owner and members Pro with source team while the team is paid', async function() {
      const { owner } = await paidTeam();
      const member = await signup('member');
      await join(owner, member);
      for (const who of [owner, member]) {
        const plan = (await authed('get', '/api/subscription', who.token)).body;
        expect(plan).to.include({ plan: 'pro', source: 'team' });
        expect(plan.team).to.include({ name: 'Platform', active: true, role: who === owner ? 'owner' : 'member' });
      }
    });

    it('keeps a member\'s own Pro as the source, and is Free when the team lapses', async function() {
      const { owner, team } = await paidTeam();
      const member = await signup('member');
      await join(owner, member);
      await Subscription.create({ userId: member.id, plan: 'pro', status: 'active', source: 'admin' });
      expect((await authed('get', '/api/subscription', member.token)).body).to.include({ plan: 'pro', source: 'admin' });

      await webhook('subscription.canceled', teamSub(team.id, { status: 'canceled' }));
      const lapsed = (await authed('get', '/api/subscription', owner.token)).body;
      expect(lapsed.plan).to.equal('free');
      expect(lapsed.team).to.include({ active: false });
    });
  });

  describe('AC8 leave and remove', function() {
    it('removes, cancels, leaves; the owner stays; the locked guard comes back', async function() {
      const { owner } = await paidTeam({ quantity: 4 });
      const member = await signup('member');
      await join(owner, member);
      await addJenkins(member.token, 'm1');
      await addJenkins(member.token, 'm2');

      const invited = await authed('post', '/api/team/invites', owner.token).send({ email: 'later@example.com' });
      const cancelled = await authed('delete', `/api/team/invites/${invited.body.invites[0].id}`, owner.token);
      expect(cancelled.body.invites).to.deep.equal([]);

      expect((await authed('post', '/api/team/leave', owner.token)).body.code).to.equal('OWNER_STAYS');
      expect((await authed('delete', `/api/team/members/${owner.id}`, owner.token)).body.code).to.equal('OWNER_STAYS');
      expect((await authed('delete', `/api/team/members/${member.id}`, member.token)).body.code).to.equal('NOT_OWNER');

      const removed = await authed('delete', `/api/team/members/${member.id}`, owner.token);
      expect(removed.body.members).to.have.length(1);
      expect((await authed('get', '/api/subscription', member.token)).body.plan).to.equal('free');
      const servers = (await authed('get', '/api/credentials', member.token)).body;
      expect(servers).to.have.length(2);
      expect(servers.filter((c) => c.locked)).to.have.length(1);
      expect(await authed('get', '/api/team', member.token).then((r) => r.body)).to.equal(null);
    });

    it('lets a member leave', async function() {
      const { owner } = await ownerWithTeam();
      const member = await signup('member');
      await join(owner, member);
      expect((await authed('post', '/api/team/leave', member.token)).status).to.equal(200);
      expect((await authed('get', '/api/team', owner.token)).body.members).to.have.length(1);
    });
  });

  describe('AC9 change seats', function() {
    it('updates Paddle for a paid team, and never goes below seats in use', async function() {
      const { owner } = await paidTeam({ quantity: 3, price: 'pri_team_yearly' });
      await authed('post', '/api/team/invites', owner.token).send({ email: 'a@example.com' });
      await authed('post', '/api/team/invites', owner.token).send({ email: 'b@example.com' });
      expect((await authed('put', '/api/team/seats', owner.token).send({ seats: 2 })).body.code).to.equal('SEATS_IN_USE');
      expect((await authed('put', '/api/team/seats', owner.token).send({ seats: 101 })).body.code).to.equal('INVALID_SEATS');
      const res = await authed('put', '/api/team/seats', owner.token).send({ seats: 8 });
      expect(res.body.seats).to.equal(8);
      expect(paddleCalls).to.deep.equal([['updateSubscriptionQuantity', {
        subscriptionId: 'sub_team_1', priceId: 'pri_team_yearly', quantity: 8,
      }]]);
    });

    it('an unpaid team just stores the count', async function() {
      const { owner } = await ownerWithTeam();
      expect((await authed('put', '/api/team/seats', owner.token).send({ seats: 5 })).body.seats).to.equal(5);
      expect(paddleCalls).to.have.length(0);
    });
  });

  describe('AC10 shared Jenkins servers', function() {
    it('members list them masked and read the secret; revoked at once', async function() {
      const { owner } = await paidTeam();
      const member = await signup('member');
      await join(owner, member);
      const server = (await addJenkins(owner.token, 'ci')).body;

      const shared = await authed('post', '/api/team/servers', owner.token).send({ credentialId: server._id });
      expect(shared.body.sharedServerIds).to.deep.equal([server._id]);

      const list = (await authed('get', '/api/team/servers', member.token)).body;
      expect(list).to.have.length(1);
      expect(list[0]).to.include({ id: server._id, serverName: 'ci', jenkinsURL: 'https://ci.example.com', sharedBy: owner.email });
      expect(JSON.stringify(list)).not.to.contain('pw-ci');

      const secret = await authed('get', `/api/team/servers/jenkins/${server._id}/secret`, member.token);
      expect(secret.status).to.equal(200);
      expect(secret.headers['cache-control']).to.equal('no-store');
      expect(secret.body.password).to.equal('pw-ci');

      const stranger = await signup('stranger');
      expect((await authed('get', `/api/team/servers/jenkins/${server._id}/secret`, stranger.token)).status).to.equal(404);

      await authed('delete', `/api/team/servers/${server._id}`, owner.token);
      expect((await authed('get', `/api/team/servers/jenkins/${server._id}/secret`, member.token)).status).to.equal(404);
      expect((await authed('get', '/api/team/servers', member.token)).body).to.deep.equal([]);
    });

    it('only the owner\'s own Jenkins servers can be shared, and a lapsed team shares nothing', async function() {
      const { owner, team } = await paidTeam();
      const member = await signup('member');
      await join(owner, member);
      const mine = (await addJenkins(member.token, 'mine')).body;
      expect((await authed('post', '/api/team/servers', owner.token).send({ credentialId: mine._id })).body.code).to.equal('NO_SERVER');
      expect((await authed('post', '/api/team/servers', member.token).send({ credentialId: mine._id })).body.code).to.equal('NOT_OWNER');

      const server = (await addJenkins(owner.token, 'ci')).body;
      await authed('post', '/api/team/servers', owner.token).send({ credentialId: server._id });
      await webhook('subscription.canceled', teamSub(team.id, { status: 'canceled' }));
      expect((await authed('get', '/api/team/servers', member.token)).body).to.deep.equal([]);
      expect((await authed('get', `/api/team/servers/jenkins/${server._id}/secret`, member.token)).status).to.equal(404);
    });
  });

  describe('AC11 delete', function() {
    it('needs the subscription to stop renewing; account deletion rules', async function() {
      const { owner, team } = await paidTeam();
      const member = await signup('member');
      await join(owner, member);

      expect((await authed('delete', '/api/team', owner.token)).body.code).to.equal('TEAM_SUBSCRIPTION_ACTIVE');
      const ownerDelete = await authed('delete', '/api/auth/account', owner.token).send({ password: 'password' });
      expect(ownerDelete.status).to.equal(403);
      expect(ownerDelete.body.code).to.equal('TEAM_OWNER');

      // A member's account deletion removes the membership.
      const memberDelete = await authed('delete', '/api/auth/account', member.token).send({ password: 'password' });
      expect(memberDelete.status).to.equal(200);
      expect((await Team.findById(team.id).lean()).members).to.have.length(1);

      await webhook('subscription.canceled', teamSub(team.id, { status: 'canceled' }));
      expect((await authed('delete', '/api/team', owner.token)).status).to.equal(200);
      expect(await Team.findById(team.id).lean()).to.equal(null);
    });
  });
});
