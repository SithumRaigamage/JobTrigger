const { api } = require('./support/api');
const { expect } = require('chai');
const Subscription = require('../models/Subscription');
const StudentVerification = require('../models/StudentVerification');
const StudentClaim = require('../models/StudentClaim');
const User = require('../models/User');
const { setTransportForTests } = require('../lib/mailer');
const { derive, writeSource } = require('../billing/combine');
const { describe: describePlan, entitlementsFor } = require('../billing/entitlements');
const student = require('../lib/student');
const { parseArgs, ROLES } = require('../scripts/grant-role');
const { studentRenewalEnabled, studentAdminEmail, invalidConfig } = require('../config/env');

const DAY = 24 * 60 * 60 * 1000;

let counter = 0;
async function signup() {
  counter += 1;
  const email = `student${counter}@example.com`;
  const res = await api().post('/api/auth/signup').send({ email, password: 'password' });
  return { ...res.body, email, id: res.body.user._id, token: res.body.token ?? res.body.accessToken };
}
const authed = (method, path, token) => api()[method](path).set('x-auth-token', token);
const start = (me, universityEmail) => authed('post', '/api/student/email/start', me.token).send({ universityEmail });
const confirm = (me, code) => authed('post', '/api/student/email/confirm', me.token).send({ code });

function fakeTransport() {
  const sent = [];
  return { sent, sendMail: async (m) => { sent.push(m); return { messageId: `m${sent.length}` }; } };
}
const codeFrom = (message) => /code is (\d{6})/.exec(message.text)[1];
const wrongCode = (code) => (code === '000000' ? '111111' : '000000');

