/**
 * Phase 32 (WEB-DEMO): five fictional student applications for local
 * development and QA. The review pages are empty without data; this script
 * fills them through the same models the real flows use, so approve and
 * reject behave exactly as they do for a real application.
 *
 *   node scripts/seed-demo-students.js
 *   node scripts/seed-demo-students.js --allow-remote   # the Atlas dev cluster
 *
 * Run it with the documented development environment already exported in the
 * shell; this script never opens a `.env` file itself. Safe to run more than
 * once: it resets these five records (and only these five) to their starting
 * state, including their claims and grant sources. `localOnly.js` refuses
 * production and unapproved remote databases. Nothing here is new personal
 * data: every person, email and document is fictional.
 */
const crypto = require('crypto');
const mongoose = require('mongoose');
const { connectDatabase } = require('../lib/database');
const { requireLocalDatabase } = require('./localOnly');
const User = require('../models/User');
const StudentVerification = require('../models/StudentVerification');
const StudentClaim = require('../models/StudentClaim');
const Subscription = require('../models/Subscription');
const { encrypt } = require('../security/secretCipher');
const { DOCUMENT_FIELD } = require('../controllers/studentController');
const { emailHash, grantStudentYear, DAY_MS } = require('../lib/student');
const { DOCUMENT_KEEP_DAYS } = require('../lib/studentJobs');

const DAY = DAY_MS;
const DEMO_PASSWORD = 'DemoPass123!';
const REVIEWER_EMAIL = 'developer@jobtrigger.app';

// A tiny valid PNG header with a fictional body. Never a real student ID.
const PNG = Buffer.concat([
  Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
  Buffer.from('fictional demo student id'),
]);

/** Days before/after the seed time; keeps the demo looking fresh on every run. */
const PEOPLE = Object.freeze([
  {
    key: 'nimali',
    accountEmail: 'demo-nimali@jobtrigger.app',
    method: 'email',
    universityEmail: 'nimali.silva@student.mtu.ac.lk',
    status: 'pending',
    submittedDaysAgo: 2,
    verifiedDaysAgo: 2,
  },
  {
    key: 'kasun',
    accountEmail: 'demo-kasun@jobtrigger.app',
    method: 'document',
    fullName: 'Kasun Perera',
    status: 'pending',
    submittedDaysAgo: 5,
    document: true,
  },
  {
    key: 'anushka',
    accountEmail: 'demo-anushka@jobtrigger.app',
    method: 'email',
    universityEmail: 'anushka.fernando@student.pdn.ac.lk',
    status: 'approved',
    submittedDaysAgo: 50,
    verifiedDaysAgo: 50,
    approvedDaysAgo: 45,
  },
  {
    key: 'tharindu',
    accountEmail: 'demo-tharindu@jobtrigger.app',
    method: 'document',
    fullName: 'Tharindu Wickramasinghe',
    status: 'rejected',
    submittedDaysAgo: 6,
    reviewedDaysAgo: 3,
    rejectionReason: 'The photo is too blurry to read. Upload a clearer student ID.',
    document: true,
  },
  {
    key: 'maya',
    accountEmail: 'demo-maya@jobtrigger.app',
    method: 'email',
    universityEmail: 'maya.chandrasekaran@student.ruh.ac.lk',
    status: 'expired',
    submittedDaysAgo: 400,
    verifiedDaysAgo: 400,
    approvedDaysAgo: 400,
  },
]);

const daysAgo = (now, days) => new Date(now.getTime() - days * DAY);
const objectIdFor = (label) =>
  new mongoose.Types.ObjectId(crypto.createHash('md5').update(`demo:${label}`).digest().subarray(0, 12));

/** The fixed personas, with their dates resolved against [now]. Exported for tests. */
function demoApplications(now = new Date()) {
  return PEOPLE.map((person) => ({
    ...person,
    id: objectIdFor(person.key),
    userId: objectIdFor(`${person.key}:user`),
    submittedAt: daysAgo(now, person.submittedDaysAgo),
    emailVerifiedAt: person.verifiedDaysAgo == null ? null : daysAgo(now, person.verifiedDaysAgo),
    reviewedAt: person.approvedDaysAgo != null
      ? daysAgo(now, person.approvedDaysAgo)
      : person.reviewedDaysAgo != null
        ? daysAgo(now, person.reviewedDaysAgo)
        : null,
    approvedAt: person.approvedDaysAgo == null ? null : daysAgo(now, person.approvedDaysAgo),
  }));
}

