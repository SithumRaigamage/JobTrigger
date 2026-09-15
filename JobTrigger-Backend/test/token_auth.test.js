const request = require('supertest');
const { expect } = require('chai');
const jwt = require('jsonwebtoken');
const { app } = require('../server');
const User = require('../models/User');

describe('Token and unauthorized access', function() {
  it('should return 401 when accessing protected route without token', async function() {
    const res = await request(app).get('/api/credentials');
    expect(res.status).to.equal(401);
    expect(res.body.message).to.match(/No token/i);
  });

  it('should return 401 when token is invalid', async function() {
    const res = await request(app).get('/api/credentials').set('x-auth-token', 'bad.token');
    expect(res.status).to.equal(401);
  });

  it('should return 401 when the token has expired', async function() {
    const signupRes = await request(app)
      .post('/api/auth/signup')
      .send({ email: 'expiring@example.com', password: 'password' });

    const expiredToken = jwt.sign({ id: signupRes.body.user._id }, process.env.JWT_SECRET, { expiresIn: '-1s' });

    const res = await request(app).get('/api/credentials').set('x-auth-token', expiredToken);
    expect(res.status).to.equal(401);
  });

  it("should return 401 once the token's user has been deleted", async function() {
    const signupRes = await request(app)
      .post('/api/auth/signup')
      .send({ email: 'deleteme@example.com', password: 'password' });
    const { token } = signupRes.body;

    await User.findByIdAndDelete(signupRes.body.user._id);

    const res = await request(app).get('/api/credentials').set('x-auth-token', token);
    expect(res.status).to.equal(401);
  });
});
