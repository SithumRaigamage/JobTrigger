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
const jobs = require('../lib/studentJobs');
const { decrypt } = require('../security/secretCipher');

const DAY = 24 * 60 * 60 * 1000;
const PNG = Buffer.concat([Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]), Buffer.from('fake png body')]);
const JPG = Buffer.concat([Buffer.from([0xff, 0xd8, 0xff, 0xe0]), Buffer.from('fake jpg body')]);
const PDF = Buffer.from('%PDF-1.4\nfake pdf body');
const unique = (base) => Buffer.concat([base, crypto.randomBytes(16)]);

let counter = 0;
async function signup() {
  counter += 1;
  const email = `doc${counter}@example.com`;
  const res = await api().post('/api/auth/signup').send({ email, password: 'password' });
  return { ...res.body, email, id: res.body.user._id, token: res.body.token ?? res.body.accessToken };
}
async function makeAdmin() {
  const me = await signup();
  await User.updateOne({ _id: me.id }, { $set: { role: 'superAdmin' } });
  return me;
}
const authed = (method, path, token) => api()[method](path).set('x-auth-token', token);
const upload = (me, bytes, fullName = 'Kasun Perera') =>
  authed('post', '/api/student/document', me.token).send({ fullName, data: bytes.toString('base64') });
function fakeTransport() {
  const sent = [];
  return { sent, sendMail: async (m) => { sent.push(m); return { messageId: `m${sent.length}` }; } };
}

