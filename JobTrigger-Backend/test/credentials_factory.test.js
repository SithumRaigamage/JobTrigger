const { api } = require('./support/api');
const { expect } = require('chai');

// AUD-23, AUD-24, AUD-31: behaviour of the shared credential controller,
// exercised through each of the three routes it now backs.
const routes = [
  {
    path: '/api/credentials',
    body: { serverName: 'S', jenkinsURL: 'http://s', username: 'u', password: 'p' },
    required: 'password',
  },
  {
    path: '/api/github-credentials',
    body: { label: 'G', token: 'ghp_x' },
    required: 'token',
  },
  {
    path: '/api/sonarqube-credentials',
    body: { label: 'Q', baseUrl: 'https://sonarcloud.io', token: 'sq_x' },
    required: 'token',
  },
];

let counter = 0;
async function signup() {
  counter += 1;
  const res = await api()
    .post('/api/auth/signup')
    .send({ email: `factory${counter}@example.com`, password: 'password' });
  return res.body.token;
}

for (const { path, body, required } of routes) {
  describe(`Credential controller for ${path}`, function() {
    let token;
    const create = (extra = {}) =>
      api().post(path).set('x-auth-token', token).send({ ...body, ...extra });

    beforeEach(async function() {
      token = await signup();
    });

    it('rejects blanking a required field on update (AUD-23)', async function() {
      const created = await create();
      const res = await api()
        .put(`${path}/${created.body._id}`)
        .set('x-auth-token', token)
        .send({ [required]: '' });
      expect(res.status).to.equal(400);
      expect(res.body.fields).to.include(required);
    });

    it('keeps fields the update leaves out, and refreshes updatedAt', async function() {
      const created = await create();
      await new Promise((resolve) => setTimeout(resolve, 5));
      const res = await api()
        .put(`${path}/${created.body._id}`)
        .set('x-auth-token', token)
        .send({ isDefault: false });
      expect(res.status).to.equal(200);
      expect(res.body[required]).to.equal(body[required]);
      expect(new Date(res.body.updatedAt)).to.be.above(new Date(created.body.updatedAt));
    });

    it('rejects an operator object as a field value', async function() {
      const created = await create();
      const res = await api()
        .put(`${path}/${created.body._id}`)
        .set('x-auth-token', token)
        .send({ [required]: { $gt: '' } });
      expect(res.status).to.equal(400);
    });

    it('keeps exactly one default when switching by update (AUD-24)', async function() {
      const first = await create({ isDefault: true });
      const second = await create();
      await api()
        .put(`${path}/${second.body._id}`)
        .set('x-auth-token', token)
        .send({ isDefault: true });
      const all = await api().get(path).set('x-auth-token', token);
      const defaults = all.body.filter((c) => c.isDefault).map((c) => c._id);
      expect(defaults).to.deep.equal([second.body._id]);
      expect(first.body._id).to.not.equal(second.body._id);
    });

    it('answers 404 for an unknown id on every route', async function() {
      const unknown = '0123456789abcdef01234567';
      const put = await api().put(`${path}/${unknown}`).set('x-auth-token', token).send({});
      const del = await api().delete(`${path}/${unknown}`).set('x-auth-token', token);
      const sw = await api().post(`${path}/switch/${unknown}`).set('x-auth-token', token);
      expect([put.status, del.status, sw.status]).to.deep.equal([404, 404, 404]);
    });
  });
}
