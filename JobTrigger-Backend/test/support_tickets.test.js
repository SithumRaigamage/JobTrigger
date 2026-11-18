const { api } = require('./support/api');
const { expect } = require('chai');
const SupportTicket = require('../models/SupportTicket');
const AppInfo = require('../models/AppInfo');
const User = require('../models/User');
const { setTransportForTests } = require('../lib/mailer');

let counter = 0;
async function signup() {
  counter += 1;
  const email = `support${counter}@example.com`;
  const res = await api().post('/api/auth/signup').send({ email, password: 'password' });
  return { ...res.body, email };
}

const authed = (method, path, token) => api()[method](path).set('x-auth-token', token);

const valid = {
  category: 'bug',
  subject: 'Build log is blank on iOS',
  message: 'Opening the console for a finished build shows nothing.',
};

describe('Support tickets (Phase 25)', function () {
  afterEach(function () {
    setTransportForTests(null);
  });

  it('requires a session', async function () {
    expect((await api().post('/api/support/tickets').send(valid)).status).to.equal(401);
    expect((await api().get('/api/support/tickets')).status).to.equal(401);
  });

  it('files a ticket that belongs to the caller, and lists only their own', async function () {
    const me = await signup();
    const other = await signup();

    const created = await authed('post', '/api/support/tickets', me.token).send({
      ...valid,
      appVersion: '1.0.0',
      buildNumber: '7',
      tool: 'jenkins',
      platform: 'ios',
    });
    expect(created.status).to.equal(201);
    expect(created.body.ticket.category).to.equal('bug');
    expect(created.body.ticket.status).to.equal('open');
    expect(created.body.ticket.subject).to.equal(valid.subject);

    const mine = await authed('get', '/api/support/tickets', me.token);
    expect(mine.status).to.equal(200);
    expect(mine.body.tickets).to.have.length(1);
    expect(mine.body.tickets[0].id).to.equal(created.body.ticket.id);

    const theirs = await authed('get', '/api/support/tickets', other.token);
    expect(theirs.body.tickets).to.have.length(0);
  });

  it('rejects an unknown category, an empty body and oversized fields', async function () {
    const me = await signup();
    const cases = [
      { ...valid, category: 'complaint' },
      { ...valid, subject: '   ' },
      { ...valid, message: '' },
      { ...valid, subject: 'x'.repeat(121) },
      { ...valid, message: 'x'.repeat(4001) },
    ];
    for (const body of cases) {
      const res = await authed('post', '/api/support/tickets', me.token).send(body);
      expect(res.status, JSON.stringify(body).slice(0, 60)).to.equal(400);
    }
    expect(await SupportTicket.countDocuments({ userId: me.user._id })).to.equal(0);
  });

  it('stores no credential and keeps only the host of a server URL', async function () {
    const me = await signup();
    // Assembled at runtime like the guard's own fixtures: a token-shaped
    // literal would fail test/secret_material.test.js (AUD-66).
    const token = ['0123456789abcdef', '0123456789abcdef'].join('');
    const created = await authed('post', '/api/support/tickets', me.token).send({
      ...valid,
      message: `It fails with password=hunter2 and token ${token}.`,
      serverHost: 'https://user:pass@ci.example.com:8443/job/api?token=abc',
    });
    expect(created.status).to.equal(201);

    const stored = await SupportTicket.findById(created.body.ticket.id).lean();
    expect(stored.message).to.not.include(token);
    expect(stored.message).to.not.include('hunter2');
    expect(stored.message).to.include('[redacted]');
    expect(stored.serverHost).to.equal('https://ci.example.com:8443');
  });

  it('still returns 201 when the notification email fails', async function () {
    await AppInfo.deleteMany({});
    await AppInfo.create({
      appVersion: '1.0.0',
      buildNumber: '1',
      privacyPolicyUrl: 'https://example.com/p',
      termsOfServiceUrl: 'https://example.com/t',
      supportEmail: 'support@example.com',
      openSourceLicensesUrl: 'https://example.com/l',
    });
    setTransportForTests({ sendMail: async () => { throw new Error('smtp down'); } });

    const me = await signup();
    const res = await authed('post', '/api/support/tickets', me.token).send(valid);
    expect(res.status).to.equal(201);
    expect(await SupportTicket.countDocuments({ userId: me.user._id })).to.equal(1);
  });

  it('sends the owner a notification carrying the report', async function () {
    await AppInfo.deleteMany({});
    await AppInfo.create({
      appVersion: '1.0.0',
      buildNumber: '1',
      privacyPolicyUrl: 'https://example.com/p',
      termsOfServiceUrl: 'https://example.com/t',
      supportEmail: 'owner@example.com',
      openSourceLicensesUrl: 'https://example.com/l',
    });
    const sent = [];
    setTransportForTests({ sendMail: async (message) => { sent.push(message); return { messageId: 'x' }; } });

    const me = await signup();
    const res = await authed('post', '/api/support/tickets', me.token).send(valid);
    expect(res.status).to.equal(201);
    expect(sent).to.have.length(1);
    expect(sent[0].to).to.equal('owner@example.com');
    expect(sent[0].subject).to.include(valid.subject);
    expect(sent[0].text).to.include(valid.message);
  });

  it('keeps triage to the owner: a normal account gets a 404', async function () {
    const me = await signup();
    const created = await authed('post', '/api/support/tickets', me.token).send(valid);

    expect((await authed('get', '/api/admin/support/tickets', me.token)).status).to.equal(404);
    expect(
      (await authed('patch', `/api/admin/support/tickets/${created.body.ticket.id}`, me.token).send({ status: 'closed' })).status
    ).to.equal(404);
  });

  it('lets a super admin list every ticket and move it to triaged', async function () {
    const author = await signup();
    const admin = await signup();
    await User.updateOne({ _id: admin.user._id }, { role: 'superAdmin' });
    const created = await authed('post', '/api/support/tickets', author.token).send(valid);

    const list = await authed('get', '/api/admin/support/tickets', admin.token);
    expect(list.status).to.equal(200);
    const found = list.body.tickets.find((ticket) => ticket.id === created.body.ticket.id);
    expect(found).to.not.equal(undefined);
    expect(found.userEmail).to.equal(author.email);

    const patched = await authed(
      'patch',
      `/api/admin/support/tickets/${created.body.ticket.id}`,
      admin.token
    ).send({ status: 'triaged' });
    expect(patched.status).to.equal(200);
    expect(patched.body.ticket.status).to.equal('triaged');

    const bad = await authed(
      'patch',
      `/api/admin/support/tickets/${created.body.ticket.id}`,
      admin.token
    ).send({ status: 'later' });
    expect(bad.status).to.equal(400);
  });
});