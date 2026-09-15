const request = require('supertest');
const { expect } = require('chai');
const { app } = require('../server');

describe('Credentials API', function() {
  let token;

  before(async function() {
    // Create a user and retrieve token
    const signupRes = await request(app)
      .post('/api/auth/signup')
      .send({ email: 'creduser@example.com', password: 'password' });

    token = signupRes.body.token;
  });

  it('should add a credential for authenticated user', async function() {
    const credential = {
      serverName: 'Test Jenkins',
      jenkinsURL: 'http://localhost:8080',
      username: 'jenkins_user',
      password: 'jenkins_password',
      paramToken: 'param',
      isDefault: true
    };

    const res = await request(app)
      .post('/api/credentials')
      .set('x-auth-token', token)
      .send(credential);

    expect(res.status).to.equal(201);
    expect(res.body).to.have.property('_id');
    expect(res.body.serverName).to.equal('Test Jenkins');
  });

  it('should retrieve credentials for authenticated user', async function() {
    const res = await request(app)
      .get('/api/credentials')
      .set('x-auth-token', token);

    expect(res.status).to.equal(200);
    expect(res.body).to.be.an('array');
    expect(res.body.length).to.be.greaterThan(0);
  });

  it('should update a credential', async function() {
    const addRes = await request(app)
      .post('/api/credentials')
      .set('x-auth-token', token)
      .send({ serverName: 'Original', jenkinsURL: 'http://original', username: 'u', password: 'p', isDefault: false });
    const id = addRes.body._id;

    const updateRes = await request(app)
      .put(`/api/credentials/${id}`)
      .set('x-auth-token', token)
      .send({ serverName: 'Renamed', jenkinsURL: 'http://renamed', username: 'u', password: 'p', isDefault: false });

    expect(updateRes.status).to.equal(200);
    expect(updateRes.body.serverName).to.equal('Renamed');
  });

  it('should delete a credential', async function() {
    const addRes = await request(app)
      .post('/api/credentials')
      .set('x-auth-token', token)
      .send({ serverName: 'Temp', jenkinsURL: 'http://temp', username: 'u', password: 'p', isDefault: false });
    const id = addRes.body._id;

    const deleteRes = await request(app)
      .delete(`/api/credentials/${id}`)
      .set('x-auth-token', token);

    expect(deleteRes.status).to.equal(200);
  });

  it('should switch the active credential', async function() {
    const first = await request(app)
      .post('/api/credentials')
      .set('x-auth-token', token)
      .send({ serverName: 'First', jenkinsURL: 'http://first', username: 'u', password: 'p', isDefault: true });
    const second = await request(app)
      .post('/api/credentials')
      .set('x-auth-token', token)
      .send({ serverName: 'Second', jenkinsURL: 'http://second', username: 'u', password: 'p', isDefault: false });

    const switchRes = await request(app)
      .post(`/api/credentials/switch/${second.body._id}`)
      .set('x-auth-token', token);

    expect(switchRes.status).to.equal(200);
    expect(switchRes.body.isDefault).to.equal(true);

    const firstAfter = await request(app)
      .get('/api/credentials')
      .set('x-auth-token', token)
      .then(res => res.body.find(c => c._id === first.body._id));
    expect(firstAfter.isDefault).to.equal(false);
  });
});