describe('Student plan: document upload (SP-30)', function() {
  let transport;
  beforeEach(function() {
    transport = fakeTransport();
    setTransportForTests(transport);
    process.env.STUDENT_ADMIN_EMAIL = 'owner@example.com';
  });
  afterEach(function() {
    setTransportForTests(null);
    process.env.STUDENT_ADMIN_EMAIL = '';
    process.env.BILLING_ENABLED = '';
  });

  it('needs a session', async function() {
    expect((await api().post('/api/student/document').send({})).status).to.equal(401);
  });

  it('accepts JPG, PNG and PDF, decided by the file bytes', async function() {
    for (const bytes of [unique(JPG), unique(PNG), unique(PDF)]) {
      const me = await signup();
      const res = await upload(me, bytes);
      expect(res.status, JSON.stringify(res.body)).to.equal(201);
      expect(res.body.status).to.equal('pending');
      expect(res.body.method).to.equal('document');
    }
  });

  it('requires the full name as on the student ID', async function() {
    const me = await signup();
    for (const name of ['', ' ', 'A', 'x'.repeat(101), undefined, { $gt: '' }]) {
      const res = await authed('post', '/api/student/document', me.token)
        .send({ fullName: name, data: unique(PNG).toString('base64') });
      expect(res.status).to.equal(400);
    }
    expect(await StudentVerification.countDocuments({ userId: me.id })).to.equal(0);
  });

  it('rejects a file over 5 MB with a clear message', async function() {
    const me = await signup();
    const big = Buffer.concat([PNG, Buffer.alloc(5 * 1024 * 1024)]);
    const res = await upload(me, big);
    expect(res.status).to.equal(413);
    expect(res.body.message).to.equal('File too large, max 5 MB');
  });

  it('accepts a file just under 5 MB', async function() {
    const me = await signup();
    const ok = Buffer.concat([PNG, crypto.randomBytes(5 * 1024 * 1024 - PNG.length - 10)]);
    const res = await upload(me, ok);
    expect(res.status, JSON.stringify(res.body)).to.equal(201);
  });

  it('rejects a body far over the limit with the same message', async function() {
    const me = await signup();
    const res = await authed('post', '/api/student/document', me.token)
      .send({ fullName: 'Kasun Perera', data: 'A'.repeat(8 * 1024 * 1024) });
    expect(res.status).to.equal(413);
    expect(res.body.message).to.equal('File too large, max 5 MB');
  });

  it('rejects other types, even when the name says image', async function() {
    const me = await signup();
    for (const bytes of [Buffer.from('<html><script>alert(1)</script></html>'), Buffer.from('MZ\u0090 an exe'), Buffer.from('GIF89a....')]) {
      const res = await upload(me, bytes);
      expect(res.status).to.equal(415);
      expect(res.body.message).to.equal('Only JPG, PNG or PDF files are accepted');
    }
    const named = await authed('post', '/api/student/document', me.token)
      .send({ fullName: 'Kasun Perera', fileName: 'id.png', mimeType: 'image/png', data: Buffer.from('not an image').toString('base64') });
    expect(named.status).to.equal(415);
  });

  it('rejects missing or malformed data', async function() {
    const me = await signup();
    for (const data of [undefined, '', 'not base64!!', 'abc', 123, { a: 1 }]) {
      const res = await authed('post', '/api/student/document', me.token).send({ fullName: 'Kasun Perera', data });
      expect(res.status).to.equal(400);
    }
  });

  it('stores the document encrypted, with the name, and never returns it', async function() {
    const me = await signup();
    const bytes = unique(PNG);
    const res = await upload(me, bytes, '  Kasun   Perera ');
    expect(JSON.stringify(res.body)).to.not.include(bytes.toString('base64').slice(0, 40));

    const stored = await StudentVerification.findOne({ userId: me.id }).select('+documentData');
    expect(stored.fullName).to.equal('Kasun Perera');
    expect(stored.documentData.startsWith('enc:v1:')).to.equal(true);
    expect(stored.documentData).to.not.include(bytes.toString('base64').slice(0, 40));
    expect(decrypt(stored.documentData, 'studentVerification.documentData')).to.equal(bytes.toString('base64'));
    expect(stored.documentHash).to.equal(student.documentHash(bytes));
    expect(stored.documentMime).to.equal('image/png');
    expect(stored.documentSize).to.equal(bytes.length);
    expect(JSON.stringify(stored.toJSON())).to.not.include('enc:v1:');

    const status = await authed('get', '/api/student', me.token);
    expect(status.body.status).to.equal('pending');
    expect(JSON.stringify(status.body)).to.not.include('enc:v1:');
  });

  it('emails the owner the name and a link, with no attachment', async function() {
    const me = await signup();
    const res = await upload(me, unique(PDF), 'Nimali Silva');
    const notice = transport.sent.find((m) => m.to === 'owner@example.com');
    expect(notice).to.exist;
    expect(notice.text).to.include('Full name on ID: Nimali Silva');
    expect(notice.text).to.include(me.email);
    expect(notice.text).to.include(`http://localhost:3000/admin/students/${res.body.id}`);
    expect(notice.attachments).to.equal(undefined);
    expect(notice.text).to.not.include('JVBER'); // no base64 of the file
  });

  it('keeps the email path free of a name', async function() {
    const me = await signup();
    await authed('post', '/api/student/email/start', me.token).send({ universityEmail: 'noname@uom.ac.lk' });
    const code = /code is (\d{6})/.exec(transport.sent[0].text)[1];
    await authed('post', '/api/student/email/confirm', me.token).send({ code });
    const notice = transport.sent.find((m) => m.to === 'owner@example.com');
    expect(notice.text).to.not.include('Full name');
  });

  it('allows one open application: a second upload is refused', async function() {
    const me = await signup();
    expect((await upload(me, unique(PNG))).status).to.equal(201);
    const again = await upload(me, unique(PNG));
    expect(again.status).to.equal(409);
    expect(again.body.code).to.equal('under_review');
  });

  it('lets a rejected user try again', async function() {
    const me = await signup();
    const first = await upload(me, unique(PNG));
    await StudentVerification.updateOne({ _id: first.body.id }, { $set: { status: 'rejected', rejectionReason: 'Blurry' } });
    expect((await upload(me, unique(PNG))).status).to.equal(201);
  });

  it('refuses the same document from another account', async function() {
    const bytes = unique(PNG);
    const a = await signup();
    const b = await signup();
    expect((await upload(a, bytes)).status).to.equal(201);
    const res = await upload(b, bytes);
    expect(res.status).to.equal(409);
    expect(res.body.code).to.equal('document_used');
  });

  it('switching from a code request to a document drops the unfinished code', async function() {
    const me = await signup();
    await authed('post', '/api/student/email/start', me.token).send({ universityEmail: 'switch@uom.ac.lk' });
    expect(await StudentVerification.countDocuments({ userId: me.id, method: 'email' })).to.equal(1);
    await upload(me, unique(PNG));
    expect(await StudentVerification.countDocuments({ userId: me.id, method: 'email' })).to.equal(0);
  });
});

