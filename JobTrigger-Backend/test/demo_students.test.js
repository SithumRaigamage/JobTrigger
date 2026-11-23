const { expect } = require('chai');
const crypto = require('crypto');

const User = require('../models/User');
const StudentVerification = require('../models/StudentVerification');
const StudentClaim = require('../models/StudentClaim');
const Subscription = require('../models/Subscription');
const { decrypt } = require('../security/secretCipher');
const { DOCUMENT_FIELD } = require('../controllers/studentController');
const { emailHash } = require('../lib/student');
const { remoteDatabaseProblem } = require('../scripts/localOnly');
const {
  DEMO_PASSWORD,
  PEOPLE,
  PNG,
  demoApplications,
  seedDemoStudents,
} = require('../scripts/seed-demo-students');

describe('Phase 32: fictional student review demo data (US-DEMO-01…03)', function() {
  const now = new Date('2026-11-23T12:00:00.000Z');
  let reviewer;

  beforeEach(async function() {
    reviewer = await User.create({
      email: `reviewer-demo-${crypto.randomBytes(4).toString('hex')}@example.com`,
      password: 'password',
      role: 'superAdmin',
    });
  });

  it('refuses production, unapproved remote and named-production databases', function() {
    expect(remoteDatabaseProblem('mongodb://localhost:27017', {
      env: { NODE_ENV: 'production' }, argv: [],
    })).to.match(/production/);
    expect(remoteDatabaseProblem('mongodb://user:pwd@localhost:27017/jobtrigger-prod', {
      env: {}, argv: ['--allow-remote'],
    })).to.match(/production/);
    const remote = remoteDatabaseProblem('mongodb+srv://dev.example.com/jobtrigger', {
      env: {}, argv: [],
    });
    expect(remote).to.match(/non-local/);
    expect(remoteDatabaseProblem('mongodb+srv://dev.example.com/jobtrigger', {
      env: {}, argv: ['--allow-remote'],
    })).to.equal(null);
  });

  it('seeds five fictional applications of both methods and every status', async function() {
    const result = await seedDemoStudents({ now });
    expect(result).to.deep.equal({ users: 5, applications: 5 });
    expect(await StudentVerification.countDocuments()).to.equal(5);

    const byEmail = new Map();
    for (const person of PEOPLE) {
      const user = await User.findOne({ email: person.accountEmail });
      expect(user, person.accountEmail).to.exist;
      expect(await user.comparePassword(DEMO_PASSWORD)).to.equal(true);
      const app = await StudentVerification.findOne({ userId: user._id }).select('+documentData');
      expect(app, `${person.key} application`).to.exist;
      byEmail.set(person.key, { user, app });
    }

    const nimali = byEmail.get('nimali').app;
    expect(nimali.method).to.equal('email');
    expect(nimali.status).to.equal('pending');
    expect(nimali.universityEmail).to.equal('nimali.silva@student.mtu.ac.lk');
    expect(nimali.emailVerifiedAt).to.be.a('date');
    expect(nimali.approvedAt).to.equal(null);

    const kasun = byEmail.get('kasun').app;
    expect(kasun.method).to.equal('document');
    expect(kasun.status).to.equal('pending');
    expect(kasun.fullName).to.equal('Kasun Perera');
    expect(kasun.documentData).to.be.a('string');
    expect(decrypt(kasun.documentData, DOCUMENT_FIELD)).to.equal(PNG.toString('base64'));
    expect(kasun.documentHash).to.equal(crypto.createHash('sha256').update(PNG).digest('hex'));

    const anushka = byEmail.get('anushka').app;
    expect(anushka.status).to.equal('approved');
    expect(anushka.approvedAt).to.be.a('date');
    expect(anushka.expiresAt.getTime() - anushka.approvedAt.getTime()).to.equal(365 * 24 * 60 * 60 * 1000);
    const recordedReviewer = await User.findById(anushka.reviewedBy);
    expect(recordedReviewer, 'recorded reviewer').to.exist;
    expect(recordedReviewer.role).to.equal('superAdmin');

    const tharindu = byEmail.get('tharindu').app;
    expect(tharindu.status).to.equal('rejected');
    expect(tharindu.rejectionReason).to.match(/blurry/);

    const maya = byEmail.get('maya').app;
    expect(maya.status).to.equal('expired');
    expect(maya.expiresAt.getTime()).to.be.lessThan(now.getTime());
  });

  it('gives decided email grants real claims and grant sources, and leaves the others claim-free', async function() {
    await seedDemoStudents({ now });
    const people = demoApplications(now);
    const approved = people.filter((p) => p.status === 'approved' || p.status === 'expired');
    const pendingOrRejected = people.filter((p) => p.status === 'pending' || p.status === 'rejected');

    for (const person of approved) {
      expect(await StudentClaim.exists({ kind: 'email', hash: emailHash(person.universityEmail) }), person.key).to.exist;
      const subscription = await Subscription.findOne({ userId: person.userId }).lean();
      expect(subscription, person.key).to.exist;
      expect(subscription.student.source).to.equal('student');
      expect(new Date(subscription.student.periodEnd).getTime()).to.equal(person.approvedAt.getTime() + 365 * 24 * 60 * 60 * 1000);
    }
    for (const person of pendingOrRejected) {
      if (person.universityEmail) {
        expect(await StudentClaim.exists({ kind: 'email', hash: emailHash(person.universityEmail) }), person.key).to.equal(null);
      }
      expect(await Subscription.findOne({ userId: person.userId }).lean(), person.key).to.equal(null);
    }
    // The rejected document is kept for 30 days like a real decided document.
    const kasun = await User.findOne({ email: 'demo-kasun@jobtrigger.app' });
    expect((await StudentVerification.findOne({ userId: kasun._id })).documentDeleteAt).to.equal(null);
    const tharindu = await User.findOne({ email: 'demo-tharindu@jobtrigger.app' });
    expect((await StudentVerification.findOne({ userId: tharindu._id })).documentDeleteAt).to.be.a('date');
  });

  it('resets the five to their starting state on a second run', async function() {
    await seedDemoStudents({ now });
    const nimaliUser = await User.findOne({ email: 'demo-nimali@jobtrigger.app' });
    await StudentVerification.updateOne(
      { userId: nimaliUser._id },
      { $set: { status: 'approved', approvedAt: now } },
    );
    await StudentClaim.create({ kind: 'email', hash: emailHash('nimali.silva@student.mtu.ac.lk') });

    const later = new Date(now.getTime() + 10 * 24 * 60 * 60 * 1000);
    await seedDemoStudents({ now: later });

    expect(await StudentVerification.countDocuments()).to.equal(5);
    expect(await StudentClaim.countDocuments()).to.equal(2); // only Anushka and Maya
    const reset = await StudentVerification.findOne({ userId: nimaliUser._id });
    expect(reset.status).to.equal('pending');
    expect(reset.approvedAt).to.equal(null);
    expect(await Subscription.findOne({ userId: nimaliUser._id }).lean(), 'nimali grant').to.equal(null);
    expect(reset.createdAt.getTime()).to.equal(later.getTime() - 2 * 24 * 60 * 60 * 1000);
  });
});
