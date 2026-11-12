const { expect } = require('chai');
const { invalidConfig, mailConfig, analyticsConfig } = require('../config/env');
const { track, setSenderForTests, cleanData } = require('../lib/analytics');
const { passwordResetEmail } = require('../emails/passwordReset');

describe('Mail and analytics configuration (P20-72, P20-78)', function() {
  it('treats mail as off without SMTP_HOST', function() {
    expect(mailConfig({})).to.equal(null);
    expect(invalidConfig({})).to.equal(null);
  });

  it('reads the Mailpit settings', function() {
    expect(mailConfig({ SMTP_HOST: 'localhost', SMTP_PORT: '1025', SMTP_SECURE: 'false' }))
      .to.include({ host: 'localhost', port: 1025, secure: false, user: null });
  });

  it('refuses half-set or malformed SMTP settings', function() {
    expect(invalidConfig({ SMTP_PORT: '1025' })).to.match(/SMTP_HOST is required/);
    expect(invalidConfig({ SMTP_HOST: 'h', SMTP_USER: 'u' })).to.match(/set together/);
    expect(invalidConfig({ SMTP_HOST: 'h', SMTP_PORT: 'abc' })).to.match(/port number/);
    expect(invalidConfig({ SMTP_HOST: 'h', SMTP_SECURE: 'yes' })).to.match(/true or false/);
  });

  it('checks the reset link base and the Umami URL', function() {
    expect(invalidConfig({ RESET_PASSWORD_URL: 'http://localhost:3000/reset-password' })).to.equal(null);
    expect(invalidConfig({ RESET_PASSWORD_URL: 'http://x/reset?a=1' })).to.match(/query string/);
    expect(invalidConfig({ UMAMI_URL: 'javascript:alert(1)' })).to.match(/UMAMI_URL/);
    expect(analyticsConfig({ UMAMI_URL: 'http://localhost:3004/', UMAMI_WEBSITE_ID: 'w' }))
      .to.deep.equal({ url: 'http://localhost:3004', websiteId: 'w' });
    expect(analyticsConfig({ UMAMI_URL: 'http://localhost:3004' })).to.equal(null);
  });
});

describe('Analytics events (P20-75, P20-78)', function() {
  afterEach(function() { setSenderForTests(null); });

  it('is a no-op when Umami isn\'t configured', async function() {
    expect(await track('password_reset_requested')).to.equal(false);
  });

  it('sends catalogue events as a Umami event', async function() {
    const sent = [];
    setSenderForTests(async (url, body) => { sent.push({ url, body }); });
    expect(await track('trial_started', { product: 'yearly' })).to.equal(true);
    expect(sent[0].url).to.match(/\/api\/send$/);
    expect(sent[0].body).to.deep.include({ type: 'event' });
    expect(sent[0].body.payload).to.include({ name: 'trial_started' });
    expect(sent[0].body.payload.data).to.deep.equal({ product: 'yearly' });
  });

  it('drops names outside the catalogue', async function() {
    const sent = [];
    setSenderForTests(async (url, body) => { sent.push(body); });
    expect(await track('someone@example.com')).to.equal(false);
    expect(sent).to.have.length(0);
  });

  it('keeps only short primitive data', function() {
    expect(cleanData({ ok: 'yes', n: 2, b: true, obj: { a: 1 }, long: 'x'.repeat(65), 'bad key': 1 }))
      .to.deep.equal({ ok: 'yes', n: 2, b: true });
    expect(cleanData(null)).to.equal(undefined);
  });

  it('never throws when Umami fails', async function() {
    setSenderForTests(async () => { throw new Error('down'); });
    expect(await track('refund')).to.equal(false);
  });
});

describe('Password reset email', function() {
  it('includes both links when the website is configured, escaped in HTML', function() {
    const email = passwordResetEmail({
      webUrl: 'http://localhost:3000/reset-password?token=ab"c',
      appUrl: 'jobtrigger://app/reset-password?token=abc',
      minutes: 15,
    });
    expect(email.text).to.include('http://localhost:3000/reset-password?token=ab"c');
    expect(email.text).to.include('expires in 15 minutes');
    expect(email.html).to.include('token=ab&quot;c');
    expect(email.html).to.not.include('<img');
  });

  it('has only the app link without a website', function() {
    const email = passwordResetEmail({ webUrl: null, appUrl: 'jobtrigger://x', minutes: 15 });
    expect(email.text).to.not.include('browser');
    expect(email.text).to.include('jobtrigger://x');
  });
});