describe('Student plan: data and entitlements (SP-1)', function() {
  afterEach(function() {
    process.env.BILLING_ENABLED = '';
  });

  it('gives a student year as Pro with source student, for 365 days', async function() {
    const me = await signup();
    const now = new Date();
    const expiresAt = await student.grantStudentYear(me.id, now);
    expect(expiresAt.getTime() - now.getTime()).to.equal(365 * DAY);

    process.env.BILLING_ENABLED = 'true';
    const ent = await entitlementsFor(me.id);
    expect(ent.plan).to.equal('pro');
    expect(ent.source).to.equal('student');
    expect(new Date(ent.periodEnd).getTime()).to.equal(expiresAt.getTime());
    const stored = await Subscription.findOne({ userId: me.id }).lean();
    expect(stored.student.startsAt).to.be.instanceOf(Date);
    expect(stored.student.source).to.equal('student');
  });

  it('computes expiry from the date: past the end is Free with no job needed', async function() {
    const me = await signup();
    const now = new Date();
    await student.grantStudentYear(me.id, now);
    const sub = await Subscription.findOne({ userId: me.id }).lean();

    const during = describePlan(sub, { enabled: true, now: new Date(now.getTime() + 364 * DAY) });
    const after = describePlan(sub, { enabled: true, now: new Date(now.getTime() + 366 * DAY) });
    expect(during.plan).to.equal('pro');
    expect(after.plan).to.equal('free');
    expect(derive(sub, new Date(now.getTime() + 366 * DAY)).plan).to.equal('free');
  });

  it('lets a paid subscription win over the student year, even a shorter one', function() {
    const now = new Date();
    const doc = {
      student: { plan: 'pro', status: 'active', source: 'student', periodEnd: new Date(now.getTime() + 300 * DAY) },
      web: { plan: 'pro', status: 'active', source: 'web', periodEnd: new Date(now.getTime() + 20 * DAY), willRenew: true },
    };
    expect(derive(doc, now).source).to.equal('web');
    const store = { plan: 'pro', status: 'active', source: 'app_store', periodEnd: new Date(now.getTime() + 5 * DAY) };
    expect(derive({ student: doc.student, store }, now).source).to.equal('app_store');
  });

  it('falls back to the student year when the paid one ends', function() {
    const now = new Date();
    const doc = {
      student: { plan: 'pro', status: 'active', source: 'student', periodEnd: new Date(now.getTime() + 300 * DAY) },
      web: { plan: 'pro', status: 'expired', source: 'web', periodEnd: new Date(now.getTime() - DAY) },
    };
    expect(derive(doc, now).source).to.equal('student');
  });

  it('keeps existing grant behaviour: the longest non-student Pro still wins', function() {
    const now = new Date();
    const doc = {
      grant: { plan: 'pro', status: 'active', source: 'admin', periodEnd: null },
      web: { plan: 'pro', status: 'active', source: 'web', periodEnd: new Date(now.getTime() + 20 * DAY) },
    };
    expect(derive(doc, now).source).to.equal('admin');
  });

  it('writes the student source without disturbing other sources', async function() {
    const me = await signup();
    await writeSource(me.id, 'web', {
      plan: 'pro', status: 'active', source: 'web', periodEnd: new Date(Date.now() + 10 * DAY),
    });
    await student.grantStudentYear(me.id);
    const sub = await Subscription.findOne({ userId: me.id }).lean();
    expect(sub.web.plan).to.equal('pro');
    expect(sub.student.plan).to.equal('pro');
    expect(sub.source).to.equal('web');
  });

  describe('allowed domains', function() {
    it('matches the listed domain and its subdomains, nothing else', function() {
      expect(student.isListedUniversityEmail('a@uom.ac.lk')).to.equal(true);
      expect(student.isListedUniversityEmail('a@cse.mrt.ac.lk')).to.equal(true);
      expect(student.isListedUniversityEmail('a@mit.edu')).to.equal(true);
      expect(student.isListedUniversityEmail('a@gmail.com')).to.equal(false);
      expect(student.isListedUniversityEmail('a@notac.lk')).to.equal(false);
      expect(student.isListedUniversityEmail('a@ac.lk.evil.com')).to.equal(false);
      expect(student.isListedUniversityEmail('nodomain')).to.equal(false);
    });

    it('can be changed by editing the list', function() {
      student.setDomainsForTests(['example.org']);
      try {
        expect(student.isListedUniversityEmail('a@uni.example.org')).to.equal(true);
        expect(student.isListedUniversityEmail('a@mit.edu')).to.equal(false);
      } finally {
        student.setDomainsForTests(null);
      }
    });
  });

  describe('role (SP-15)', function() {
    it('defaults to user and cannot be set through signup', async function() {
      const res = await api().post('/api/auth/signup')
        .send({ email: 'role-try@example.com', password: 'password', role: 'superAdmin' });
      expect(res.status).to.equal(201);
      const user = await User.findOne({ email: 'role-try@example.com' }).lean();
      expect(user.role).to.equal('user');
    });

    it('is not exposed or changeable through any account route', async function() {
      const me = await signup();
      const res = await authed('post', '/api/auth/password', me.token)
        .send({ currentPassword: 'password', newPassword: 'password2', role: 'superAdmin' });
      expect(res.status).to.be.oneOf([200, 400]);
      expect((await User.findById(me.id).lean()).role).to.equal('user');
    });

    it('rejects anything but user and superAdmin in the model', async function() {
      const user = new User({ email: 'badrole@example.com', password: 'password', role: 'root' });
      let error;
      try { await user.validate(); } catch (err) { error = err; }
      expect(error).to.exist;
    });

    it('parses the grant-role arguments', function() {
      expect(parseArgs(['a@b.co', 'superAdmin', '--allow-remote'])).to.deep.equal({ email: 'a@b.co', role: 'superAdmin' });
      expect(ROLES).to.deep.equal(['user', 'superAdmin']);
    });
  });

  describe('config', function() {
    it('keeps renewal off by default and validates the flags', function() {
      expect(studentRenewalEnabled({})).to.equal(false);
      expect(studentRenewalEnabled({ STUDENT_RENEWAL_ENABLED: 'true' })).to.equal(true);
      expect(studentAdminEmail({})).to.equal(null);
      expect(studentAdminEmail({ STUDENT_ADMIN_EMAIL: ' o@x.co ' })).to.equal('o@x.co');
      const base = { CREDENTIALS_ENCRYPTION_KEY: process.env.CREDENTIALS_ENCRYPTION_KEY };
      expect(invalidConfig({ ...base, STUDENT_RENEWAL_ENABLED: 'yes' })).to.match(/STUDENT_RENEWAL_ENABLED/);
      expect(invalidConfig({ ...base, STUDENT_ADMIN_EMAIL: 'nope' })).to.match(/STUDENT_ADMIN_EMAIL/);
      expect(invalidConfig({ ...base, STUDENT_ADMIN_EMAIL: 'o@x.co' })).to.equal(null);
    });
  });
});

