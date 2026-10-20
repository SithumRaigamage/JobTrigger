const crypto = require('crypto');
const mongoose = require('mongoose');
const { api } = require('./support/api');
const { expect } = require('chai');
const {
  encrypt,
  decrypt,
  isEncrypted,
  needsRotation,
  loadKeys,
} = require('../security/secretCipher');
const { encryptExistingCredentials } = require('../scripts/encrypt-credentials');
const JenkinsCredential = require('../models/JenkinsCredential');
const GitHubCredential = require('../models/GitHubCredential');

const key = () => crypto.randomBytes(32).toString('base64');

describe('Secret cipher (AUD-03)', function() {
  const ring = loadKeys({ CREDENTIALS_ENCRYPTION_KEY: key() });

  it('round-trips, with a fresh IV each time', function() {
    const a = encrypt('s3cret', 'token', ring);
    const b = encrypt('s3cret', 'token', ring);
    expect(a).to.match(/^enc:v1:k1:/);
    expect(a).to.not.equal(b);
    expect(decrypt(a, 'token', ring)).to.equal('s3cret');
  });

  it('rejects tampering and a ciphertext moved to another field', function() {
    const stored = encrypt('s3cret', 'token', ring);
    const parts = stored.split(':');
    parts[5] = Buffer.from('forged').toString('base64url');
    expect(() => decrypt(parts.join(':'), 'token', ring)).to.throw();
    expect(() => decrypt(stored, 'password', ring)).to.throw();
  });

  it('reads legacy plaintext as-is until the backfill runs', function() {
    expect(decrypt('plain-old-token', 'token', ring)).to.equal('plain-old-token');
    expect(isEncrypted('plain-old-token')).to.equal(false);
  });

  it('keeps old keys readable after rotation', function() {
    const oldKey = key();
    const before = loadKeys({ CREDENTIALS_ENCRYPTION_KEY: oldKey, CREDENTIALS_ENCRYPTION_KEY_ID: 'k1' });
    const stored = encrypt('s3cret', 'token', before);
    const after = loadKeys({
      CREDENTIALS_ENCRYPTION_KEY: key(),
      CREDENTIALS_ENCRYPTION_KEY_ID: 'k2',
      CREDENTIALS_ENCRYPTION_PREVIOUS_KEYS: `k1:${oldKey}`,
    });
    expect(decrypt(stored, 'token', after)).to.equal('s3cret');
    expect(needsRotation(stored, after)).to.equal(true);
  });

  it('refuses a key that is not 32 bytes', function() {
    expect(() => loadKeys({ CREDENTIALS_ENCRYPTION_KEY: 'c2hvcnQ=' })).to.throw(/32 bytes/);
  });
});

describe('Credentials at rest (AUD-03)', function() {
  let token;

  before(async function() {
    const res = await api()
      .post('/api/auth/signup')
      .send({ email: 'atrest@example.com', password: 'password' });
    token = res.body.token;
  });

  it('stores secrets encrypted but returns them as plaintext', async function() {
    const created = await api()
      .post('/api/credentials')
      .set('x-auth-token', token)
      .send({ serverName: 'S', jenkinsURL: 'http://s', username: 'u', password: 'jenkins-token', paramToken: 'trigger' });
    expect(created.status).to.equal(201);
    expect(created.body.password).to.equal('jenkins-token');

    const raw = await JenkinsCredential.collection.findOne({
      _id: new mongoose.Types.ObjectId(created.body._id),
    });
    expect(raw.password).to.match(/^enc:v1:/);
    expect(raw.paramToken).to.match(/^enc:v1:/);
    expect(JSON.stringify(raw)).to.not.include('jenkins-token');

    const list = await api().get('/api/credentials').set('x-auth-token', token);
    expect(list.body.find((c) => c._id === created.body._id).password).to.equal('jenkins-token');
  });

  it('encrypts an updated secret too', async function() {
    const created = await api()
      .post('/api/github-credentials')
      .set('x-auth-token', token)
      .send({ label: 'G', token: 'ghp_first' });
    await api()
      .put(`/api/github-credentials/${created.body._id}`)
      .set('x-auth-token', token)
      .send({ token: 'ghp_second' });
    const raw = await GitHubCredential.collection.findOne({
      _id: new mongoose.Types.ObjectId(created.body._id),
    });
    expect(raw.token).to.match(/^enc:v1:/);
    expect(decrypt(raw.token, 'token')).to.equal('ghp_second');
  });

  it('backfills legacy plaintext rows, idempotently', async function() {
    const inserted = await GitHubCredential.collection.insertOne({
      userId: new mongoose.Types.ObjectId(),
      label: 'Legacy',
      token: 'ghp_legacy_plaintext',
      defaultOwner: '',
      isDefault: false,
    });
    const quiet = () => {};

    expect(await encryptExistingCredentials({ dryRun: true, log: quiet })).to.be.at.least(1);
    let raw = await GitHubCredential.collection.findOne({ _id: inserted.insertedId });
    expect(raw.token).to.equal('ghp_legacy_plaintext'); // Dry run wrote nothing.

    await encryptExistingCredentials({ log: quiet });
    raw = await GitHubCredential.collection.findOne({ _id: inserted.insertedId });
    expect(raw.token).to.match(/^enc:v1:/);
    expect((await GitHubCredential.findById(inserted.insertedId)).token).to.equal('ghp_legacy_plaintext');

    expect(await encryptExistingCredentials({ log: quiet })).to.equal(0); // Re-run: no-op.
  });
});
