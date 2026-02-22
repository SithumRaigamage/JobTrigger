const request = require('supertest');
const { expect } = require('chai');
const { app } = require('../server');

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
});
