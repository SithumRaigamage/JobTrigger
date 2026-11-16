const { api } = require('./support/api');
const { expect } = require('chai');
const Subscription = require('../models/Subscription');
const StudentVerification = require('../models/StudentVerification');
const { setTransportForTests } = require('../lib/mailer');
const { entitlementsFor } = require('../billing/entitlements');
const { writeSource } = require('../billing/combine');
const student = require('../lib/student');
const jobs = require('../lib/studentJobs');

const DAY = 24 * 60 * 60 * 1000;

let counter = 0;
async function signup() {
  counter += 1;
  const email = `jobs${counter}@example.com`;
  const res = await api().post('/api/auth/signup').send({ email, password: 'password' });
  return { ...res.body, email, id: res.body.user._id, token: res.body.token ?? res.body.accessToken };
}
const authed = (method, path, token) => api()[method](path).set('x-auth-token', token);
function fakeTransport() {
  const sent = [];
  return { sent, sendMail: async (m) => { sent.push(m); return { messageId: `m${sent.length}` }; } };
}

/** An approved student year for [me] that ends [daysLeft] days from [now]. */
async function approvedYear(me, daysLeft, now = new Date()) {
  const approvedAt = new Date(now.getTime() - (365 - daysLeft) * DAY);
  await student.grantStudentYear(me.id, approvedAt);
  const expiresAt = new Date(approvedAt.getTime() + 365 * DAY);
  return StudentVerification.create({
    userId: me.id, method: 'email', status: 'approved', universityEmail: `${me.email}.edu`,
    approvedAt, expiresAt,
  });
}

describe('Student plan: reminder 7 days before the end (SP-60)', function() {
  let transport;
  beforeEach(function() {
    transport = fakeTransport();
    setTransportForTests(transport);
  });
  afterEach(function() {
    setTransportForTests(null);
    process.env.STUDENT_RENEWAL_ENABLED = '';
  });

  it('emails the account address once, in the last 7 days', async function() {
    const me = await signup();
    const record = await approvedYear(me, 6);
    expect(await jobs.sendExpiryReminders()).to.be.at.least(1);

    const mine = transport.sent.filter((m) => m.to === me.email);
    expect(mine).to.have.length(1);
    expect(mine[0].subject).to.equal('Your JobTrigger student year ends soon');
    expect(mine[0].text).to.include('ends on');
    expect(mine[0].text).to.include('one free year per person');
    expect((await StudentVerification.findById(record._id)).reminderSentAt).to.be.instanceOf(Date);

    // A second run the same day sends nothing more.
    await jobs.sendExpiryReminders();
    expect(transport.sent.filter((m) => m.to === me.email)).to.have.length(1);
  });

  it('is not sent early, and not after the end', async function() {
    const early = await signup();
    const late = await signup();
    await approvedYear(early, 8);
    await approvedYear(late, -1);
    await jobs.sendExpiryReminders();
    expect(transport.sent.some((m) => m.to === early.email)).to.equal(false);
    expect(transport.sent.some((m) => m.to === late.email)).to.equal(false);
  });

  it('is sent from day 7 on if a run was missed', async function() {
    const me = await signup();
    await approvedYear(me, 2);
    await jobs.sendExpiryReminders();
    expect(transport.sent.filter((m) => m.to === me.email)).to.have.length(1);
  });

  it('mentions applying again only when renewal is on', async function() {
    process.env.STUDENT_RENEWAL_ENABLED = 'true';
    const me = await signup();
    await approvedYear(me, 3);
    await jobs.sendExpiryReminders();
    const text = transport.sent.find((m) => m.to === me.email).text;
    expect(text).to.include('verify again');
    expect(text).to.not.include('one free year per person');
  });

  it('tries again the next run when the send fails', async function() {
    const me = await signup();
    const record = await approvedYear(me, 5);
    setTransportForTests({ sendMail: async () => { throw new Error('smtp down'); } });
    await jobs.sendExpiryReminders();
    expect((await StudentVerification.findById(record._id)).reminderSentAt).to.equal(null);

    setTransportForTests(transport);
    await jobs.sendExpiryReminders();
    expect(transport.sent.filter((m) => m.to === me.email)).to.have.length(1);
    expect((await StudentVerification.findById(record._id)).reminderSentAt).to.be.instanceOf(Date);
  });

  it('keeps the reminder for later while mail is off', async function() {
    const me = await signup();
    const record = await approvedYear(me, 5);
    setTransportForTests(null);
    await jobs.sendExpiryReminders();
    expect((await StudentVerification.findById(record._id)).reminderSentAt).to.equal(null);
  });

  it('skips a year that is not approved', async function() {
    const me = await signup();
    const record = await approvedYear(me, 4);
    await StudentVerification.updateOne({ _id: record._id }, { $set: { status: 'rejected' } });
    await jobs.sendExpiryReminders();
    expect(transport.sent.some((m) => m.to === me.email)).to.equal(false);
  });
});

