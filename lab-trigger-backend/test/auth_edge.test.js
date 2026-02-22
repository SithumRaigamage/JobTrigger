const request = require('supertest');
const { expect } = require('chai');
const { app } = require('../server');

describe('Auth edge cases', function() {
  it('should not allow signup with short password', async function() {
    const res = await request(app)
      .post('/api/auth/signup')
      .send({ email: 'shortpw@example.com', password: '123' });

    expect(res.status).to.equal(400);
    expect(res.body.message).to.match(/at least 6/);
  });

  it('should not allow duplicate signup', async function() {
    const payload = { email: 'dup@example.com', password: 'password' };
    // First signup
    const r1 = await request(app).post('/api/auth/signup').send(payload);
    expect(r1.status).to.equal(201);

    // Duplicate
    const r2 = await request(app).post('/api/auth/signup').send(payload);
    expect(r2.status).to.equal(400);
    expect(r2.body.message).to.match(/already exists/i);
  });

  it('should not login with wrong password', async function() {
    const email = 'wrongpw@example.com';
    const pw = 'correctpw';
    await request(app).post('/api/auth/signup').send({ email, password: pw });

    const res = await request(app).post('/api/auth/login').send({ email, password: 'bad' });
    expect(res.status).to.equal(400);
    expect(res.body.message).to.match(/Invalid credentials/i);
  });

  it('should not login non-existing user', async function() {
    const res = await request(app).post('/api/auth/login').send({ email: 'noone@example.com', password: 'pw' });
    expect(res.status).to.equal(400);
  });
});
