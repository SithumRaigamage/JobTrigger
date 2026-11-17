const crypto = require('node:crypto');
const { expect } = require('chai');

const DeviceToken = require('../models/DeviceToken');
const User = require('../models/User');
const { pushConfig } = require('../config/env');
const { api } = require('./support/api');
const { sendToUser, pushesEnabled, setSenderForTests, signedAssertion } = require('../lib/push');

let counter = 0;

async function signup() {
  counter += 1;
  const email = `push${counter}@example.com`;
  const res = await api().post('/api/auth/signup').send({ email, password: 'password' });
  const user = await User.findOne({ email }).lean();
  return { token: res.body.token, id: user._id, email };
}

describe('Server push — device registration (NR-06)', function() {
  it('registers a device for the caller, idempotently', async function() {
    const { token, id } = await signup();
    const pushToken = `ios-token-${counter}-abcdefgh`;

    const first = await api().post('/api/devices').set('x-auth-token', token)
      .send({ token: pushToken, platform: 'ios' });
    expect(first.status).to.equal(204);

    const again = await api().post('/api/devices').set('x-auth-token', token)
      .send({ token: pushToken, platform: 'ios' });
    expect(again.status).to.equal(204);

    const rows = await DeviceToken.find({ token: pushToken }).lean();
    expect(rows).to.have.length(1);
    expect(String(rows[0].userId)).to.equal(String(id));
    expect(rows[0].platform).to.equal('ios');
  });

  it('refuses a missing token and an unknown platform', async function() {
    const { token } = await signup();

    const noToken = await api().post('/api/devices').set('x-auth-token', token)
      .send({ platform: 'ios' });
    expect(noToken.status).to.equal(400);

    const badPlatform = await api().post('/api/devices').set('x-auth-token', token)
      .send({ token: 'android-token-abcdefgh', platform: 'windows' });
    expect(badPlatform.status).to.equal(400);
  });

  it('needs a session', async function() {
    const res = await api().post('/api/devices').send({ token: 'unauthenticated-token', platform: 'ios' });
    expect(res.status).to.equal(401);
  });

  it('lets only the owner unregister a token', async function() {
    const owner = await signup();
    const other = await signup();
    const pushToken = `shared-token-${counter}-abcdefgh`;
    await api().post('/api/devices').set('x-auth-token', owner.token)
      .send({ token: pushToken, platform: 'android' });

    const byOther = await api().delete(`/api/devices/${pushToken}`).set('x-auth-token', other.token);
    expect(byOther.status).to.equal(204);
    expect(await DeviceToken.countDocuments({ token: pushToken })).to.equal(1);

    const byOwner = await api().delete(`/api/devices/${pushToken}`).set('x-auth-token', owner.token);
    expect(byOwner.status).to.equal(204);
    expect(await DeviceToken.countDocuments({ token: pushToken })).to.equal(0);
  });
});

describe('Server push — delivery (NR-06)', function() {
  afterEach(() => setSenderForTests(null));

  it('is off unless a service account is configured', async function() {
    delete process.env.FCM_SERVICE_ACCOUNT;

    expect(pushConfig({})).to.equal(null);
    expect(pushConfig({ FCM_SERVICE_ACCOUNT: 'not json' })).to.equal(null);
    expect(pushConfig({ FCM_SERVICE_ACCOUNT: '{"project_id":"p"}' })).to.equal(null);
    expect(pushesEnabled()).to.equal(false);
    expect(await sendToUser('507f1f77bcf86cd799439011', { title: 'Build finished' }))
      .to.deep.equal({ sent: 0, failed: 0, removed: 0 });
  });

  it('reads a service account, unescaping its private key', function() {
    const config = pushConfig({
      FCM_SERVICE_ACCOUNT: JSON.stringify({
        project_id: 'jobtrigger',
        client_email: 'push@jobtrigger.iam.gserviceaccount.com',
        private_key: '-----BEGIN PRIVATE KEY-----\\nabc\\n-----END PRIVATE KEY-----\\n'
      })
    });

    expect(config.projectId).to.equal('jobtrigger');
    expect(config.privateKey).to.contain('\n');
  });

  it('signs the OAuth assertion FCM expects', function() {
    const { privateKey } = crypto.generateKeyPairSync('rsa', { modulusLength: 2048 });
    const assertion = signedAssertion(
      { clientEmail: 'push@jobtrigger.iam.gserviceaccount.com', privateKey: privateKey.export({ type: 'pkcs8', format: 'pem' }) },
      1700000000
    );

    expect(assertion.split('.')).to.have.length(3);
    const claims = JSON.parse(Buffer.from(assertion.split('.')[1], 'base64url').toString());
    expect(claims.iss).to.equal('push@jobtrigger.iam.gserviceaccount.com');
    expect(claims.aud).to.equal('https://oauth2.googleapis.com/token');
    expect(claims.exp).to.equal(1700003600);
  });

  it('delivers to every device and counts them', async function() {
    const { id } = await signup();
    const pushToken = `deliver-token-${counter}-abcdefgh`;
    await DeviceToken.create({ userId: id, platform: 'ios', token: pushToken });

    const sent = [];
    setSenderForTests(async (token, message) => { sent.push([token, message.title]); });

    const result = await sendToUser(id, { title: 'Build #12 failed', body: 'api' });

    expect(result).to.deep.equal({ sent: 1, failed: 0, removed: 0 });
    expect(sent).to.deep.equal([[pushToken, 'Build #12 failed']]);
  });

  it('deletes a token FCM reports as unregistered', async function() {
    const { id } = await signup();
    const pushToken = `gone-token-${counter}-abcdefgh`;
    await DeviceToken.create({ userId: id, platform: 'android', token: pushToken });

    setSenderForTests(async () => {
      const error = new Error('FCM HTTP 404');
      error.unregistered = true;
      throw error;
    });

    const result = await sendToUser(id, { title: 'Build finished' });

    expect(result).to.deep.equal({ sent: 0, failed: 0, removed: 1 });
    expect(await DeviceToken.countDocuments({ token: pushToken })).to.equal(0);
  });
});
