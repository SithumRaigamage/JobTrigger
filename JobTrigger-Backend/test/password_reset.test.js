const { api } = require('./support/api');
const { expect } = require('chai');
const { captureLogs, linesWith } = require('./support/logs');
const User = require('../models/User');
const PasswordResetToken = require('../models/PasswordResetToken');
const { setTransportForTests } = require('../lib/mailer');
const { setSenderForTests } = require('../lib/analytics');
const { whenIdle, hashToken } = require('../controllers/passwordResetController');

let counter = 0;
async function signup() {
  counter += 1;
  const email = `reset${counter}@example.com`;
  const res = await api().post('/api/auth/signup').send({ email, password: 'password' });
  return { ...res.body, email };
}

/** A transport that keeps every message instead of sending it. */
function fakeTransport() {
  const sent = [];
  return { sent, sendMail: async (message) => { sent.push(message); return { messageId: `m${sent.length}` }; } };
}

const requestReset = async (email) => {
  const res = await api().post('/api/auth/password-reset/request').send({ email });
  await whenIdle();
  return res;
};
const tokenFrom = (message) => /token=([a-f0-9]{64})/.exec(message.text)[1];
const confirm = (body) => api().post('/api/auth/password-reset/confirm').send(body);

describe('Password reset by email (US-AUTH-08)', function() {
  let transport;
  let events;

  beforeEach(function() {
    transport = fakeTransport();
    setTransportForTests(transport);
    events = [];
    setSenderForTests(async (url, body) => { events.push(body.payload.name); });
  });

  afterEach(function() {
    setTransportForTests(null);
    setSenderForTests(null);
  });

  it('answers an unknown email exactly like a known one, and sends nothing', async function() {
    const me = await signup();
    const known = await requestReset(me.email);
    const unknown = await requestReset('nobody-here@example.com');

    expect(known.status).to.equal(202);
    expect(unknown.status).to.equal(202);
    expect(unknown.body).to.deep.equal(known.body);
    expect(transport.sent).to.have.length(1);
    expect(transport.sent[0].to).to.equal(me.email);
  });

  it('emails a single-use link and stores only the token hash', async function() {
    const me = await signup();
    await requestReset(`  ${me.email.toUpperCase()} `);

    const message = transport.sent[0];
    expect(message.subject).to.equal('Reset your JobTrigger password');
    // Web only (US-AUTH-08): one link, to the website, none into the app.
    expect(message.text).to.include('http://localhost:3000/reset-password?token=');
    expect(message.text).to.not.include('jobtrigger://');
    const token = tokenFrom(message);

    const stored = await PasswordResetToken.find({ userId: me.user._id });
    expect(stored).to.have.length(1);
    expect(stored[0].tokenHash).to.equal(hashToken(token));
    expect(stored[0].tokenHash).to.not.equal(token);
    expect(JSON.stringify(stored[0].toObject())).to.not.include(token);
  });

  it('resets the password, signs out every session, and spends the token', async function() {
    const me = await signup();
    await requestReset(me.email);
    const token = tokenFrom(transport.sent[0]);

    const res = await confirm({ token, newPassword: 'brand-new-password' });
    expect(res.status).to.equal(200);

    // Old sessions are revoked (tokenVersion bump).
    expect((await api().get('/api/credentials').set('x-auth-token', me.token)).status).to.equal(401);
    expect((await api().post('/api/auth/refresh').send({ refreshToken: me.refreshToken })).status)
      .to.equal(401);
    // Only the new password works.
    expect((await api().post('/api/auth/login').send({ email: me.email, password: 'password' })).status)
      .to.equal(400);
    expect((await api().post('/api/auth/login')
      .send({ email: me.email, password: 'brand-new-password' })).status).to.equal(200);

    // Single use.
    const again = await confirm({ token, newPassword: 'another-password' });
    expect(again.status).to.equal(400);
    expect(await PasswordResetToken.countDocuments({ userId: me.user._id })).to.equal(0);
    expect(events).to.include.members(['password_reset_requested', 'password_reset_completed']);
  });

  it('replaces an older pending link with the newest one', async function() {
    const me = await signup();
    await requestReset(me.email);
    await requestReset(me.email);
    const [first, second] = transport.sent.map(tokenFrom);

    expect((await confirm({ token: first, newPassword: 'brand-new-password' })).status).to.equal(400);
    expect((await confirm({ token: second, newPassword: 'brand-new-password' })).status).to.equal(200);
  });

  it('refuses an expired link', async function() {
    const me = await signup();
    await requestReset(me.email);
    const token = tokenFrom(transport.sent[0]);
    await PasswordResetToken.updateOne(
      { userId: me.user._id }, { $set: { expiresAt: new Date(Date.now() - 1000) } },
    );

    const res = await confirm({ token, newPassword: 'brand-new-password' });
    expect(res.status).to.equal(400);
    expect(res.body.message).to.match(/invalid or has expired/);
  });

  it('keeps the link usable when the new password breaks the rules', async function() {
    const me = await signup();
    await requestReset(me.email);
    const token = tokenFrom(transport.sent[0]);

    const weak = await confirm({ token, newPassword: 'short' });
    expect(weak.status).to.equal(400);
    expect((await confirm({ token, newPassword: 'brand-new-password' })).status).to.equal(200);
  });

  it('rejects malformed bodies before touching the database', async function() {
    for (const body of [{}, { email: { $gt: '' } }, { email: 42 }, { email: '   ' }]) {
      const res = await api().post('/api/auth/password-reset/request').send(body);
      expect(res.status).to.equal(400);
    }
    for (const body of [
      {},
      { token: 'abc', newPassword: 'brand-new-password' },
      { token: { $ne: null }, newPassword: 'brand-new-password' },
      { token: 'a'.repeat(64), newPassword: { $gt: '' } },
    ]) {
      const res = await confirm(body);
      expect(res.status).to.equal(400);
    }
    expect(transport.sent).to.have.length(0);
  });

  it('still answers 202 when mail is off, and logs it without the address', async function() {
    setTransportForTests(null); // No SMTP_HOST in tests: mail is disabled.
    const me = await signup();
    let res;
    const logs = await captureLogs(async () => { res = await requestReset(me.email); });

    expect(res.status).to.equal(202);
    expect(linesWith(logs, 'mail.disabled')).to.have.length(1);
    expect(JSON.stringify(logs)).to.not.include(me.email);
  });

  it('still answers 202 when sending fails', async function() {
    setTransportForTests({ sendMail: async () => { throw new Error('smtp down'); } });
    const me = await signup();
    let res;
    const logs = await captureLogs(async () => { res = await requestReset(me.email); });

    expect(res.status).to.equal(202);
    expect(linesWith(logs, 'password_reset.request_failed')).to.have.length(1);
  });

  it('deletes pending reset links with the account', async function() {
    const me = await signup();
    await requestReset(me.email);
    await api().delete('/api/auth/account').set('x-auth-token', me.token).send({ password: 'password' });
    expect(await PasswordResetToken.countDocuments({ userId: me.user._id })).to.equal(0);
    expect(await User.exists({ _id: me.user._id })).to.equal(null);
  });
});
