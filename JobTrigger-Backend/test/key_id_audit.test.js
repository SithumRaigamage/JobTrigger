const mongoose = require('mongoose');
const crypto = require('crypto');
const { api } = require('./support/api');
const { captureLogs, linesWith } = require('./support/logs');
const { expect } = require('chai');
const { auditKeyIds } = require('../security/keyIdAudit');
const CREDENTIAL_TARGETS = require('../models/credentialTargets');
const { loadKeys } = require('../security/secretCipher');
const GitHubCredential = require('../models/GitHubCredential');
const { auditCredentialKeyIds } = require('../server');

const key = () => crypto.randomBytes(32).toString('base64');

/**
 * AUD-63: a key id dropped from the keyring too early leaves secrets the
 * server can't read. The startup audit names those ids, and how many rows
 * each one holds, without stopping the server.
 */
describe('Startup key-id audit (AUD-63)', function() {
  let userId;

  before(async function() {
    const res = await api()
      .post('/api/auth/signup')
      .send({ email: 'audit-keys@example.com', password: 'password' });
    userId = res.body.user._id;

    // A row written with a key id the server doesn't have.
    await GitHubCredential.collection.insertOne({
      userId: new mongoose.Types.ObjectId(userId),
      label: 'Bad key id',
      token: `enc:v1:ghost:${Buffer.from('x').toString('base64url')}`,
      defaultOwner: '',
      isDefault: false,
    });
  });

  after(async function() {
    // The rows with made-up key ids are this user's alone.
    await GitHubCredential.collection.deleteMany({
      userId: new mongoose.Types.ObjectId(userId),
    });
  });

  it('names the key ids the database uses that the keyring cannot decrypt', async function() {
    const ring = loadKeys({
      CREDENTIALS_ENCRYPTION_KEY: key(),
      CREDENTIALS_ENCRYPTION_KEY_ID: 'k1',
    });

    const { missing, counts } = await auditKeyIds(CREDENTIAL_TARGETS, { ring });

    const ghost = missing.find((m) => m.keyId === 'ghost');
    expect(ghost, 'ghost is missing').to.exist;
    expect(ghost.count, 'rows using ghost').to.be.at.least(1);
    // The key the rows were written with is in the ring, so it is fine.
    expect(missing.map((m) => m.keyId)).to.not.include('k1');
    expect(counts).to.have.property('k1');
  });

  it('does not report a key id the keyring can decrypt', async function() {
    const ring = loadKeys({
      CREDENTIALS_ENCRYPTION_KEY: key(),
      CREDENTIALS_ENCRYPTION_KEY_ID: 'k1',
      CREDENTIALS_ENCRYPTION_PREVIOUS_KEYS: `ghost:${key()}`,
    });

    const { missing } = await auditKeyIds(CREDENTIAL_TARGETS, { ring });
    expect(missing.map((m) => m.keyId)).to.not.include('ghost');
  });

  it('the server logs the missing key ids, and keeps running', async function() {
    const entries = await captureLogs(async () => {
      await auditCredentialKeyIds();
    });

    const line = linesWith(entries, 'credential.key_ids_missing')[0];
    expect(line, 'logged').to.exist;
    expect(line.level).to.equal('error');
    const reported = line.missing.map((m) => m.keyId);
    expect(reported).to.include('ghost');
    for (const entry of line.missing) {
      expect(entry.count, 'rows per key id').to.be.at.least(1);
    }
  });
});
