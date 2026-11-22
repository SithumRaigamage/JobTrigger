const { api } = require('./support/api');
const { expect } = require('chai');
const crypto = require('crypto');
const Subscription = require('../models/Subscription');
const StudentVerification = require('../models/StudentVerification');
const StudentClaim = require('../models/StudentClaim');
const User = require('../models/User');
const { setTransportForTests } = require('../lib/mailer');
const { entitlementsFor } = require('../billing/entitlements');
const student = require('../lib/student');

/*
 * US-STU-01…03 (owner decision 2026-11-22): every student application,
 * including a verified university email, waits for a super admin; the
 * admin API serves the app as well as the website, with history.
 */

const DAY = 24 * 60 * 60 * 1000;
const PNG = Buffer.concat([Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]), Buffer.from('fake png body')]);
const unique = (base) => Buffer.concat([base, crypto.randomBytes(16)]);

let counter = 0;
async function signup() {
  counter += 1;
  const email = `review${counter}@example.com`;
  const res = await api().post('/api/auth/signup').send({ email, password: 'password' });
  return { ...res.body, email, id: res.body.user._id, token: res.body.token ?? res.body.accessToken };
}
async function makeAdmin() {
  const me = await signup();
  await User.updateOne({ _id: me.id }, { $set: { role: 'superAdmin' } });
  return me;
}
const authed = (method, path, token) => api()[method](path).set('x-auth-token', token);
const admin = (method, path, me) => authed(method, `/api/admin/students${path}`, me.token);
const codeFrom = (message) => /code is (\d{6})/.exec(message.text)[1];

function fakeTransport() {
  const sent = [];
  return { sent, sendMail: async (m) => { sent.push(m); return { messageId: `m${sent.length}` }; } };
}

