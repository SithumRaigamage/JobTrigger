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
});
