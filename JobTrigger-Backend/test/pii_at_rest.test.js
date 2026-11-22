const crypto = require('crypto');
const mongoose = require('mongoose');
const { expect } = require('chai');
const { api } = require('./support/api');
const User = require('../models/User');
const StudentVerification = require('../models/StudentVerification');
const SupportTicket = require('../models/SupportTicket');
const Team = require('../models/Team');
const JenkinsCredential = require('../models/JenkinsCredential');
const student = require('../lib/student');
const { blindIndex, loadIndexKey } = require('../security/blindIndex');
const { loadKeys } = require('../security/secretCipher');

// NFR-SEC-08: personal data encrypted at rest.
// Story: docs/user-stories/shared/09-non-functional-security.md#nfr-sec-08

let counter = 0;
const nextEmail = (prefix = 'pii') => `${prefix}${Date.now()}${counter++}@example.com`;
const authed = (method, path, token) => api()[method](path).set('x-auth-token', token);

async function signup(email = nextEmail()) {
  const res = await api().post('/api/auth/signup').send({ email, password: 'password' });
  expect(res.status).to.equal(201);
  return { email, token: res.body.token, id: res.body.user._id };
}

const rawUser = (id) => User.collection.findOne({ _id: new mongoose.Types.ObjectId(id) });

