const request = require('supertest');
const { expect } = require('chai');
const { app } = require('../server');

describe('GitHub Credentials API', function() {
  let token;

  before(async function() {
    const signupRes = await request(app)
      .post('/api/auth/signup')
      .send({ email: 'ghcreduser@example.com', password: 'password' });

    token = signupRes.body.token;
  });

  it('should add a credential for authenticated user', async function() {
    const credential = {
      label: 'Personal',
      token: 'ghp_faketoken1234567890',
      defaultOwner: 'octocat',
      isDefault: true
    };

    const res = await request(app)
      .post('/api/github-credentials')
      .set('x-auth-token', token)
      .send(credential);

    expect(res.status).to.equal(201);
    expect(res.body).to.have.property('_id');
    expect(res.body.label).to.equal('Personal');
    expect(res.body.defaultOwner).to.equal('octocat');
  });

  it('should retrieve credentials for authenticated user', async function() {
    const res = await request(app)
      .get('/api/github-credentials')
      .set('x-auth-token', token);

    expect(res.status).to.equal(200);
    expect(res.body).to.be.an('array');
    expect(res.body.length).to.be.greaterThan(0);
  });

  it('should update a credential', async function() {
    const addRes = await request(app)
      .post('/api/github-credentials')
      .set('x-auth-token', token)
      .send({ label: 'Work', token: 'ghp_original', isDefault: false });
    const id = addRes.body._id;

    const updateRes = await request(app)
      .put(`/api/github-credentials/${id}`)
      .set('x-auth-token', token)
      .send({ label: 'Work Org', token: 'ghp_rotated', isDefault: false });

    expect(updateRes.status).to.equal(200);
    expect(updateRes.body.label).to.equal('Work Org');
  });

  it('should delete a credential', async function() {
    const addRes = await request(app)
      .post('/api/github-credentials')
      .set('x-auth-token', token)
      .send({ label: 'Temp', token: 'ghp_temp', isDefault: false });
    const id = addRes.body._id;

    const deleteRes = await request(app)
      .delete(`/api/github-credentials/${id}`)
      .set('x-auth-token', token);

    expect(deleteRes.status).to.equal(200);
  });

  it('should switch the active credential', async function() {
    const first = await request(app)
      .post('/api/github-credentials')
      .set('x-auth-token', token)
      .send({ label: 'First', token: 'ghp_first', isDefault: true });
    const second = await request(app)
      .post('/api/github-credentials')
      .set('x-auth-token', token)
      .send({ label: 'Second', token: 'ghp_second', isDefault: false });

    const switchRes = await request(app)
      .post(`/api/github-credentials/switch/${second.body._id}`)
      .set('x-auth-token', token);

    expect(switchRes.status).to.equal(200);
    expect(switchRes.body.isDefault).to.equal(true);

    const firstAfter = await request(app)
      .get('/api/github-credentials')
      .set('x-auth-token', token)
      .then(res => res.body.find(c => c._id === first.body._id));
    expect(firstAfter.isDefault).to.equal(false);
  });
});

describe('GitHub Credentials ownership and defaults', function() {
  it("should prevent one user from updating another user's credential", async function() {
    const a = await request(app).post('/api/auth/signup').send({ email: 'gha@example.com', password: 'password' });
    const tokenA = a.body.token;

    const credRes = await request(app)
      .post('/api/github-credentials')
      .set('x-auth-token', tokenA)
      .send({ label: 'A GitHub', token: 'ghp_a', isDefault: false });

    expect(credRes.status).to.equal(201);
    const credId = credRes.body._id;

    const b = await request(app).post('/api/auth/signup').send({ email: 'ghb@example.com', password: 'password' });
    const tokenB = b.body.token;

    const updateRes = await request(app)
      .put(`/api/github-credentials/${credId}`)
      .set('x-auth-token', tokenB)
      .send({ label: 'B Hacked', token: 'ghp_b', isDefault: false });

    expect(updateRes.status).to.equal(401);

    const deleteRes = await request(app)
      .delete(`/api/github-credentials/${credId}`)
      .set('x-auth-token', tokenB);

    expect(deleteRes.status).to.equal(401);
  });

  it('should ensure only one default credential per user when adding', async function() {
    const u = await request(app).post('/api/auth/signup').send({ email: 'ghdef@example.com', password: 'password' });
    const token = u.body.token;

    const c1 = await request(app)
      .post('/api/github-credentials')
      .set('x-auth-token', token)
      .send({ label: 'G1', token: 'ghp_g1', isDefault: true });
    expect(c1.status).to.equal(201);

    const c2 = await request(app)
      .post('/api/github-credentials')
      .set('x-auth-token', token)
      .send({ label: 'G2', token: 'ghp_g2', isDefault: true });
    expect(c2.status).to.equal(201);

    const all = await request(app).get('/api/github-credentials').set('x-auth-token', token);
    expect(all.status).to.equal(200);
    const defaults = all.body.filter(c => c.isDefault);
    expect(defaults.length).to.equal(1);
  });
});