describe('Student plan: manual review of every application (US-STU-01…03)', function() {
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

  async function codeRequest(me, universityEmail) {
    const res = await authed('post', '/api/student/email/start', me.token).send({ universityEmail });
    expect(res.status).to.equal(202);
    const message = transport.sent.filter((m) => m.to === universityEmail).pop();
    return codeFrom(message);
  }
  async function verifiedEmail(me, universityEmail) {
    const code = await codeRequest(me, universityEmail);
    const res = await authed('post', '/api/student/email/confirm', me.token).send({ code });
    expect(res.status).to.equal(200);
    return res.body;
  }
  const upload = (me, bytes = unique(PNG)) =>
    authed('post', '/api/student/document', me.token).send({ fullName: 'Kasun Perera', data: bytes.toString('base64') });

  describe('US-STU-01: the email path waits for approval', function() {
    it('sends the owner notice when the email is verified, not when the code is asked for', async function() {
      const me = await signup();
      await codeRequest(me, 'notice@uom.ac.lk');
      expect(transport.sent.filter((m) => m.to === 'owner@example.com')).to.have.length(0);
      const app = await verifiedEmail(me, 'notice@uom.ac.lk');
      const notices = transport.sent.filter((m) => m.to === 'owner@example.com');
      expect(notices).to.have.length(1);
      expect(notices[0].subject).to.include('to review');
      expect(notices[0].text).to.include(`/admin/students/${app.id}`);
      expect(notices[0].text).to.include('Status: pending');
    });

    it('a code request is not an application: none for the student, not listed for review', async function() {
      const boss = await makeAdmin();
      const me = await signup();
      await codeRequest(me, 'waiting@uom.ac.lk');
      expect((await authed('get', '/api/student', me.token)).body).to.deep.equal({ status: 'none' });
      for (const status of ['pending', 'all']) {
        const list = await admin('get', `?status=${status}`, boss);
        expect(list.body.items.some((i) => i.accountEmail === me.email), status).to.equal(false);
      }
    });

    it('a verified email blocks a second code or a document with under_review', async function() {
      const me = await signup();
      await verifiedEmail(me, 'block@uom.ac.lk');
      const again = await authed('post', '/api/student/email/start', me.token).send({ universityEmail: 'block2@uom.ac.lk' });
      expect(again.status).to.equal(409);
      expect(again.body.code).to.equal('under_review');
      const doc = await upload(me);
      expect(doc.status).to.equal(409);
      expect(doc.body.code).to.equal('under_review');
      expect(await StudentVerification.countDocuments({ userId: me.id })).to.equal(1);
    });

    it('a university email waiting for review on another account is taken', async function() {
      const first = await signup();
      await verifiedEmail(first, 'twice@uom.ac.lk');
      const second = await signup();
      const res = await authed('post', '/api/student/email/start', second.token).send({ universityEmail: 'twice@uom.ac.lk' });
      expect(res.status).to.equal(409);
      expect(res.body.code).to.equal('email_used');
    });

    it('refuses at confirm when another account verified the same email in between', async function() {
      const first = await signup();
      const second = await signup();
      const firstCode = await codeRequest(first, 'between@uom.ac.lk');
      const secondCode = await codeRequest(second, 'between@uom.ac.lk');
      expect((await authed('post', '/api/student/email/confirm', first.token).send({ code: firstCode })).status).to.equal(200);
      const res = await authed('post', '/api/student/email/confirm', second.token).send({ code: secondCode });
      expect(res.status).to.equal(409);
      expect(res.body.code).to.equal('email_used');
    });

    it('approving an email application grants 365 days, claims the email and records the reviewer', async function() {
      const boss = await makeAdmin();
      const me = await signup();
      const app = await verifiedEmail(me, 'approve@uom.ac.lk');
      const before = Date.now();
      const res = await admin('post', `/${app.id}/approve`, boss);
      expect(res.status).to.equal(200);
      expect(res.body).to.include({ status: 'approved', method: 'email', reviewedBy: boss.id, reviewedByEmail: boss.email });
      expect(new Date(res.body.expiresAt).getTime() - new Date(res.body.approvedAt).getTime()).to.equal(365 * DAY);
      expect(new Date(res.body.approvedAt).getTime()).to.be.at.least(before - 1000);
      expect(res.body.documentDeleteAt).to.equal(null);

      process.env.BILLING_ENABLED = 'true';
      const ent = await entitlementsFor(me.id);
      expect(ent.plan).to.equal('pro');
      expect(ent.source).to.equal('student');
      expect(await StudentClaim.countDocuments({ kind: 'email', hash: student.emailHash('approve@uom.ac.lk') })).to.equal(1);
      expect((await authed('get', '/api/student', me.token)).body.status).to.equal('approved');
    });

    it('approving when the email was claimed in between is 409 and leaves it pending', async function() {
      const boss = await makeAdmin();
      const me = await signup();
      const app = await verifiedEmail(me, 'claimed@uom.ac.lk');
      await student.claim('email', student.emailHash('claimed@uom.ac.lk'));
      const res = await admin('post', `/${app.id}/approve`, boss);
      expect(res.status).to.equal(409);
      expect(res.body.code).to.equal('email_used');
      expect((await StudentVerification.findById(app.id)).status).to.equal('pending');
      process.env.BILLING_ENABLED = 'true';
      expect((await entitlementsFor(me.id)).source).to.not.equal('student');
    });

    it('rejecting an email application needs a reason, claims nothing, and lets the student try again', async function() {
      const boss = await makeAdmin();
      const me = await signup();
      const app = await verifiedEmail(me, 'reject@uom.ac.lk');
      expect((await admin('post', `/${app.id}/reject`, boss).send({})).status).to.equal(400);
      expect((await admin('post', `/${app.id}/reject`, boss).send({ reason: 'x'.repeat(501) })).status).to.equal(400);

      const res = await admin('post', `/${app.id}/reject`, boss).send({ reason: 'Not a student address' });
      expect(res.status).to.equal(200);
      expect(res.body).to.include({ status: 'rejected', rejectionReason: 'Not a student address', reviewedByEmail: boss.email });
      expect(res.body.documentDeleteAt).to.equal(null);
      expect(await StudentClaim.countDocuments({ hash: student.emailHash('reject@uom.ac.lk') })).to.equal(0);

      const seen = await authed('get', '/api/student', me.token);
      expect(seen.body).to.include({ status: 'rejected', rejectionReason: 'Not a student address', method: 'email' });
      expect((await authed('post', '/api/student/email/start', me.token).send({ universityEmail: 'reject@uom.ac.lk' })).status).to.equal(202);
      expect((await admin('post', `/${app.id}/approve`, boss)).status).to.equal(409);
    });

    it('an email application still waiting for its code cannot be approved or rejected', async function() {
      const boss = await makeAdmin();
      const me = await signup();
      await codeRequest(me, 'unverified@uom.ac.lk');
      const record = await StudentVerification.findOne({ userId: me.id });
      const approve = await admin('post', `/${record._id}/approve`, boss);
      expect(approve.status).to.equal(409);
      expect(approve.body.code).to.equal('not_verified');
      const reject = await admin('post', `/${record._id}/reject`, boss).send({ reason: 'no' });
      expect(reject.status).to.equal(409);
      expect((await StudentVerification.findById(record._id)).status).to.equal('pending');
    });

    it('with renewal on, a person may be approved again for their own earlier email', async function() {
      process.env.STUDENT_RENEWAL_ENABLED = 'true';
      const boss = await makeAdmin();
      const me = await signup();
      const first = await verifiedEmail(me, 'again@uom.ac.lk');
      expect((await admin('post', `/${first.id}/approve`, boss)).status).to.equal(200);
      await StudentVerification.updateOne({ _id: first.id }, { $set: { status: 'expired' } });
      const second = await verifiedEmail(me, 'again@uom.ac.lk');
      expect((await admin('post', `/${second.id}/approve`, boss)).status).to.equal(200);
    });
  });

  describe('US-STU-02: the app can ask for access', function() {
    it('answers a super admin with the role and everyone else with the plain 404', async function() {
      const boss = await makeAdmin();
      const plain = await signup();
      const ok = await admin('get', '/access', boss);
      expect(ok.status).to.equal(200);
      expect(ok.body).to.deep.equal({ role: 'superAdmin' });
      expect(ok.headers['cache-control']).to.include('no-store');
      const no = await admin('get', '/access', plain);
      expect(no.status).to.equal(404);
      expect(no.body).to.deep.equal({ message: 'Not found' });
      expect((await api().get('/api/admin/students/access')).status).to.equal(401);
    });

    it('keeps role off the account routes', async function() {
      const boss = await makeAdmin();
      const login = await api().post('/api/auth/login').send({ email: boss.email, password: 'password' });
      expect(login.status).to.equal(200);
      expect(JSON.stringify(login.body)).to.not.include('superAdmin');
      expect(JSON.stringify(login.body)).to.not.include('"role"');
    });
  });

  describe('US-STU-02/03: list and history', function() {
    it('lists pending email and document applications together, newest first', async function() {
      const boss = await makeAdmin();
      const a = await signup();
      const b = await signup();
      const emailApp = await verifiedEmail(a, 'listed@uom.ac.lk');
      await new Promise((r) => setTimeout(r, 5));
      const docApp = (await upload(b)).body;

      const res = await admin('get', '', boss);
      expect(res.status).to.equal(200);
      const ids = res.body.items.map((i) => i.id);
      expect(ids).to.include(emailApp.id);
      expect(ids).to.include(docApp.id);
      expect(ids.indexOf(docApp.id)).to.be.below(ids.indexOf(emailApp.id));
      const times = res.body.items.map((i) => new Date(i.submittedAt).getTime());
      expect([...times].sort((x, y) => y - x)).to.deep.equal(times);

      const item = res.body.items.find((i) => i.id === emailApp.id);
      expect(item).to.include({ method: 'email', status: 'pending', universityEmail: 'listed@uom.ac.lk', accountEmail: a.email, hasDocument: false });
      expect(item.emailVerifiedAt).to.be.a('string');
      expect(item.reviewedByEmail).to.equal(null);
    });

    it('filters history by status for both methods, with dates and the reviewer', async function() {
      const boss = await makeAdmin();
      const a = await signup();
      const b = await signup();
      const approved = await verifiedEmail(a, 'history@uom.ac.lk');
      await admin('post', `/${approved.id}/approve`, boss);
      const rejected = (await upload(b)).body;
      await admin('post', `/${rejected.id}/reject`, boss).send({ reason: 'Blurry' });

      const ap = await admin('get', '?status=approved', boss);
      const apItem = ap.body.items.find((i) => i.id === approved.id);
      expect(apItem).to.include({ status: 'approved', reviewedByEmail: boss.email });
      expect(apItem.reviewedAt).to.be.a('string');
      expect(ap.body.items.every((i) => i.status === 'approved')).to.equal(true);

      const rj = await admin('get', '?status=rejected', boss);
      expect(rj.body.items.find((i) => i.id === rejected.id)).to.include({ method: 'document', rejectionReason: 'Blurry', reviewedByEmail: boss.email });
      expect(rj.body.items.some((i) => i.id === approved.id)).to.equal(false);

      const all = await admin('get', '?status=all', boss);
      const allIds = all.body.items.map((i) => i.id);
      expect(allIds).to.include.members([approved.id, rejected.id]);

      await StudentVerification.updateOne({ _id: approved.id }, { $set: { status: 'expired' } });
      const ex = await admin('get', '?status=expired', boss);
      expect(ex.body.items.some((i) => i.id === approved.id)).to.equal(true);
      expect((await admin('get', '?status=bogus', boss)).status).to.equal(400);
    });

    it('searches by university email too', async function() {
      const boss = await makeAdmin();
      const a = await signup();
      const app = await verifiedEmail(a, 'findme@uom.ac.lk');
      const res = await admin('get', '?status=all&q=findme@uom', boss);
      expect(res.body.items.map((i) => i.id)).to.deep.equal([app.id]);
    });

    it('shows a deleted reviewer as null', async function() {
      const boss = await makeAdmin();
      const other = await makeAdmin();
      const a = await signup();
      const app = await verifiedEmail(a, 'gonereviewer@uom.ac.lk');
      await admin('post', `/${app.id}/approve`, boss);
      await User.deleteOne({ _id: boss.id });
      const res = await admin('get', `/${app.id}`, other);
      expect(res.body.reviewedBy).to.equal(boss.id);
      expect(res.body.reviewedByEmail).to.equal(null);
    });

    it('never serves a document for an email application', async function() {
      const boss = await makeAdmin();
      const a = await signup();
      const app = await verifiedEmail(a, 'nodoc@uom.ac.lk');
      expect((await admin('get', `/${app.id}/document`, boss)).status).to.equal(404);
    });
  });

  it('journey: verify → no Pro → approve → Pro, and the subscription stays one source', async function() {
    process.env.BILLING_ENABLED = 'true';
    const boss = await makeAdmin();
    const me = await signup();
    const app = await verifiedEmail(me, 'journey@uom.ac.lk');
    expect((await entitlementsFor(me.id)).plan).to.equal('free');
    await admin('post', `/${app.id}/approve`, boss);
    expect((await entitlementsFor(me.id)).plan).to.equal('pro');
    const sub = await Subscription.findOne({ userId: me.id }).lean();
    expect(sub.student.source).to.equal('student');
  });
});