describe('Personal data at rest (NFR-SEC-08)', function() {
  describe('AC1–AC3: accounts', function() {
    it('stores the email encrypted with a keyed hash, and answers with plaintext', async function() {
      const email = nextEmail('Mixed');
      const me = await signup(`  ${email.toUpperCase()} `);
      const raw = await rawUser(me.id);
      expect(raw.email).to.match(/^enc:v1:/);
      expect(JSON.stringify(raw)).to.not.include(email.toLowerCase());
      expect(raw.emailHash).to.equal(blindIndex('email', email.toLowerCase()));

      const login = await api().post('/api/auth/login').send({ email, password: 'password' });
      expect(login.status).to.equal(200);
      expect(login.body.user.email).to.equal(email.toLowerCase());
      expect(JSON.stringify(login.body)).to.not.include('emailHash');
    });

    it('finds a user by exact email, case-insensitively, through find, lean and exists', async function() {
      const me = await signup();
      const upper = me.email.toUpperCase();
      expect(String((await User.findOne({ email: upper }))._id)).to.equal(me.id);
      expect((await User.findOne({ email: me.email }).lean()).email).to.equal(me.email);
      expect(await User.exists({ email: me.email })).to.not.equal(null);
      expect(await User.countDocuments({ email: mongoose.trusted({ $in: [me.email, 'nobody@x.io'] }) })).to.equal(1);
    });

    it('still refuses a second account for the same email', async function() {
      const me = await signup();
      const again = await api().post('/api/auth/signup').send({ email: me.email.toUpperCase(), password: 'password' });
      expect(again.status).to.equal(400);
    });

    it('refuses a query on an encrypted field that is not an exact match', async function() {
      let error;
      try {
        await User.find({ email: mongoose.trusted({ $regex: /example/ }) });
      } catch (err) {
        error = err;
      }
      expect(error?.message).to.match(/only an exact match/);
      error = undefined;
      try {
        await SupportTicket.find({ replyEmail: 'a@b.co' });
      } catch (err) {
        error = err;
      }
      expect(error?.message).to.match(/can't be queried/);
    });

    it('keeps the hash in step when the email is updated by query', async function() {
      const me = await signup();
      const moved = nextEmail('moved');
      await User.updateOne({ _id: me.id }, { $set: { email: moved.toUpperCase() } });
      const raw = await rawUser(me.id);
      expect(raw.email).to.match(/^enc:v1:/);
      expect(raw.emailHash).to.equal(blindIndex('email', moved));
      expect((await User.findOne({ email: moved }))?.email).to.equal(moved);
    });

    it('does not wipe the hash when a document loaded without the email is saved', async function() {
      const me = await signup();
      const partial = await User.findById(me.id).select('role');
      partial.role = 'user';
      await partial.save();
      expect((await rawUser(me.id)).emailHash).to.be.a('string');
    });

    it('decrypts emails in populate results', async function() {
      const me = await signup();
      await authed('post', '/api/support/tickets', me.token).send({
        category: 'question', subject: 'Populate', message: 'Hello there', replyEmail: me.email,
      });
      const ticket = await SupportTicket.findOne({ userId: me.id }).populate('userId', 'email').lean();
      expect(ticket.userId.email).to.equal(me.email);
      expect(ticket.message).to.equal('Hello there');
    });
  });

  describe('AC1, AC6: support tickets, student records, team invites, servers', function() {
    it('encrypts every personal field of a support ticket and keeps the length limits', async function() {
      const me = await signup();
      const created = await authed('post', '/api/support/tickets', me.token).send({
        category: 'bug', subject: 'Secret subject', message: 'Private details', replyEmail: me.email,
        serverHost: 'https://jenkins.internal.example:8443/job/x',
      });
      expect(created.status).to.equal(201);
      const raw = await SupportTicket.collection.findOne({ _id: new mongoose.Types.ObjectId(created.body.ticket.id) });
      for (const field of ['subject', 'message', 'replyEmail', 'serverHost']) {
        expect(raw[field], field).to.match(/^enc:v1:/);
      }
      expect(JSON.stringify(raw)).to.not.include('Private details');
      const mine = await authed('get', '/api/support/tickets', me.token);
      expect(mine.body.tickets[0].subject).to.equal('Secret subject');

      const tooLong = new SupportTicket({ userId: me.id, category: 'bug', subject: 'x'.repeat(121), message: 'm', replyEmail: 'a@b.co' });
      const error = await tooLong.validate().then(() => null, (err) => err);
      expect(Object.keys(error?.errors ?? {})).to.include('subject');
    });

    it('encrypts the student name and university email, with an exact-match hash', async function() {
      const me = await signup();
      const record = await StudentVerification.create({
        userId: me.id, method: 'email', universityEmail: ' Kamal@UOM.ac.lk ', fullName: 'Kamal Perera',
      });
      const raw = await StudentVerification.collection.findOne({ _id: record._id });
      expect(raw.universityEmail).to.match(/^enc:v1:/);
      expect(raw.fullName).to.match(/^enc:v1:/);
      expect(raw.universityEmailHash).to.equal(blindIndex('universityEmail', 'kamal@uom.ac.lk'));
      const found = await StudentVerification.findOne({ universityEmail: 'KAMAL@uom.ac.lk' }).lean();
      expect(found.fullName).to.equal('Kamal Perera');
      expect(found.universityEmail).to.equal('kamal@uom.ac.lk');
      expect(JSON.stringify(record.toJSON())).to.not.include('enc:v1:');
    });

    it('encrypts team invite emails inside the array', async function() {
      const owner = await signup();
      const team = await Team.create({
        name: 'PII team', ownerId: owner.id, members: [{ userId: owner.id }],
        invites: [{ email: ' Friend@Example.com ', tokenHash: crypto.randomBytes(8).toString('hex'), expiresAt: new Date(Date.now() + 60000), invitedBy: owner.id }],
      });
      const raw = await Team.collection.findOne({ _id: team._id });
      expect(raw.invites[0].email).to.match(/^enc:v1:/);
      expect((await Team.findById(team._id)).invites[0].email).to.equal('friend@example.com');
      expect((await Team.findById(team._id).lean()).invites[0].email).to.equal('friend@example.com');
    });

    it('encrypts the Jenkins server address and username', async function() {
      const me = await signup();
      const created = await authed('post', '/api/credentials', me.token).send({
        serverName: 'Lab', jenkinsURL: 'http://10.0.0.5:8080', username: 'sithum', password: 'tok',
      });
      expect(created.status).to.equal(201);
      expect(created.body.jenkinsURL).to.equal('http://10.0.0.5:8080');
      expect(created.body.username).to.equal('sithum');
      const raw = await JenkinsCredential.collection.findOne({ _id: new mongoose.Types.ObjectId(created.body._id) });
      expect(raw.jenkinsURL).to.match(/^enc:v1:/);
      expect(raw.username).to.match(/^enc:v1:/);
      expect(JSON.stringify(raw)).to.not.include('10.0.0.5');
    });
  });

  describe('AC4: admin search', function() {
    it('matches an exact account email only', async function() {
      const boss = await signup(nextEmail('boss'));
      await User.updateOne({ _id: boss.id }, { $set: { role: 'superAdmin' } });
      const target = await signup();
      const exact = await authed('get', `/api/admin/subscriptions?q=${encodeURIComponent(target.email.toUpperCase())}`, boss.token);
      expect(exact.body.items.map((i) => i.userId)).to.deep.equal([target.id]);
      const partial = await authed('get', `/api/admin/subscriptions?q=${encodeURIComponent(target.email.slice(0, 6))}`, boss.token);
      expect(partial.status).to.equal(200);
      expect(partial.body.items).to.have.length(0);
    });
  });

  describe('AC5, AC11: keys', function() {
    it('hashes student email claims with the key, not plain SHA-256', function() {
      const email = 'claim@uom.ac.lk';
      expect(student.emailHash(email)).to.equal(blindIndex('student-email', email));
      expect(student.emailHash(email)).to.not.equal(student.legacyEmailHash(email));
      expect(student.legacyEmailHash(email)).to.equal(
        crypto.createHash('sha256').update(`student-email:${email}`).digest('hex'),
      );
    });

    it('derives the hash key from key k1 unless PII_INDEX_KEY is set', function() {
      const k1 = crypto.randomBytes(32).toString('base64');
      const env = { CREDENTIALS_ENCRYPTION_KEY: k1 };
      const derived = loadIndexKey(env);
      expect(derived).to.have.length(32);
      // Rotating to k2 (k1 kept as a previous key) keeps the same hash key.
      const rotated = loadIndexKey({
        CREDENTIALS_ENCRYPTION_KEY: crypto.randomBytes(32).toString('base64'),
        CREDENTIALS_ENCRYPTION_KEY_ID: 'k2',
        CREDENTIALS_ENCRYPTION_PREVIOUS_KEYS: `k1:${k1}`,
      });
      expect(rotated.equals(derived)).to.equal(true);
      const explicit = crypto.randomBytes(32);
      expect(loadIndexKey({ ...env, PII_INDEX_KEY: explicit.toString('base64') }).equals(explicit)).to.equal(true);
      expect(() => loadIndexKey({ ...env, PII_INDEX_KEY: 'c2hvcnQ=' })).to.throw(/32 bytes/);
      expect(loadKeys(env).keys.has('k1')).to.equal(true);
    });
  });

  describe('AC10: startup audit', function() {
    it('logs pii.migration_pending while accounts have no email hash', async function() {
      const { captureLogs } = require('./support/logs');
      await User.collection.insertOne({ email: nextEmail('legacy'), password: 'x', role: 'user', tokenVersion: 0 });
      const server = require('../server');
      const lines = await captureLogs(() => server.auditPiiMigration());
      expect(lines.some((l) => l.msg === 'pii.migration_pending' && l.users >= 1)).to.equal(true);
      await User.collection.deleteMany({ emailHash: { $exists: false } });
    });
  });
});
