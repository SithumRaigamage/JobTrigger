const { api } = require('./support/api');
const { expect } = require('chai');

describe('Auth API', function() {
  it('should signup a new user', async function() {
    const res = await api()
      .post('/api/auth/signup')
      .send({ email: 'test@example.com', password: 'password' });

    expect(res.status).to.equal(201);
    expect(res.body).to.have.property('token');
    expect(res.body.user).to.have.property('_id');
    expect(res.body.user.email).to.equal('test@example.com');
  });

  it('should login existing user', async function() {
    const res = await api()
      .post('/api/auth/login')
      .send({ email: 'test@example.com', password: 'password' });

    expect(res.status).to.equal(200);
    expect(res.body).to.have.property('token');
    expect(res.body.user.email).to.equal('test@example.com');
  });
});
