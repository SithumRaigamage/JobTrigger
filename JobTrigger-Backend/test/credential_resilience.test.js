const mongoose = require('mongoose');
const { api } = require('./support/api');
const { captureLogs, linesWith } = require('./support/logs');
const { expect } = require('chai');
const JenkinsCredential = require('../models/JenkinsCredential');
const GitHubCredential = require('../models/GitHubCredential');
const SonarQubeCredential = require('../models/SonarQubeCredential');

/**
 * AUD-63: a credential whose secret can't be decrypted (a key id dropped
 * from the keyring too early, or a GCM tag that doesn't check out) used
 * to make `toJSON` throw, so the whole list 500'd and the user lost
 * every server, not just the broken one.
 *
 * The row is written through the raw collection, which has no setters,
 * so the ciphertext is stored exactly as given.
 */
const UNREADABLE = 'enc:v1:nosuchkey:AAAAAAAAAAAAAAAA:BBBBBBBBBB:CCCCCCCCCC';

describe('Undecryptable credentials (AUD-63)', function() {
  let token;
  let userId;

  before(async function() {
    const res = await api()
      .post('/api/auth/signup')
      .send({ email: 'aud63@example.com', password: 'password' });
    token = res.body.token;
    userId = res.body.user._id;
  });

  after(async function() {
    // The unreadable rows are this user's alone; leave the database as
    // the other suites expect to find it.
    const user = new mongoose.Types.ObjectId(userId);
    await GitHubCredential.collection.deleteMany({ userId: user });
    await JenkinsCredential.collection.deleteMany({ userId: user });
    await SonarQubeCredential.collection.deleteMany({ userId: user });
  });

  it('lists an unreadable GitHub token as null with needsReentry, and keeps the others', async function() {
    await GitHubCredential.collection.insertOne({
      userId: new mongoose.Types.ObjectId(userId),
      label: 'Broken',
      token: UNREADABLE,
      defaultOwner: '',
      isDefault: false,
    });
    const created = await api()
      .post('/api/github-credentials')
      .set('x-auth-token', token)
      .send({ label: 'Working', token: 'ghp_working' });
    expect(created.status).to.equal(201);

    const list = await api().get('/api/github-credentials').set('x-auth-token', token);
    expect(list.status).to.equal(200);
    expect(list.body).to.be.an('array');

    const broken = list.body.find((c) => c.label === 'Broken');
    expect(broken).to.exist;
    expect(broken.token).to.equal(null);
    expect(broken.needsReentry).to.equal(true);

    const working = list.body.find((c) => c.label === 'Working');
    expect(working.token).to.equal('ghp_working');
    expect(working.needsReentry).to.equal(false);
  });

  it('lists an unreadable Jenkins password as null with needsReentry', async function() {
    await JenkinsCredential.collection.insertOne({
      userId: new mongoose.Types.ObjectId(userId),
      serverName: 'Broken Jenkins',
      jenkinsURL: 'http://broken',
      username: 'u',
      password: UNREADABLE,
      paramToken: '',
      isDefault: false,
    });

    const list = await api().get('/api/credentials').set('x-auth-token', token);
    expect(list.status).to.equal(200);

    const broken = list.body.find((c) => c.serverName === 'Broken Jenkins');
    expect(broken).to.exist;
    expect(broken.password).to.equal(null);
    expect(broken.needsReentry).to.equal(true);
  });

  it('lists an unreadable SonarQube token as null with needsReentry', async function() {
    await SonarQubeCredential.collection.insertOne({
      userId: new mongoose.Types.ObjectId(userId),
      label: 'Broken Sonar',
      baseUrl: 'https://sonarcloud.io',
      token: UNREADABLE,
      defaultOrganization: '',
      isDefault: false,
    });

    const list = await api().get('/api/sonarqube-credentials').set('x-auth-token', token);
    expect(list.status).to.equal(200);

    const broken = list.body.find((c) => c.label === 'Broken Sonar');
    expect(broken).to.exist;
    expect(broken.token).to.equal(null);
    expect(broken.needsReentry).to.equal(true);
  });

  it('puts needsReentry on every credential, true or false', async function() {
    for (const path of [
      '/api/credentials',
      '/api/github-credentials',
      '/api/sonarqube-credentials',
    ]) {
      const list = await api().get(path).set('x-auth-token', token);
      expect(list.status, path).to.equal(200);
      expect(list.body.length, path).to.be.greaterThan(0);
      for (const credential of list.body) {
        expect(credential, path).to.have.property('needsReentry');
        expect(credential.needsReentry, path).to.be.a('boolean');
      }
    }
  });

  it('logs the failing row without the secret', async function() {
    const entries = await captureLogs(async () => {
      await api().get('/api/github-credentials').set('x-auth-token', token);
    });

    const failures = linesWith(entries, 'credential.decrypt_failed');
    expect(failures.length).to.be.greaterThan(0);

    const failure = failures.find((f) => f.model === 'GitHubCredential');
    expect(failure).to.exist;
    expect(failure.field).to.equal('token');
    expect(failure.credentialId).to.be.a('string');
    expect(failure.level).to.equal('error');
    // No ciphertext, no plaintext, no part of the secret.
    const text = JSON.stringify(failure);
    expect(text).to.not.include('enc:v1:');
    expect(text).to.not.include('ghp_');
    expect(text).to.not.include('nosuchkey');
  });

  it('returns a legacy plaintext row unchanged', async function() {
    await GitHubCredential.collection.insertOne({
      userId: new mongoose.Types.ObjectId(userId),
      label: 'Legacy',
      token: 'ghp_legacy_plaintext',
      defaultOwner: '',
      isDefault: false,
    });

    const list = await api().get('/api/github-credentials').set('x-auth-token', token);
    const legacy = list.body.find((c) => c.label === 'Legacy');
    expect(legacy.token).to.equal('ghp_legacy_plaintext');
    expect(legacy.needsReentry).to.equal(false);
  });

  it('keeps an empty secret an empty string', async function() {
    const created = await api()
      .post('/api/credentials')
      .set('x-auth-token', token)
      .send({ serverName: 'No param token', jenkinsURL: 'http://empty', username: 'u', password: 'p', paramToken: '' });
    expect(created.status).to.equal(201);
    expect(created.body.paramToken).to.equal('');
    expect(created.body.needsReentry).to.equal(false);
  });

  it('clears needsReentry once the secret is re-entered', async function() {
    const list = await api().get('/api/github-credentials').set('x-auth-token', token);
    const broken = list.body.find((c) => c.label === 'Broken');

    const updated = await api()
      .put(`/api/github-credentials/${broken._id}`)
      .set('x-auth-token', token)
      .send({ token: 'ghp_reentered' });
    expect(updated.status).to.equal(200);
    expect(updated.body.token).to.equal('ghp_reentered');
    expect(updated.body.needsReentry).to.equal(false);
  });
});