describe('Student plan: admin review (SP-31)', function() {
  let transport;
  beforeEach(function() {
    transport = fakeTransport();
    setTransportForTests(transport);
  });
  afterEach(function() {
    setTransportForTests(null);
    process.env.BILLING_ENABLED = '';
    process.env.STUDENT_RENEWAL_ENABLED = '';
  });

  const admin = (method, path, me) => authed(method, `/api/admin/students${path}`, me.token);

  it('answers 404 to everyone who is not a super admin, like an unknown route', async function() {
    const plain = await signup();
    const target = await signup();
    const sub = await upload(target, unique(PNG));
    for (const [method, path] of [
      ['get', ''], ['get', `/${sub.body.id}`], ['get', `/${sub.body.id}/document`],
      ['post', `/${sub.body.id}/approve`], ['post', `/${sub.body.id}/reject`],
    ]) {
      const res = await admin(method, path, plain).send({ reason: 'x' });
      expect(res.status, `${method} ${path}`).to.equal(404);
      expect(res.body).to.deep.equal({ message: 'Not found' });
    }
    const unknown = await authed('get', '/api/nope-not-here', plain.token);
    expect(unknown.body).to.deep.equal({ message: 'Not found' });
    expect((await StudentVerification.findById(sub.body.id)).status).to.equal('pending');
  });

  it('needs a session at all', async function() {
    expect((await api().get('/api/admin/students')).status).to.equal(401);
  });

  it('checks the role in the database: revoking it takes effect at once', async function() {
    const boss = await makeAdmin();
    expect((await admin('get', '', boss)).status).to.equal(200);
    await User.updateOne({ _id: boss.id }, { $set: { role: 'user' } });
    expect((await admin('get', '', boss)).status).to.equal(404);
  });

  it('lists pending document applications without any document data', async function() {
    const boss = await makeAdmin();
    const s = await signup();
    const sub = await upload(s, unique(PNG), 'Amal Fernando');
    const res = await admin('get', '', boss);
    expect(res.status).to.equal(200);
    const item = res.body.items.find((i) => i.id === sub.body.id);
    expect(item).to.include({ accountEmail: s.email, fullName: 'Amal Fernando', status: 'pending', method: 'document', hasDocument: true });
    expect(JSON.stringify(res.body)).to.not.include('enc:v1:');
    expect(res.headers['cache-control']).to.include('no-store');
  });

  it('does not list email-code applications as pending reviews', async function() {
    const boss = await makeAdmin();
    const s = await signup();
    setTransportForTests(fakeTransport());
    await authed('post', '/api/student/email/start', s.token).send({ universityEmail: 'listme@uom.ac.lk' });
    const res = await admin('get', '', boss);
    expect(res.body.items.some((i) => i.accountEmail === s.email)).to.equal(false);
  });

  it('searches by account email or name, and filters by status', async function() {
    const boss = await makeAdmin();
    const s = await signup();
    const sub = await upload(s, unique(PNG), 'Zanele Findable');
    const byEmail = await admin('get', `?q=${encodeURIComponent(s.email.toUpperCase())}`, boss);
    expect(byEmail.body.items.map((i) => i.id)).to.include(sub.body.id);
    const byName = await admin('get', '?q=findable', boss);
    expect(byName.body.items.map((i) => i.id)).to.include(sub.body.id);
    const none = await admin('get', '?q=.*', boss); // treated literally, not a regex
    expect(none.body.items).to.have.length(0);
    const approvedOnly = await admin('get', '?status=approved', boss);
    expect(approvedOnly.body.items.map((i) => i.id)).to.not.include(sub.body.id);
    expect((await admin('get', '?status=bogus', boss)).status).to.equal(400);
  });

  it('streams the document with no-store, its real type, and sandbox headers', async function() {
    const boss = await makeAdmin();
    const s = await signup();
    const bytes = unique(PDF);
    const sub = await upload(s, bytes);
    const res = await admin('get', `/${sub.body.id}/document`, boss).buffer(true).parse((r, cb) => {
      const chunks = [];
      r.on('data', (c) => chunks.push(c));
      r.on('end', () => cb(null, Buffer.concat(chunks)));
    });
    expect(res.status).to.equal(200);
    expect(res.headers['content-type']).to.include('application/pdf');
    expect(res.headers['cache-control']).to.equal('no-store');
    expect(res.headers['x-content-type-options']).to.equal('nosniff');
    expect(res.headers['content-security-policy']).to.include('sandbox');
    expect(Buffer.compare(res.body, bytes)).to.equal(0);
  });

  it('approves: Pro for 365 days, keeps the document hash, schedules deletion in 30 days', async function() {
    const boss = await makeAdmin();
    const s = await signup();
    const bytes = unique(PNG);
    const sub = await upload(s, bytes);
    const res = await admin('post', `/${sub.body.id}/approve`, boss);
    expect(res.status, JSON.stringify(res.body)).to.equal(200);
    expect(res.body.status).to.equal('approved');

    process.env.BILLING_ENABLED = 'true';
    const ent = await entitlementsFor(s.id);
    expect(ent.plan).to.equal('pro');
    expect(ent.source).to.equal('student');
    expect(new Date(ent.periodEnd).getTime() - new Date(res.body.approvedAt).getTime()).to.equal(365 * DAY);

    const stored = await StudentVerification.findById(sub.body.id);
    expect(String(stored.reviewedBy)).to.equal(boss.id);
    expect(stored.documentDeleteAt.getTime() - stored.reviewedAt.getTime()).to.equal(30 * DAY);
    expect(await StudentClaim.exists({ kind: 'document', hash: student.documentHash(bytes) })).to.exist;

    const again = await admin('post', `/${sub.body.id}/approve`, boss);
    expect(again.status).to.equal(409);
    const status = await authed('get', '/api/student', s.token);
    expect(status.body.status).to.equal('approved');
  });

  it('rejects with a required reason, which the student sees, and they can try again', async function() {
    const boss = await makeAdmin();
    const s = await signup();
    const sub = await upload(s, unique(PNG));
    expect((await admin('post', `/${sub.body.id}/reject`, boss).send({})).status).to.equal(400);
    expect((await admin('post', `/${sub.body.id}/reject`, boss).send({ reason: 'x'.repeat(501) })).status).to.equal(400);
    const res = await admin('post', `/${sub.body.id}/reject`, boss).send({ reason: 'The photo is too blurry to read.' });
    expect(res.status).to.equal(200);
    expect(res.body.status).to.equal('rejected');

    const status = await authed('get', '/api/student', s.token);
    expect(status.body).to.include({ status: 'rejected', rejectionReason: 'The photo is too blurry to read.' });
    process.env.BILLING_ENABLED = 'true';
    expect((await entitlementsFor(s.id)).source).to.not.equal('student');
    expect(await StudentClaim.countDocuments({ kind: 'document' , hash: (await StudentVerification.findById(sub.body.id)).documentHash })).to.equal(0);
    expect((await upload(s, unique(PNG))).status).to.equal(201);

    const decided = await admin('post', `/${sub.body.id}/reject`, boss).send({ reason: 'again' });
    expect(decided.status).to.equal(409);
  });

  it('leaves a pending application pending when its document was claimed by another', async function() {
    const boss = await makeAdmin();
    const s = await signup();
    const bytes = unique(PNG);
    const sub = await upload(s, bytes);
    await student.claim('document', student.documentHash(bytes));
    const res = await admin('post', `/${sub.body.id}/approve`, boss);
    expect(res.status).to.equal(409);
    expect(res.body.code).to.equal('document_used');
    expect((await StudentVerification.findById(sub.body.id)).status).to.equal('pending');
  });

  it('404s for unknown or malformed ids and email-code applications', async function() {
    const boss = await makeAdmin();
    expect((await admin('get', '/not-an-id', boss)).status).to.equal(404);
    expect((await admin('get', '/64b000000000000000000000', boss)).status).to.equal(404);
    expect((await admin('post', '/64b000000000000000000000/approve', boss)).status).to.equal(404);
    expect((await admin('post', '/64b000000000000000000000/reject', boss).send({ reason: 'r' })).status).to.equal(404);
    expect((await admin('get', '/64b000000000000000000000/document', boss)).status).to.equal(404);
  });

  it('a student who deletes their account takes the application with them; the hash stays', async function() {
    const s = await signup();
    const bytes = unique(PNG);
    await upload(s, bytes);
    const boss = await makeAdmin();
    const pending = (await admin('get', '', boss)).body.items.find((i) => i.accountEmail === s.email);
    await admin('post', `/${pending.id}/approve`, boss);
    await authed('delete', '/api/auth/account', s.token).send({ password: 'password' });
    expect(await StudentVerification.countDocuments({ userId: s.id })).to.equal(0);
    expect(await Subscription.countDocuments({ userId: s.id })).to.equal(0);
    const second = await signup();
    const res = await upload(second, bytes);
    expect(res.status).to.equal(409);
    expect(res.body.code).to.equal('document_used');
  });
});

