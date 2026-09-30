const { api } = require('./support/api');
const { expect } = require('chai');
const jwt = require('jsonwebtoken');

let counter = 0;
async function signup() {
  counter += 1;
  const res = await api()
    .post('/api/auth/signup')
    .send({ email: `session${counter}@example.com`, password: 'password' });
  return res.body;
}

const listCredentials = (token) =>
  api().get('/api/credentials').set('x-auth-token', token);

describe('Sessions (AUD-26)', function() {
  it('login returns a 15-minute access token and a refresh token', async function() {
    const body = await signup();
    const access = jwt.decode(body.token);
    const refresh = jwt.decode(body.refreshToken);
    expect(access.typ).to.equal('access');
    expect(access.exp - access.iat).to.equal(15 * 60);
    expect(refresh.typ).to.equal('refresh');
    expect((await listCredentials(body.token)).status).to.equal(200);
  });

  it('trades a refresh token for a working new pair', async function() {
    const { refreshToken } = await signup();
    const res = await api().post('/api/auth/refresh').send({ refreshToken });
    expect(res.status).to.equal(200);
    expect(res.body.token).to.be.a('string');
    expect(res.body.refreshToken).to.be.a('string');
    expect((await listCredentials(res.body.token)).status).to.equal(200);
  });

  it('refuses a refresh token as an access token, and the reverse', async function() {
    const { token, refreshToken } = await signup();
    expect((await listCredentials(refreshToken)).status).to.equal(401);
    const res = await api().post('/api/auth/refresh').send({ refreshToken: token });
    expect(res.status).to.equal(401);
  });

  it('refuses a missing, malformed, or non-string refresh token', async function() {
    for (const body of [{}, { refreshToken: 'nope' }, { refreshToken: { $gt: '' } }]) {
      const res = await api().post('/api/auth/refresh').send(body);
      expect(res.status).to.equal(401);
    }
  });

  it('logout everywhere revokes every access and refresh token', async function() {
    const first = await signup();
    const email = `session${counter}@example.com`;
    const second = (await api().post('/api/auth/login').send({ email, password: 'password' })).body;

    const res = await api().post('/api/auth/logout-all').set('x-auth-token', first.token);
    expect(res.status).to.equal(200);

    for (const session of [first, second]) {
      expect((await listCredentials(session.token)).status).to.equal(401);
      const refreshed = await api()
        .post('/api/auth/refresh')
        .send({ refreshToken: session.refreshToken });
      expect(refreshed.status).to.equal(401);
    }

    // Signing in again works, with the new version.
    const again = await api().post('/api/auth/login').send({ email, password: 'password' });
    expect((await listCredentials(again.body.token)).status).to.equal(200);
  });

  it('still accepts a pre-AUD-26 token until it expires', async function() {
    const body = await signup();
    const legacy = jwt.sign({ id: body.user._id }, process.env.JWT_SECRET, { expiresIn: '7d' });
    expect((await listCredentials(legacy)).status).to.equal(200);
  });
});
