const request = require('supertest');
const { expect } = require('chai');
const { app } = require('../server');

describe('Auth edge cases', function() {
  it('should not allow signup with short password', async function() {
    const res = await request(app)
      .post('/api/auth/signup')
      .send({ email: 'shortpw@example.com', password: '123' });

    expect(res.status).to.equal(400);
    expect(res.body.message).to.match(/at least 8/);
  });

  it('should not allow a 7-character password (AUD-26)', async function() {
    const res = await request(app)
      .post('/api/auth/signup')
      .send({ email: 'seven@example.com', password: 'abcdefg' });
    expect(res.status).to.equal(400);
    expect(res.body.message).to.match(/at least 8/);
  });

  it('should not allow a password bcrypt would truncate', async function() {
    const res = await request(app)
      .post('/api/auth/signup')
      .send({ email: 'long@example.com', password: 'x'.repeat(73) });
    expect(res.status).to.equal(400);
    expect(res.body.message).to.match(/too long/i);
  });

  it('should not allow signup with a malformed email (AUD-26)', async function() {
    for (const email of ['no-at-sign.com', 'a@b', 'spaces in@example.com']) {
      const res = await request(app)
        .post('/api/auth/signup')
        .send({ email, password: 'password' });
      expect(res.status, email).to.equal(400);
      expect(res.body.message).to.match(/valid email/i);
    }
  });

  describe('operator injection (AUD-04)', function() {
    beforeEach(async function() {
      await request(app)
        .post('/api/auth/signup')
        .send({ email: 'victim@example.com', password: 'password' });
    });

    it('rejects an operator object as the login email', async function() {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ email: { $gt: '' }, password: 'password' });
      expect(res.status).to.equal(400);
      expect(res.body.token).to.be.undefined;
    });

    it('rejects an operator object as the login password', async function() {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ email: 'victim@example.com', password: { $ne: null } });
      expect(res.status).to.equal(400);
      expect(res.body.token).to.be.undefined;
    });

    it('rejects non-string signup fields', async function() {
      for (const body of [
        { email: ['a@b.com'], password: 'password' },
        { email: 'num@example.com', password: 12345678 },
      ]) {
        const res = await request(app).post('/api/auth/signup').send(body);
        expect(res.status).to.equal(400);
      }
    });
  });

  it('matches the email case- and space-insensitively at login', async function() {
    await request(app)
      .post('/api/auth/signup')
      .send({ email: 'Mixed@Example.com', password: 'password' });
    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: '  mixed@example.COM ', password: 'password' });
    expect(res.status).to.equal(200);
    expect(res.body.token).to.be.a('string');
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

  it('should not allow signup with a missing email', async function() {
    const res = await request(app).post('/api/auth/signup').send({ password: 'password' });
    expect(res.status).to.equal(400);
    expect(res.body.message).to.match(/required/i);
  });

  it('should not allow signup with a missing password', async function() {
    const res = await request(app).post('/api/auth/signup').send({ email: 'nopassword@example.com' });
    expect(res.status).to.equal(400);
    expect(res.body.message).to.match(/required/i);
  });
});
