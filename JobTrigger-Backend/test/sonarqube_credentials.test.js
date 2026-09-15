const request = require('supertest');
const { expect } = require('chai');
const { app } = require('../server');

describe('SonarQube Credentials API', function() {
  let token;

  before(async function() {
    const signupRes = await request(app)
      .post('/api/auth/signup')
      .send({ email: 'sqcreduser@example.com', password: 'password' });

    token = signupRes.body.token;
  });

  it('should add a credential for authenticated user', async function() {
    const credential = {
      label: 'Personal',
      baseUrl: 'https://sonarcloud.io',
      token: 'squ_faketoken1234567890',
      defaultOrganization: 'octocat-org',
      isDefault: true
    };

    const res = await request(app)
      .post('/api/sonarqube-credentials')
      .set('x-auth-token', token)
      .send(credential);

    expect(res.status).to.equal(201);
    expect(res.body).to.have.property('_id');
    expect(res.body.label).to.equal('Personal');
    expect(res.body.defaultOrganization).to.equal('octocat-org');
  });

  it('should retrieve credentials for authenticated user', async function() {
    const res = await request(app)
      .get('/api/sonarqube-credentials')
      .set('x-auth-token', token);

    expect(res.status).to.equal(200);
    expect(res.body).to.be.an('array');
    expect(res.body.length).to.be.greaterThan(0);
  });

  it('should update a credential', async function() {
    const addRes = await request(app)
      .post('/api/sonarqube-credentials')
      .set('x-auth-token', token)
      .send({ label: 'Work', baseUrl: 'https://sonar.example.com', token: 'squ_original', isDefault: false });
    const id = addRes.body._id;

    const updateRes = await request(app)
      .put(`/api/sonarqube-credentials/${id}`)
      .set('x-auth-token', token)
      .send({ label: 'Work Org', baseUrl: 'https://sonar.example.com', token: 'squ_rotated', isDefault: false });

    expect(updateRes.status).to.equal(200);
    expect(updateRes.body.label).to.equal('Work Org');
  });

  it('should delete a credential', async function() {
    const addRes = await request(app)
      .post('/api/sonarqube-credentials')
      .set('x-auth-token', token)
      .send({ label: 'Temp', baseUrl: 'https://sonarcloud.io', token: 'squ_temp', isDefault: false });
    const id = addRes.body._id;

    const deleteRes = await request(app)
      .delete(`/api/sonarqube-credentials/${id}`)
      .set('x-auth-token', token);

    expect(deleteRes.status).to.equal(200);
  });

  it('should switch the active credential', async function() {
    const first = await request(app)
      .post('/api/sonarqube-credentials')
      .set('x-auth-token', token)
      .send({ label: 'First', baseUrl: 'https://sonarcloud.io', token: 'squ_first', isDefault: true });
    const second = await request(app)
      .post('/api/sonarqube-credentials')
      .set('x-auth-token', token)
      .send({ label: 'Second', baseUrl: 'https://sonarcloud.io', token: 'squ_second', isDefault: false });

    const switchRes = await request(app)
      .post(`/api/sonarqube-credentials/switch/${second.body._id}`)
      .set('x-auth-token', token);

    expect(switchRes.status).to.equal(200);
    expect(switchRes.body.isDefault).to.equal(true);

    const firstAfter = await request(app)
      .get('/api/sonarqube-credentials')
      .set('x-auth-token', token)
      .then(res => res.body.find(c => c._id === first.body._id));
    expect(firstAfter.isDefault).to.equal(false);
  });
});

describe('SonarQube Credentials ownership and defaults', function() {
  it("should prevent one user from updating another user's credential", async function() {
    const a = await request(app).post('/api/auth/signup').send({ email: 'sqa@example.com', password: 'password' });
    const tokenA = a.body.token;

    const credRes = await request(app)
      .post('/api/sonarqube-credentials')
      .set('x-auth-token', tokenA)
      .send({ label: 'A SonarQube', baseUrl: 'https://sonarcloud.io', token: 'squ_a', isDefault: false });

    expect(credRes.status).to.equal(201);
    const credId = credRes.body._id;

    const b = await request(app).post('/api/auth/signup').send({ email: 'sqb@example.com', password: 'password' });
    const tokenB = b.body.token;

    const updateRes = await request(app)
      .put(`/api/sonarqube-credentials/${credId}`)
      .set('x-auth-token', tokenB)
      .send({ label: 'B Hacked', baseUrl: 'https://sonarcloud.io', token: 'squ_b', isDefault: false });

    expect(updateRes.status).to.equal(401);

    const deleteRes = await request(app)
      .delete(`/api/sonarqube-credentials/${credId}`)
      .set('x-auth-token', tokenB);

    expect(deleteRes.status).to.equal(401);
  });

  it("should prevent one user from switching another user's credential active", async function() {
    const a = await request(app).post('/api/auth/signup').send({ email: 'sqswitcha@example.com', password: 'password' });
    const tokenA = a.body.token;

    const credRes = await request(app)
      .post('/api/sonarqube-credentials')
      .set('x-auth-token', tokenA)
      .send({ label: 'A SonarQube', baseUrl: 'https://sonarcloud.io', token: 'squ_a', isDefault: false });
    const credId = credRes.body._id;

    const b = await request(app).post('/api/auth/signup').send({ email: 'sqswitchb@example.com', password: 'password' });
    const tokenB = b.body.token;

    const switchRes = await request(app)
      .post(`/api/sonarqube-credentials/switch/${credId}`)
      .set('x-auth-token', tokenB);

    expect(switchRes.status).to.equal(401);
  });

  it('should ensure only one default credential per user when adding', async function() {
    const u = await request(app).post('/api/auth/signup').send({ email: 'sqdef@example.com', password: 'password' });
    const token = u.body.token;

    const c1 = await request(app)
      .post('/api/sonarqube-credentials')
      .set('x-auth-token', token)
      .send({ label: 'S1', baseUrl: 'https://sonarcloud.io', token: 'squ_s1', isDefault: true });
    expect(c1.status).to.equal(201);

    const c2 = await request(app)
      .post('/api/sonarqube-credentials')
      .set('x-auth-token', token)
      .send({ label: 'S2', baseUrl: 'https://sonarcloud.io', token: 'squ_s2', isDefault: true });
    expect(c2.status).to.equal(201);

    const all = await request(app).get('/api/sonarqube-credentials').set('x-auth-token', token);
    expect(all.status).to.equal(200);
    const defaults = all.body.filter(c => c.isDefault);
    expect(defaults.length).to.equal(1);
  });
});