describe('Student plan: expiry and the downgrade (SP-61)', function() {
  beforeEach(function() { setTransportForTests(fakeTransport()); });
  afterEach(function() {
    setTransportForTests(null);
    process.env.BILLING_ENABLED = '';
  });

  it('marks an ended year expired and writes the plan back to Free', async function() {
    const me = await signup();
    const record = await approvedYear(me, -2);
    expect(await jobs.expireEndedYears()).to.be.at.least(1);

    expect((await StudentVerification.findById(record._id)).status).to.equal('expired');
    const sub = await Subscription.findOne({ userId: me.id }).lean();
    expect(sub.plan).to.equal('free');
    expect(sub.status).to.equal('expired');
    expect(sub.source).to.equal('student');
    expect(sub.student.plan).to.equal('free');
    const status = await authed('get', '/api/student', me.token);
    expect(status.body.status).to.equal('expired');
  });

  it('leaves a running year alone, and a second run changes nothing', async function() {
    const me = await signup();
    const record = await approvedYear(me, 100);
    await jobs.expireEndedYears();
    expect((await StudentVerification.findById(record._id)).status).to.equal('approved');
    process.env.BILLING_ENABLED = 'true';
    expect((await entitlementsFor(me.id)).plan).to.equal('pro');

    await StudentVerification.updateOne({ _id: record._id }, { $set: { expiresAt: new Date(Date.now() - DAY) } });
    expect(await jobs.expireEndedYears()).to.be.at.least(1);
    expect(await jobs.expireEndedYears()).to.equal(0);
  });

  it('a missed run never leaves anyone on Pro: the date decides', async function() {
    const me = await signup();
    await approvedYear(me, 10);
    // 20 days later, with the job never having run.
    const sub = await Subscription.findOne({ userId: me.id }).lean();
    const { describe: describePlan } = require('../billing/entitlements');
    expect(describePlan(sub, { enabled: true, now: new Date(Date.now() + 20 * DAY) }).plan).to.equal('free');
    expect(describePlan(sub, { enabled: true, now: new Date(Date.now() + 5 * DAY) }).plan).to.equal('pro');
  });

  it('applies the locked-server guard as for a lapsed paid plan: nothing deleted, one usable', async function() {
    const me = await signup();
    process.env.BILLING_ENABLED = 'true';
    await approvedYear(me, 30);
    const add = (name) => authed('post', '/api/credentials', me.token).send({
      serverName: name, jenkinsURL: 'https://ci.example.com', username: 'u', password: 'p',
    });
    const first = await add('one');
    const second = await add('two');
    expect(first.status).to.equal(201);
    expect(second.status).to.equal(201);

    // The year ends (and the job runs).
    const record = await StudentVerification.findOne({ userId: me.id });
    await StudentVerification.updateOne({ _id: record._id }, { $set: { expiresAt: new Date(Date.now() - DAY) } });
    await writeSource(me.id, 'student', { periodEnd: new Date(Date.now() - DAY) });
    await jobs.expireEndedYears();

    const list = await authed('get', '/api/credentials', me.token);
    expect(list.body).to.have.length(2);
    expect(list.body.filter((c) => c.locked)).to.have.length(1);
    const locked = list.body.find((c) => c.locked);
    const switched = await authed('post', `/api/credentials/switch/${locked._id}`, me.token);
    expect(switched.status).to.equal(403);
    expect(switched.body).to.deep.include({ code: 'PLAN_LIMIT', limit: 'locked' });

    const sub = await authed('get', '/api/subscription', me.token);
    expect(sub.body.plan).to.equal('free');
    expect(sub.body.status).to.equal('expired');
  });

  it('a paid plan keeps Pro when the student year ends', async function() {
    const me = await signup();
    await writeSource(me.id, 'web', {
      plan: 'pro', status: 'active', source: 'web', periodEnd: new Date(Date.now() + 200 * DAY), willRenew: true,
    });
    await approvedYear(me, -1);
    await jobs.expireEndedYears();
    process.env.BILLING_ENABLED = 'true';
    const ent = await entitlementsFor(me.id);
    expect(ent.plan).to.equal('pro');
    expect(ent.source).to.equal('web');
  });

  it('the one-per-person rule still holds after the year ends', async function() {
    const me = await signup();
    await approvedYear(me, -1);
    await jobs.expireEndedYears();
    const res = await authed('post', '/api/student/email/start', me.token).send({ universityEmail: 'again@uom.ac.lk' });
    expect(res.status).to.equal(409);
    expect(res.body.code).to.equal('already_used');
  });

  it('runAll runs all three steps and reports them', async function() {
    const summary = await jobs.runAll();
    expect(summary).to.have.all.keys('documentsDeleted', 'remindersSent', 'yearsExpired');
  });
});
