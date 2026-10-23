const { api } = require('./support/api');
const { expect } = require('chai');
const JenkinsCredential = require('../models/JenkinsCredential');
const GitHubCredential = require('../models/GitHubCredential');
const SonarQubeCredential = require('../models/SonarQubeCredential');
const User = require('../models/User');

let counter = 0;
async function signup() {
  counter += 1;
  const email = `account${counter}@example.com`;
  const res = await api().post('/api/auth/signup').send({ email, password: 'password' });
  return { ...res.body, email };
}

const authed = (method, path, token) => api()[method](path).set('x-auth-token', token);

async function addCredentials(token) {
  await authed('post', '/api/credentials', token).send({
    serverName: 'ci', jenkinsURL: 'https://ci.example.com', username: 'u', password: 'p',
  });
  await authed('post', '/api/github-credentials', token).send({ label: 'gh', token: 't' });
  await authed('post', '/api/sonarqube-credentials', token).send({ label: 'sq', token: 't' });
}

describe('Account deletion (AUD-48)', function() {
  it('deletes the user and every credential stored for them', async function() {
    const me = await signup();
    const other = await signup();
    await addCredentials(me.token);
    await addCredentials(other.token);

    const res = await authed('delete', '/api/auth/account', me.token).send({ password: 'password' });
    expect(res.status).to.equal(200);

    expect(await User.exists({ _id: me.user._id })).to.equal(null);
    for (const Model of [JenkinsCredential, GitHubCredential, SonarQubeCredential]) {
      expect(await Model.countDocuments({ userId: me.user._id })).to.equal(0);
      expect(await Model.countDocuments({ userId: other.user._id })).to.equal(1);
    }
    // The old tokens no longer work, and the email can sign up again.
    expect((await authed('get', '/api/credentials', me.token)).status).to.equal(401);
    const again = await api().post('/api/auth/signup').send({ email: me.email, password: 'password' });
    expect(again.status).to.equal(201);
  });

  it('refuses without the right password, and deletes nothing', async function() {
    const me = await signup();
    await addCredentials(me.token);
    for (const body of [{}, { password: 'wrong-password' }, { password: { $gt: '' } }]) {
      const res = await authed('delete', '/api/auth/account', me.token).send(body);
      expect(res.status).to.equal(400);
    }
    expect(await User.exists({ _id: me.user._id })).to.not.equal(null);
    expect(await JenkinsCredential.countDocuments({ userId: me.user._id })).to.equal(1);
  });

  it('needs a session', async function() {
    const res = await api().delete('/api/auth/account').send({ password: 'password' });
    expect(res.status).to.equal(401);
  });
});

describe('Password change (AUD-48)', function() {
  it('changes the password, revokes old sessions, and keeps this device signed in', async function() {
    const me = await signup();
    const res = await authed('post', '/api/auth/password', me.token)
      .send({ currentPassword: 'password', newPassword: 'new-password' });
    expect(res.status).to.equal(200);

    // Every earlier token is revoked; the returned pair works.
    expect((await authed('get', '/api/credentials', me.token)).status).to.equal(401);
    expect((await api().post('/api/auth/refresh').send({ refreshToken: me.refreshToken })).status)
      .to.equal(401);
    expect((await authed('get', '/api/credentials', res.body.token)).status).to.equal(200);

    const oldLogin = await api().post('/api/auth/login').send({ email: me.email, password: 'password' });
    expect(oldLogin.status).to.equal(400);
    const newLogin = await api().post('/api/auth/login').send({ email: me.email, password: 'new-password' });
    expect(newLogin.status).to.equal(200);
  });

  it('applies the signup rules to the new password', async function() {
    const me = await signup();
    for (const newPassword of ['short', 'x'.repeat(73), undefined]) {
      const res = await authed('post', '/api/auth/password', me.token)
        .send({ currentPassword: 'password', newPassword });
      expect(res.status).to.equal(400);
    }
  });

  it('refuses a wrong current password', async function() {
    const me = await signup();
    const res = await authed('post', '/api/auth/password', me.token)
      .send({ currentPassword: 'nope-nope', newPassword: 'new-password' });
    expect(res.status).to.equal(400);
    expect((await authed('get', '/api/credentials', me.token)).status).to.equal(200);
  });
});
