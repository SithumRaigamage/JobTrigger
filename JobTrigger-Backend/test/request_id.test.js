const request = require('supertest');
const express = require('express');
const { api } = require('./support/api');
const { captureLogs, linesWith } = require('./support/logs');
const { expect } = require('chai');
const requestId = require('../middleware/requestId');
const requestLogger = require('../middleware/requestLogger');
const User = require('../models/User');
const AppInfo = require('../models/AppInfo');

/** §19: a request id on every request, and a log line to match it to. */
describe('Request ids and structured logs (§19)', function() {
  it('echoes a valid inbound x-request-id', async function() {
    const res = await api().get('/').set('x-request-id', 'client-abc_123.XYZ');
    expect(res.status).to.equal(200);
    expect(res.headers['x-request-id']).to.equal('client-abc_123.XYZ');
  });

  it('generates a request id when the header is missing', async function() {
    const res = await api().get('/');
    expect(res.status).to.equal(200);
    expect(res.headers['x-request-id']).to.match(
      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/,
    );
  });

  it('replaces an untrusted x-request-id rather than logging it', async function() {
    for (const value of [
      'has spaces',
      'has"quote',
      'a'.repeat(65),
      '',
    ]) {
      const res = await api().get('/').set('x-request-id', value);
      expect(res.status).to.equal(200);
      expect(res.headers['x-request-id']).to.not.equal(value);
      expect(res.headers['x-request-id']).to.match(
        /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/,
      );
    }
  });

  it('carries the request id on the 500 body', async function() {
    const original = AppInfo.findOne;
    AppInfo.findOne = async () => {
      throw new Error('boom');
    };
    try {
      const res = await api()
        .get('/api/appinfo')
        .set('x-request-id', 'boom-500');
      expect(res.status).to.equal(500);
      expect(res.body.message).to.equal('Server error');
      expect(res.body.requestId).to.equal('boom-500');
      expect(res.headers['x-request-id']).to.equal('boom-500');
    } finally {
      AppInfo.findOne = original;
    }
  });

  it('logs one line per finished request, without the query string', async function() {
    const app = express();
    app.use(requestId);
    app.use(requestLogger);
    app.get('/probe', (req, res) => res.json({ ok: true }));

    const entries = await captureLogs(async () => {
      const res = await request(app).get('/probe?token=secretvalue');
      expect(res.status).to.equal(200);
      // The response is flushed before the server's 'finish' event.
      await new Promise((resolve) => setTimeout(resolve, 50));
    });

    const logged = linesWith(entries, 'http.request');
    expect(logged.length).to.equal(1);
    const entry = logged[0];
    expect(entry.method).to.equal('GET');
    expect(entry.path).to.equal('/probe');
    expect(entry.status).to.equal(200);
    expect(entry.durationMs).to.be.a('number');
    expect(entry.requestId).to.be.a('string');
    expect(entry.level).to.equal('info');
    expect(entry.time).to.be.a('string');
    // The query string can carry a token; it never reaches the log.
    expect(JSON.stringify(entry)).to.not.include('secretvalue');
  });

  it('names the user on the line of an authenticated request', async function() {
    const signup = await api()
      .post('/api/auth/signup')
      .send({ email: 'reqid-user@example.com', password: 'password' });

    const entries = await captureLogs(async () => {
      await api().get('/api/credentials').set('x-auth-token', signup.body.token);
      await new Promise((resolve) => setTimeout(resolve, 50));
    });

    const entry = linesWith(entries, 'http.request').find(
      (e) => e.path === '/api/credentials',
    );
    expect(entry, 'the request was logged').to.exist;
    expect(entry.userId).to.equal(signup.body.user._id);
  });

  it('logs each authentication outcome under its own message', async function() {
    const signup = await api()
      .post('/api/auth/signup')
      .send({ email: 'reqid-auth@example.com', password: 'password' });

    const entries = await captureLogs(async () => {
      await api().get('/api/credentials');
      await api().get('/api/credentials').set('x-auth-token', 'not-a-token');
      await api().get('/api/credentials').set('x-auth-token', signup.body.token);
      await new Promise((resolve) => setTimeout(resolve, 50));
    });

    const messages = entries.map((entry) => entry.msg);
    expect(messages).to.include('auth.no_token');
    expect(messages).to.include('auth.invalid_token');
    expect(messages).to.include('auth.ok');

    // The token itself is never in a log line.
    expect(JSON.stringify(entries)).to.not.include(signup.body.token);
    for (const entry of entries) {
      if (entry.msg?.startsWith('auth.')) {
        expect(entry.level, entry.msg).to.be.oneOf(['info', 'warn']);
        expect(entry.requestId, entry.msg).to.be.a('string');
      }
    }
  });

  it('logs a token that is no longer current', async function() {
    const signup = await api()
      .post('/api/auth/signup')
      .send({ email: 'reqid-stale@example.com', password: 'password' });
    await User.findByIdAndDelete(signup.body.user._id);

    const entries = await captureLogs(async () => {
      await api().get('/api/credentials').set('x-auth-token', signup.body.token);
      await new Promise((resolve) => setTimeout(resolve, 50));
    });

    expect(entries.map((entry) => entry.msg)).to.include('auth.token_not_current');
  });
});