describe('Student plan: deleting documents after 30 days (SP-32)', function() {
  beforeEach(function() { setTransportForTests(fakeTransport()); });
  afterEach(function() { setTransportForTests(null); });

  it('removes the bytes and the name 30 days after a decision, and keeps the hash', async function() {
    const boss = await makeAdmin();
    const s = await signup();
    const bytes = unique(PNG);
    const sub = await upload(s, bytes);
    await authed('post', `/api/admin/students/${sub.body.id}/approve`, boss.token);

    const decidedAt = (await StudentVerification.findById(sub.body.id)).reviewedAt;
    expect(await jobs.purgeDecidedDocuments(new Date(decidedAt.getTime() + 29 * DAY))).to.equal(0);
    expect((await StudentVerification.findById(sub.body.id).select('+documentData')).documentData).to.be.a('string');

    expect(await jobs.purgeDecidedDocuments(new Date(decidedAt.getTime() + 31 * DAY))).to.be.at.least(1);
    const after = await StudentVerification.findById(sub.body.id).select('+documentData');
    expect(after.documentData).to.equal(null);
    expect(after.fullName).to.equal(null);
    expect(after.documentHash).to.equal(student.documentHash(bytes));
    expect(after.documentDeletedAt).to.be.instanceOf(Date);
    expect(await StudentClaim.exists({ kind: 'document', hash: student.documentHash(bytes) })).to.exist;

    const res = await authed('get', `/api/admin/students/${sub.body.id}/document`, boss.token);
    expect(res.status).to.equal(410);
    const detail = await authed('get', `/api/admin/students/${sub.body.id}`, boss.token);
    expect(detail.body).to.include({ hasDocument: false, documentDeleted: true, fullName: null });
    // The grant itself is untouched.
    process.env.BILLING_ENABLED = 'true';
    expect((await entitlementsFor(s.id)).source).to.equal('student');
    process.env.BILLING_ENABLED = '';
  });

  it('also covers rejected applications and leaves undecided ones alone', async function() {
    const boss = await makeAdmin();
    const rejected = await signup();
    const waiting = await signup();
    const r = await upload(rejected, unique(PNG));
    const w = await upload(waiting, unique(PNG));
    await authed('post', `/api/admin/students/${r.body.id}/reject`, boss.token).send({ reason: 'No' });
    await jobs.purgeDecidedDocuments(new Date(Date.now() + 40 * DAY));
    expect((await StudentVerification.findById(r.body.id).select('+documentData')).documentData).to.equal(null);
    expect((await StudentVerification.findById(w.body.id).select('+documentData')).documentData).to.be.a('string');
  });

  it('runAll reports what it did and never throws', async function() {
    const summary = await jobs.runAll();
    expect(summary).to.have.property('documentsDeleted');
  });
});
