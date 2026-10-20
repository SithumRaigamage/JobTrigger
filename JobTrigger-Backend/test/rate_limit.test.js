const request = require('supertest');
const { expect } = require('chai');
const express = require('express');
const { authLimiter, refreshKey } = require('../middleware/rateLimit');
const { issueTokens } = require('../security/tokens');

// A small app with tiny limits, so the suites' generous limits (setup.js)
// don't hide the behaviour. Listening once for the whole test, like
// test/support/api.js, rather than a throwaway server per request.
const servers = [];

function probe(options) {
  const app = express();
  app.use(express.json());
  app.post('/attempt', authLimiter({ windowMs: 60000, ...options }), (req, res) => {
    const ok = req.query.ok === '1';
    res.status(ok ? 200 : 400).json({ ok });
  });
  const server = app.listen(0);
  servers.push(server);
  return server;
}

describe('Auth rate limiting (AUD-05)', function() {
  afterEach(function() {
    while (servers.length) servers.pop().close();
  });

  it('answers 429 with a JSON message once the limit is reached', async function() {
    const app = probe({ limit: 2 });
    await request(app).post('/attempt');
    await request(app).post('/attempt');
    const res = await request(app).post('/attempt');
    expect(res.status).to.equal(429);
    expect(res.body.message).to.match(/too many attempts/i);
    expect(res.headers).to.have.property('ratelimit');
  });

  it('only counts failures when told to (login)', async function() {
    const app = probe({ limit: 1, skipSuccessfulRequests: true });
    for (let i = 0; i < 3; i++) {
      const ok = await request(app).post('/attempt?ok=1');
      expect(ok.status).to.equal(200);
    }
    await request(app).post('/attempt'); // One failure uses the quota.
    const res = await request(app).post('/attempt?ok=1');
    expect(res.status).to.equal(429);
  });

  // AUD-47: a whole office shares one IP; refreshes are counted per user.
  it('counts refreshes per user, not per IP', async function() {
    const app = probe({ limit: 1, keyGenerator: refreshKey });
    const tokenFor = (id) =>
      issueTokens({ _id: id, tokenVersion: 0 }).refreshToken;
    const alice = tokenFor('64b000000000000000000001');
    const bob = tokenFor('64b000000000000000000002');

    expect((await request(app).post('/attempt?ok=1').send({ refreshToken: alice })).status)
      .to.equal(200);
    expect((await request(app).post('/attempt?ok=1').send({ refreshToken: bob })).status)
      .to.equal(200);
    expect((await request(app).post('/attempt?ok=1').send({ refreshToken: alice })).status)
      .to.equal(429);
  });

  it('counts refreshes without a valid token against the IP', async function() {
    const app = probe({ limit: 1, keyGenerator: refreshKey });
    await request(app).post('/attempt').send({ refreshToken: 'garbage' });
    const res = await request(app).post('/attempt').send({});
    expect(res.status).to.equal(429);
  });
});
