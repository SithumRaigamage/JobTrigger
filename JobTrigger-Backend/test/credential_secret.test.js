const { api } = require('./support/api');
const { captureLogs } = require('./support/logs');
const { expect } = require('chai');

/**
 * E4 (PE-32): lists, creates, updates and switches carry masks only. The
 * decrypted secret comes from GET /:id/secret and nowhere else: owner-only,
 * `no-store`, rate-limited.
 */
const routes = [
  {
    path: '/api/credentials',
    body: { serverName: 'S', jenkinsURL: 'http://s', username: 'u', password: 'jenkins-secret-1', paramToken: 'trigger-secret-1' },
    secret: { password: 'jenkins-secret-1', paramToken: 'trigger-secret-1' },
    secrets: ['jenkins-secret-1', 'trigger-secret-1'],
    mask: '••••et-1',
  },
  {
    path: '/api/github-credentials',
    body: { label: 'G', token: 'ghp_secret_value' },
    secret: { token: 'ghp_secret_value' },
    secrets: ['ghp_secret_value'],
    mask: '••••alue',
  },
  {
    path: '/api/sonarqube-credentials',
    body: { label: 'Q', baseUrl: 'https://sonarcloud.io', token: 'sq_secret_value' },
    secret: { token: 'sq_secret_value' },
    secrets: ['sq_secret_value'],
    mask: '••••alue',
  },
];

let counter = 0;
async function signup() {
  counter += 1;
  const res = await api()
    .post('/api/auth/signup')
    .send({ email: `secret${counter}@example.com`, password: 'password' });
  return res.body.token;
}

for (const { path, body, secret, secrets, mask } of routes) {
  describe(`Credential secret for ${path} (E4)`, function() {
    let token;
    let id;

    before(async function() {
      token = await signup();
      const created = await api().post(path).set('x-auth-token', token).send(body);
      expect(created.status).to.equal(201);
      id = created.body._id;
    });

    it('returns no secret from create, list, update or switch', async function() {
      const responses = [
        await api().get(path).set('x-auth-token', token),
        await api().put(`${path}/${id}`).set('x-auth-token', token).send({ isDefault: false }),
        await api().post(`${path}/switch/${id}`).set('x-auth-token', token),
        await api().post(path).set('x-auth-token', token).send(body).then((r) => {
          // A second credential of the same tool may hit the free-plan
          // limit; the 403 body must be secret-free too.
          return r;
        }),
      ];
      for (const res of responses) {
        for (const value of secrets) {
          expect(JSON.stringify(res.body), `${res.status} ${res.req.path}`).to.not.include(value);
        }
      }
      const list = responses[0].body.find((c) => c._id === id);
      expect(list.secretMask).to.equal(mask);
    });

    it('returns the decrypted secret to its owner, uncached', async function() {
      const res = await api().get(`${path}/${id}/secret`).set('x-auth-token', token);
      expect(res.status).to.equal(200);
      expect(res.headers['cache-control']).to.equal('no-store');
      expect(res.headers.pragma).to.equal('no-cache');
      expect(res.body).to.include(secret);
      expect(res.body.needsReentry).to.equal(false);
      expect(new Date(res.body.version).toISOString()).to.equal(res.body.version);
    });

    it('changes its version when the credential is saved', async function() {
      const before = await api().get(`${path}/${id}/secret`).set('x-auth-token', token);
      await new Promise((resolve) => setTimeout(resolve, 5));
      await api().put(`${path}/${id}`).set('x-auth-token', token).send({ isDefault: false });
      const after = await api().get(`${path}/${id}/secret`).set('x-auth-token', token);
      expect(after.body.version).to.not.equal(before.body.version);
    });

    it('is a 404 for another user, a missing id and a bad id', async function() {
      const other = await signup();
      const stranger = await api().get(`${path}/${id}/secret`).set('x-auth-token', other);
      expect(stranger.status).to.equal(404);
      expect(JSON.stringify(stranger.body)).to.not.include(secrets[0]);
      const missing = await api()
        .get(`${path}/64b0000000000000000000aa/secret`)
        .set('x-auth-token', token);
      expect(missing.status).to.equal(404);
      expect((await api().get(`${path}/nope/secret`).set('x-auth-token', token)).status).to.equal(400);
    });

    it('needs a session', async function() {
      const res = await api().get(`${path}/${id}/secret`);
      expect(res.status).to.equal(401);
    });

    it('is rate limited per user', async function() {
      const limited = await signup();
      const mine = await api().post(path).set('x-auth-token', limited).send(body);
      let last;
      for (let i = 0; i < 31; i += 1) {
        last = await api().get(`${path}/${mine.body._id}/secret`).set('x-auth-token', limited);
      }
      expect(last.status).to.equal(429);
      expect(JSON.stringify(last.body)).to.not.include(secrets[0]);
      // Another user is unaffected.
      const fine = await api().get(`${path}/${id}/secret`).set('x-auth-token', token);
      expect(fine.status).to.equal(200);
    });

    // PE-33: nothing a credential route logs may carry a secret.
    it('logs no secret from any credential route', async function() {
      const logger = await signup();
      const entries = await captureLogs(async () => {
        const created = await api().post(path).set('x-auth-token', logger).send(body);
        const cid = created.body._id;
        await api().get(path).set('x-auth-token', logger);
        await api().put(`${path}/${cid}`).set('x-auth-token', logger).send({ ...body, isDefault: true });
        await api().put(`${path}/${cid}`).set('x-auth-token', logger).send({ ...body, [Object.keys(secret)[0]]: { $gt: '' } });
        await api().post(`${path}/switch/${cid}`).set('x-auth-token', logger);
        await api().get(`${path}/${cid}/secret`).set('x-auth-token', logger);
        await api().get(`${path}/${cid}/secret`).set('x-auth-token', await signup());
        await api().get(`${path}/nope/secret`).set('x-auth-token', logger);
        await api().delete(`${path}/${cid}`).set('x-auth-token', logger);
      });
      expect(entries.length).to.be.greaterThan(0);
      const text = JSON.stringify(entries);
      for (const value of secrets) expect(text).to.not.include(value);
    });
  });
}