describe('Student plan: email code flow (SP-2)', function() {
  let transport;

  beforeEach(function() {
    transport = fakeTransport();
    setTransportForTests(transport);
    process.env.STUDENT_ADMIN_EMAIL = 'owner@example.com';
  });

  afterEach(function() {
    setTransportForTests(null);
    process.env.STUDENT_ADMIN_EMAIL = '';
    process.env.STUDENT_RENEWAL_ENABLED = '';
    process.env.BILLING_ENABLED = '';
  });

  it('needs a session', async function() {
    expect((await api().post('/api/student/email/start').send({ universityEmail: 'a@uom.ac.lk' })).status).to.equal(401);
    expect((await api().post('/api/student/email/confirm').send({ code: '123456' })).status).to.equal(401);
    expect((await api().get('/api/student')).status).to.equal(401);
  });

  it('refuses a missing or malformed university email', async function() {
    const me = await signup();
    expect((await start(me, '')).status).to.equal(400);
    expect((await start(me, 'not-an-email')).status).to.equal(400);
    expect((await start(me, { $gt: '' })).status).to.equal(400);
    expect(transport.sent).to.have.length(0);
  });

  it('points to the document fallback when the domain is not listed', async function() {
    const me = await signup();
    const res = await start(me, 'someone@gmail.com');
    expect(res.status).to.equal(400);
    expect(res.body.code).to.equal('domain_not_listed');
    expect(transport.sent).to.have.length(0);
  });

  it('emails a 6-digit code to the university address and stores only a hash', async function() {
    const me = await signup();
    const res = await start(me, '  Kasun@Uom.AC.lk ');
    expect(res.status).to.equal(202);
    expect(transport.sent).to.have.length(1);
    expect(transport.sent[0].to).to.equal('kasun@uom.ac.lk');
    const code = codeFrom(transport.sent[0]);
    expect(code).to.match(/^\d{6}$/);

    const stored = await StudentVerification.findOne({ userId: me.id }).select('+codeHash +codeSalt');
    expect(stored.codeHash).to.not.equal(code);
    expect(JSON.stringify(stored.toObject())).to.not.include(code);
    expect(stored.codeExpiresAt.getTime() - Date.now()).to.be.within(9 * 60 * 1000, 10 * 60 * 1000 + 1000);
    // Never in an API response.
    expect(JSON.stringify(res.body)).to.not.include(code);
    expect(JSON.stringify((await authed('get', '/api/student', me.token)).body)).to.not.include(stored.codeHash);
  });

  it('answers 503 when mail is off, instead of pretending a code was sent', async function() {
    setTransportForTests(null);
    const me = await signup();
    const res = await start(me, 'a@uom.ac.lk');
    expect(res.status).to.equal(503);
  });

  it('approves on the right code, grants 365 days at once, and tells the owner', async function() {
    const me = await signup();
    await start(me, 'ok@uom.ac.lk');
    const code = codeFrom(transport.sent[0]);

    const res = await confirm(me, code);
    expect(res.status).to.equal(200);
    expect(res.body.status).to.equal('approved');
    expect(new Date(res.body.expiresAt).getTime() - new Date(res.body.approvedAt).getTime()).to.equal(365 * DAY);

    process.env.BILLING_ENABLED = 'true';
    const ent = await entitlementsFor(me.id);
    expect(ent.plan).to.equal('pro');
    expect(ent.source).to.equal('student');

    // Owner email: details and a link, never a document.
    const notice = transport.sent.find((m) => m.to === 'owner@example.com');
    expect(notice).to.exist;
    expect(notice.text).to.include(me.email);
    expect(notice.text).to.include('ok@uom.ac.lk');
    expect(notice.text).to.include(`http://localhost:3000/admin/students/${res.body.id}`);
    expect(notice.attachments).to.equal(undefined);
    expect(notice.text).to.not.include(code);

    // The code is gone: it can't be used again.
    const again = await confirm(me, code);
    expect(again.status).to.equal(400);
    const status = await authed('get', '/api/student', me.token);
    expect(status.body.status).to.equal('approved');
  });

  it('works without an owner address (logged, nothing sent to the owner)', async function() {
    process.env.STUDENT_ADMIN_EMAIL = '';
    const me = await signup();
    await start(me, 'noowner@uom.ac.lk');
    const res = await confirm(me, codeFrom(transport.sent[0]));
    expect(res.status).to.equal(200);
    expect(transport.sent).to.have.length(1);
  });

  it('counts wrong codes and says how many tries are left', async function() {
    const me = await signup();
    await start(me, 'wrong@uom.ac.lk');
    const code = codeFrom(transport.sent[0]);
    const res = await confirm(me, wrongCode(code));
    expect(res.status).to.equal(400);
    expect(res.body.code).to.equal('wrong_code');
    expect(res.body.message).to.include('4 tries left');
    expect((await authed('get', '/api/student', me.token)).body.status).to.equal('pending');
  });

  it('locks the code after 5 wrong tries, even for the right code', async function() {
    const me = await signup();
    await start(me, 'lock@uom.ac.lk');
    const code = codeFrom(transport.sent[0]);
    for (let i = 0; i < 5; i += 1) {
      expect((await confirm(me, wrongCode(code))).status).to.equal(400);
    }
    const locked = await confirm(me, code);
    expect(locked.status).to.equal(429);
    expect(locked.body.code).to.equal('too_many_attempts');
    process.env.BILLING_ENABLED = 'true';
    expect((await entitlementsFor(me.id)).source).to.not.equal('student');

    // A new code starts a fresh count.
    await start(me, 'lock@uom.ac.lk');
    const fresh = codeFrom(transport.sent[transport.sent.length - 1]);
    expect((await confirm(me, fresh)).status).to.equal(200);
  });

  it('refuses an expired code', async function() {
    const me = await signup();
    await start(me, 'late@uom.ac.lk');
    const code = codeFrom(transport.sent[0]);
    await StudentVerification.updateOne({ userId: me.id }, { $set: { codeExpiresAt: new Date(Date.now() - 1000) } });
    const res = await confirm(me, code);
    expect(res.status).to.equal(400);
    expect(res.body.code).to.equal('code_expired');
  });

  it('refuses a malformed code and a confirm with no code requested', async function() {
    const me = await signup();
    expect((await confirm(me, '12345')).status).to.equal(400);
    expect((await confirm(me, 'abcdef')).status).to.equal(400);
    expect((await confirm(me, '123456')).body.code).to.equal('no_code');
  });

  it('a new code replaces the old one', async function() {
    const me = await signup();
    await start(me, 'two@uom.ac.lk');
    const first = codeFrom(transport.sent[0]);
    await start(me, 'two@uom.ac.lk');
    const second = codeFrom(transport.sent[1]);
    expect(await StudentVerification.countDocuments({ userId: me.id })).to.equal(1);
    if (first !== second) expect((await confirm(me, first)).status).to.equal(400);
    expect((await confirm(me, second)).status).to.equal(200);
  });

  it('allows one grant per person: a second application is refused', async function() {
    const me = await signup();
    await start(me, 'once@uom.ac.lk');
    await confirm(me, codeFrom(transport.sent[0]));
    const res = await start(me, 'other@uom.ac.lk');
    expect(res.status).to.equal(409);
    expect(res.body.code).to.equal('already_used');
  });

  it('keeps an expired grant blocking a new one while renewal is off, and allows it when on', async function() {
    const me = await signup();
    await start(me, 'renew@uom.ac.lk');
    await confirm(me, codeFrom(transport.sent[0]));
    await StudentVerification.updateOne({ userId: me.id }, { $set: { status: 'expired' } });

    const off = await start(me, 'renew@uom.ac.lk');
    expect(off.status).to.equal(409);

    process.env.STUDENT_RENEWAL_ENABLED = 'true';
    const on = await start(me, 'renew@uom.ac.lk'); // their own earlier email is fine
    expect(on.status).to.equal(202);
    const renewed = await confirm(me, codeFrom(transport.sent[transport.sent.length - 1]));
    expect(renewed.status).to.equal(200);
  });

  it('refuses a university email another account already used', async function() {
    const first = await signup();
    await start(first, 'shared@uom.ac.lk');
    await confirm(first, codeFrom(transport.sent[0]));

    const second = await signup();
    const res = await start(second, 'Shared@UOM.ac.lk');
    expect(res.status).to.equal(409);
    expect(res.body.code).to.equal('email_used');
    expect(transport.sent.filter((m) => m.to === 'shared@uom.ac.lk')).to.have.length(1);
  });

  it('refuses at confirm when the email was claimed in between', async function() {
    const slow = await signup();
    await start(slow, 'race@uom.ac.lk');
    const slowCode = codeFrom(transport.sent[0]);
    await student.claim('email', student.emailHash('race@uom.ac.lk'));
    const res = await confirm(slow, slowCode);
    expect(res.status).to.equal(409);
    expect(res.body.code).to.equal('email_used');
    process.env.BILLING_ENABLED = 'true';
    expect((await entitlementsFor(slow.id)).source).to.not.equal('student');
  });

  it('still blocks the email after the account is deleted and recreated', async function() {
    const first = await signup();
    await start(first, 'gone@uom.ac.lk');
    await confirm(first, codeFrom(transport.sent[0]));

    const del = await authed('delete', '/api/auth/account', first.token).send({ password: 'password' });
    expect(del.status).to.equal(200);
    expect(await StudentVerification.countDocuments({ userId: first.id })).to.equal(0);
    expect(await Subscription.countDocuments({ userId: first.id })).to.equal(0);

    // Only a one-way hash remains.
    const claims = await StudentClaim.find({ kind: 'email' }).lean();
    expect(claims.some((c) => c.hash === student.emailHash('gone@uom.ac.lk'))).to.equal(true);
    expect(JSON.stringify(claims)).to.not.include('gone@uom.ac.lk');
    expect(JSON.stringify(claims)).to.not.include(first.id);

    const again = await signup();
    const res = await start(again, 'gone@uom.ac.lk');
    expect(res.status).to.equal(409);
    expect(res.body.code).to.equal('email_used');
  });

  it('reports no application for a new user', async function() {
    const me = await signup();
    const res = await authed('get', '/api/student', me.token);
    expect(res.status).to.equal(200);
    expect(res.body).to.deep.equal({ status: 'none' });
  });

  it('does nothing while billing is off: everyone is Pro either way', async function() {
    const me = await signup();
    await start(me, 'billingoff@uom.ac.lk');
    await confirm(me, codeFrom(transport.sent[0]));
    const res = await authed('get', '/api/subscription', me.token);
    expect(res.body.billingEnabled).to.equal(false);
    expect(res.body.plan).to.equal('pro');
  });
});
