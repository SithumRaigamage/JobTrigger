const fs = require('fs');
const os = require('os');
const path = require('path');
const express = require('express');
const request = require('supertest');
const { expect } = require('chai');

const { errorReportingConfig } = require('../config/env');
const errorReporting = require('../lib/errorReporting');
const { scrubEvent } = require('../lib/errorReporting/scrub');
const { createOutbox, withOutbox } = require('../lib/errorReporting/outbox');
const { errorHandler } = require('../middleware/errorHandler');
const requestId = require('../middleware/requestId');

// E3 / PE-20, PE-21: crash reporting never carries a secret, and does
// nothing without a DSN.
describe('Crash reporting (E3)', function() {
  // Assembled at runtime so no token-shaped literal sits in this file: the
  // repository guard scans the tree (AUD-66). Made up; authenticates nothing.
  const TOKEN = ['a1b2c3d4', 'e5f60718', '2a3b4c5d', '6e7f8091'].join('');
  const DSN = 'https://publickey@glitchtip.invalid/1';

  describe('configuration', function() {
    it('is off without SENTRY_DSN', function() {
      expect(errorReportingConfig({})).to.equal(null);
      expect(errorReportingConfig({ SENTRY_DSN: '  ' })).to.equal(null);
      expect(errorReporting.init(null)).to.equal(false);
      expect(errorReporting.isEnabled()).to.equal(false);
    });

    it('names the environment and release', function() {
      const dev = errorReportingConfig({ SENTRY_DSN: DSN });
      expect(dev.environment).to.equal('development');
      expect(dev.release).to.match(/^\d+\.\d+\.\d+/);
      const prod = errorReportingConfig({ SENTRY_DSN: DSN, NODE_ENV: 'production', SENTRY_RELEASE: '2.0.0+9' });
      expect(prod).to.include({ environment: 'production', release: '2.0.0+9' });
    });

    it('captures nothing when off', function() {
      expect(() => errorReporting.captureServerError(new Error('x'), {})).to.not.throw();
    });
  });

  describe('scrubEvent', function() {
    const dirty = () => ({
      message: `failed with token ${TOKEN}`,
      exception: { values: [{ type: 'Error', value: `Basic ${Buffer.from(`u:${TOKEN}`).toString('base64')} rejected` }] },
      request: {
        method: 'POST',
        url: `https://user:${TOKEN}@jenkins.example.com/job/x?token=${TOKEN}#frag`,
        query_string: `token=${TOKEN}`,
        data: { password: TOKEN },
        cookies: { sid: TOKEN },
        headers: {
          Authorization: `Bearer ${TOKEN}`,
          'x-auth-token': TOKEN,
          Cookie: `sid=${TOKEN}`,
          'Set-Cookie': `sid=${TOKEN}`,
          'PRIVATE-TOKEN': TOKEN,
          'X-Api-Key': 'whatever',
          'content-type': 'application/json',
        },
      },
      user: { id: 'abc', email: 'someone@example.com', ip_address: '1.2.3.4' },
      breadcrumbs: [{ message: `typed ${TOKEN}` }],
      extra: { uri: `mongodb+srv://admin:${TOKEN}@cluster.example.net/db`, secret: TOKEN },
    });

    it('removes the token from the message, headers and URL', function() {
      const clean = scrubEvent(dirty());
      const text = JSON.stringify(clean);
      expect(text).to.not.include(TOKEN);
      expect(text).to.not.include(Buffer.from(`u:${TOKEN}`).toString('base64'));
      expect(clean.request.url).to.equal('https://jenkins.example.com/job/x');
      expect(clean.request.headers).to.deep.equal({ 'content-type': 'application/json' });
      expect(clean.request).to.not.have.any.keys('data', 'cookies', 'query_string');
    });

    it('keeps no email, address, breadcrumbs or Mongo password', function() {
      const clean = scrubEvent(dirty());
      const text = JSON.stringify(clean);
      expect(text).to.not.include('someone@example.com');
      expect(text).to.not.include('1.2.3.4');
      expect(clean.user).to.deep.equal({ id: 'abc' });
      expect(clean).to.not.have.property('breadcrumbs');
      expect(text).to.not.include('admin:');
    });

    it('drops the event when it cannot be scrubbed', function() {
      const broken = {};
      Object.defineProperty(broken, 'message', { enumerable: true, get() { throw new Error('boom'); } });
      expect(scrubEvent(broken)).to.equal(null);
    });
  });

  describe('through the SDK', function() {
    let sent;
    let outboxDir;

    beforeEach(function() {
      sent = [];
      outboxDir = fs.mkdtempSync(path.join(os.tmpdir(), 'crash-outbox-'));
    });

    afterEach(async function() {
      await errorReporting.shutdown();
      fs.rmSync(outboxDir, { recursive: true, force: true });
    });

    const capturing = (statusCode = 200) => () => ({
      send: async (envelope) => {
        sent.push(envelope);
        return { statusCode };
      },
      flush: async () => true,
    });

    const appThatThrows = () => {
      const app = express();
      app.use(requestId);
      app.get('/boom', () => {
        throw new Error(`upstream rejected token ${TOKEN}`);
      });
      app.get('/bad', (_req, _res, next) => next(Object.assign(new Error('nope'), { status: 400 })));
      app.use(errorHandler);
      return app;
    };

    it('reports a 5xx with the token scrubbed from message, headers and URL', async function() {
      errorReporting.init(errorReportingConfig({ SENTRY_DSN: DSN }), { transport: capturing(), outboxDir });
      const res = await request(appThatThrows())
        .get(`/boom?token=${TOKEN}`)
        .set('Authorization', `Bearer ${TOKEN}`)
        .set('x-auth-token', TOKEN);
      expect(res.status).to.equal(500);
      await errorReporting.flush();

      const events = sent.flatMap((envelope) => envelope[1]).filter((item) => item[0].type === 'event');
      expect(events).to.have.lengthOf(1);
      const event = events[0][1];
      expect(event.tags.request_id).to.equal(res.body.requestId);
      expect(JSON.stringify(sent)).to.not.include(TOKEN);
    });

    it('does not report 4xx errors', async function() {
      errorReporting.init(errorReportingConfig({ SENTRY_DSN: DSN }), { transport: capturing(), outboxDir });
      const res = await request(appThatThrows()).get('/bad');
      expect(res.status).to.equal(400);
      await errorReporting.flush();
      expect(sent).to.have.lengthOf(0);
    });

    it('sends nothing without a DSN', async function() {
      errorReporting.init(errorReportingConfig({}), { transport: capturing(), outboxDir });
      await request(appThatThrows()).get('/boom');
      await errorReporting.flush();
      expect(sent).to.have.lengthOf(0);
    });

    it('keeps the scrubbed event in the outbox while the host is unreachable', async function() {
      errorReporting.init(errorReportingConfig({ SENTRY_DSN: DSN }), { transport: capturing(503), outboxDir });
      await request(appThatThrows()).get('/boom');
      await errorReporting.flush();

      const files = fs.readdirSync(outboxDir);
      expect(files).to.have.lengthOf(1);
      const file = path.join(outboxDir, files[0]);
      expect(fs.statSync(file).mode & 0o777).to.equal(0o600);
      const text = fs.readFileSync(file, 'utf8');
      expect(text).to.not.include(TOKEN);
      expect(text).to.not.include('glitchtip.invalid');
      expect(text.trim().split('\n')).to.have.lengthOf(1);
    });
  });

  describe('outbox', function() {
    let dir;
    beforeEach(function() { dir = fs.mkdtempSync(path.join(os.tmpdir(), 'crash-outbox-')); });
    afterEach(function() { fs.rmSync(dir, { recursive: true, force: true }); });

    const envelope = (id = 'e1') => [{ dsn: DSN }, [[{ type: 'event' }, { event_id: id }]]];

    it('retries stored events and deletes them once accepted', async function() {
      const outbox = createOutbox({ dir, dsn: DSN });
      expect(outbox.add(envelope('a'))).to.equal(true);
      expect(outbox.add(envelope('b'))).to.equal(true);

      const received = [];
      await outbox.drain(async (env) => { received.push(env); return { statusCode: 200 }; });
      expect(received.map((env) => env[1][0][1].event_id)).to.deep.equal(['a', 'b']);
      expect(received[0][0].dsn).to.equal(DSN);
      expect(fs.readdirSync(dir)).to.have.lengthOf(0);
    });

    it('keeps lines that still fail', async function() {
      const outbox = createOutbox({ dir, dsn: DSN });
      outbox.add(envelope('a'));
      await outbox.drain(async () => ({ statusCode: 503 }));
      expect(fs.readdirSync(dir)).to.have.lengthOf(1);
      await outbox.drain(async () => { throw new Error('offline'); });
      expect(fs.readdirSync(dir)).to.have.lengthOf(1);
    });

    it('drains on startup through the wrapped transport', async function() {
      createOutbox({ dir, dsn: DSN }).add(envelope('old'));
      const received = [];
      const wrapped = withOutbox(
        { send: async (env) => { received.push(env); return { statusCode: 200 }; }, flush: async () => true },
        createOutbox({ dir, dsn: DSN }),
        { retryEveryMs: 60000 },
      );
      await wrapped.drain();
      wrapped.stop();
      expect(received).to.have.lengthOf(1);
      expect(fs.readdirSync(dir)).to.have.lengthOf(0);
    });

    it('stops storing at the size cap', function() {
      const outbox = createOutbox({ dir, dsn: DSN, maxBytes: 100 });
      expect(outbox.add(envelope('a'))).to.equal(true);
      expect(outbox.add(envelope('b'))).to.equal(true);
      expect(outbox.add(envelope('c'))).to.equal(false);
    });

    it('removes files older than 7 days', function() {
      fs.writeFileSync(path.join(dir, '2020-01-01.jsonl'), '{}\n');
      createOutbox({ dir, dsn: DSN }).add(envelope('a'));
      expect(fs.readdirSync(dir)).to.not.include('2020-01-01.jsonl');
    });

    it('does not store anything that is not an event', function() {
      expect(createOutbox({ dir }).add([{}, [[{ type: 'session' }, {}]]])).to.equal(false);
    });
  });
});
