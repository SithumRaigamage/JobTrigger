const { api } = require('./support/api');
const { expect } = require('chai');

describe('Credentials ownership and defaults', function() {
  it('should prevent one user from updating another user\'s credential', async function() {
    // User A
    const a = await api().post('/api/auth/signup').send({ email: 'a@example.com', password: 'password' });
    const tokenA = a.body.token;

    // Create credential as A
    const credRes = await api()
      .post('/api/credentials')
      .set('x-auth-token', tokenA)
      .send({ serverName: 'A Jenkins', jenkinsURL: 'http://a', username: 'a', password: 'p', isDefault: false });

    expect(credRes.status).to.equal(201);
    const credId = credRes.body._id;

    // User B
    const b = await api().post('/api/auth/signup').send({ email: 'b@example.com', password: 'password' });
    const tokenB = b.body.token;

    // Attempt update by B
    const updateRes = await api()
      .put(`/api/credentials/${credId}`)
      .set('x-auth-token', tokenB)
      .send({ serverName: 'B Hacked', jenkinsURL: 'http://b', username: 'b', password: 'p' });

    expect(updateRes.status).to.equal(404); // AUD-24: indistinguishable from missing.

    // Attempt delete by B
    const deleteRes = await api()
      .delete(`/api/credentials/${credId}`)
      .set('x-auth-token', tokenB);

    expect(deleteRes.status).to.equal(404); // AUD-24: indistinguishable from missing.
  });

  it("should prevent one user from switching another user's credential active", async function() {
    const a = await api().post('/api/auth/signup').send({ email: 'switcha@example.com', password: 'password' });
    const tokenA = a.body.token;

    const credRes = await api()
      .post('/api/credentials')
      .set('x-auth-token', tokenA)
      .send({ serverName: 'A Jenkins', jenkinsURL: 'http://a', username: 'a', password: 'p', isDefault: false });
    const credId = credRes.body._id;

    const b = await api().post('/api/auth/signup').send({ email: 'switchb@example.com', password: 'password' });
    const tokenB = b.body.token;

    const switchRes = await api()
      .post(`/api/credentials/switch/${credId}`)
      .set('x-auth-token', tokenB);

    expect(switchRes.status).to.equal(404); // AUD-24: indistinguishable from missing.
  });

  it('should ensure only one default credential per user when adding', async function() {
    const u = await api().post('/api/auth/signup').send({ email: 'def@example.com', password: 'password' });
    const token = u.body.token;

    // Add first credential as default
    const c1 = await api()
      .post('/api/credentials')
      .set('x-auth-token', token)
      .send({ serverName: 'J1', jenkinsURL: 'http://j1', username: 'u1', password: 'p1', isDefault: true });
    expect(c1.status).to.equal(201);

    // Add second credential also as default
    const c2 = await api()
      .post('/api/credentials')
      .set('x-auth-token', token)
      .send({ serverName: 'J2', jenkinsURL: 'http://j2', username: 'u2', password: 'p2', isDefault: true });
    expect(c2.status).to.equal(201);

    // Fetch credentials and ensure only one is default
    const all = await api().get('/api/credentials').set('x-auth-token', token);
    expect(all.status).to.equal(200);
    const defaults = all.body.filter(c => c.isDefault);
    expect(defaults.length).to.equal(1);
  });
});
