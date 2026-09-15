const request = require('supertest');
const { expect } = require('chai');
const { app } = require('../server');

describe('Credentials ownership and defaults', function() {
  it('should prevent one user from updating another user\'s credential', async function() {
    // User A
    const a = await request(app).post('/api/auth/signup').send({ email: 'a@example.com', password: 'password' });
    const tokenA = a.body.token;

    // Create credential as A
    const credRes = await request(app)
      .post('/api/credentials')
      .set('x-auth-token', tokenA)
      .send({ serverName: 'A Jenkins', jenkinsURL: 'http://a', username: 'a', password: 'p', isDefault: false });

    expect(credRes.status).to.equal(201);
    const credId = credRes.body._id;

    // User B
    const b = await request(app).post('/api/auth/signup').send({ email: 'b@example.com', password: 'password' });
    const tokenB = b.body.token;

    // Attempt update by B
    const updateRes = await request(app)
      .put(`/api/credentials/${credId}`)
      .set('x-auth-token', tokenB)
      .send({ serverName: 'B Hacked', jenkinsURL: 'http://b', username: 'b', password: 'p' });

    expect(updateRes.status).to.equal(401);

    // Attempt delete by B
    const deleteRes = await request(app)
      .delete(`/api/credentials/${credId}`)
      .set('x-auth-token', tokenB);

    expect(deleteRes.status).to.equal(401);
  });

  it('should ensure only one default credential per user when adding', async function() {
    const u = await request(app).post('/api/auth/signup').send({ email: 'def@example.com', password: 'password' });
    const token = u.body.token;

    // Add first credential as default
    const c1 = await request(app)
      .post('/api/credentials')
      .set('x-auth-token', token)
      .send({ serverName: 'J1', jenkinsURL: 'http://j1', username: 'u1', password: 'p1', isDefault: true });
    expect(c1.status).to.equal(201);

    // Add second credential also as default
    const c2 = await request(app)
      .post('/api/credentials')
      .set('x-auth-token', token)
      .send({ serverName: 'J2', jenkinsURL: 'http://j2', username: 'u2', password: 'p2', isDefault: true });
    expect(c2.status).to.equal(201);

    // Fetch credentials and ensure only one is default
    const all = await request(app).get('/api/credentials').set('x-auth-token', token);
    expect(all.status).to.equal(200);
    const defaults = all.body.filter(c => c.isDefault);
    expect(defaults.length).to.equal(1);
  });
});