/** Removes every trace of the five demo accounts before rebuilding them. */
async function clearDemo(people) {
  const userIds = mongoose.trusted({ $in: people.map((p) => p.userId) });
  await StudentVerification.deleteMany({ userId: userIds });
  await Subscription.deleteMany({ userId: userIds });
  const hashes = [
    ...people.filter((p) => p.universityEmail).map((p) => emailHash(p.universityEmail)),
    ...people.filter((p) => p.document).map((p) => crypto.createHash('sha256').update(PNG).digest('hex')),
  ];
  if (hashes.length > 0) {
    await StudentClaim.deleteMany({ hash: mongoose.trusted({ $in: hashes }) });
  }
}

/** Seeds the five users and applications. Returns a short summary for the CLI. */
async function seedDemoStudents({ now = new Date() } = {}) {
  const people = demoApplications(now);
  const reviewer = await User.findOne({ role: 'superAdmin' }).select('_id').lean();

  for (const person of people) {
    let user = await User.findOne({ email: person.accountEmail });
    if (user) {
      user.password = DEMO_PASSWORD; // Re-hashed by the pre-save hook.
      await user.save();
    } else {
      user = await User.create({
        _id: person.userId,
        email: person.accountEmail,
        password: DEMO_PASSWORD,
      });
    }
  }
  await clearDemo(people);

  for (const person of people) {
    const decided = person.status !== 'pending';
    const documentHash = person.document
      ? crypto.createHash('sha256').update(PNG).digest('hex')
      : null;
    await StudentVerification.create({
      _id: person.id,
      userId: person.userId,
      method: person.method,
      status: person.status,
      universityEmail: person.universityEmail ?? null,
      fullName: person.fullName ?? null,
      emailVerifiedAt: person.emailVerifiedAt,
      reviewedBy: decided && reviewer ? reviewer._id : null,
      reviewedAt: person.reviewedAt,
      approvedAt: person.approvedAt,
      // The expired persona is really past its year; the date decides Pro,
      // not the status field (Phase 21 note 2).
      expiresAt: person.approvedAt ? new Date(person.approvedAt.getTime() + 365 * DAY) : null,
      rejectionReason: person.rejectionReason ?? null,
      documentData: person.document ? encrypt(PNG.toString('base64'), DOCUMENT_FIELD) : null,
      documentMime: person.document ? 'image/png' : null,
      documentSize: person.document ? PNG.length : null,
      documentHash,
      documentDeleteAt: person.document && decided
        ? new Date(person.reviewedAt.getTime() + DOCUMENT_KEEP_DAYS * DAY)
        : null,
      createdAt: person.submittedAt,
      updatedAt: person.submittedAt,
    });

    // Approved and ended grants own their email forever; a rejected or still
    // pending one must not block another application using the same email.
    if (person.status === 'approved' || person.status === 'expired') {
      if (person.universityEmail) {
        await StudentClaim.create({ kind: 'email', hash: emailHash(person.universityEmail) });
      }
      if (documentHash) await StudentClaim.create({ kind: 'document', hash: documentHash });
      await grantStudentYear(person.userId, person.approvedAt);
    }
  }
  return { users: people.length, applications: people.length };
}

async function main() {
  requireLocalDatabase(process.env.MONGODB_URI);
  await connectDatabase();
  try {
    const result = await seedDemoStudents();
    console.log(
      `Seeded ${result.users} fictional demo students. Re-running resets them. ` +
        `Sign in as demo-nimali@jobtrigger.app / ${DEMO_PASSWORD} to see one.`,
    );
  } finally {
    await mongoose.disconnect();
  }
}

if (require.main === module) main();

module.exports = {
  DEMO_PASSWORD,
  PEOPLE,
  PNG,
  demoApplications,
  seedDemoStudents,
  clearDemo,
};
