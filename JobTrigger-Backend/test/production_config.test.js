const { expect } = require('chai');
const { invalidConfig } = require('../config/env');

/**
 * Pre-release audit 2026-11-20: production refuses values copied from the
 * development lab (local website origin, Mac GlitchTip DSN, short secrets).
 */
describe('production configuration guard', function() {
  const prod = { NODE_ENV: 'production' };

  it('accepts a clean production config', function() {
    expect(invalidConfig({
      ...prod,
      JWT_SECRET: 'x'.repeat(48),
      CORS_ORIGINS: 'https://jobtrigger.app,https://www.jobtrigger.app',
      SITE_URL: 'https://jobtrigger.app',
      SENTRY_DSN: 'https://abc@errors.jobtrigger.app/2',
      UMAMI_URL: 'https://stats.jobtrigger.app',
    })).to.equal(null);
  });

  it('refuses a short JWT secret in production only', function() {
    expect(invalidConfig({ ...prod, JWT_SECRET: 'devsecret' })).to.match(/JWT_SECRET.*32/);
    expect(invalidConfig({ JWT_SECRET: 'devsecret' })).to.equal(null);
  });

  it('refuses local, LAN and http CORS origins', function() {
    for (const origin of [
      'http://localhost:3000',
      'https://localhost:3000',
      'http://jobtrigger.app',
      'https://Sithums-MacBook-Pro.local:3000',
      'https://192.168.1.53:3000',
      'https://172.20.0.4',
    ]) {
      const message = invalidConfig({ ...prod, CORS_ORIGINS: `https://jobtrigger.app,${origin}` });
      expect(message, origin).to.match(/CORS_ORIGINS/);
      expect(message).not.to.contain(origin);
    }
    // Development keeps working with the local website.
    expect(invalidConfig({ CORS_ORIGINS: 'http://localhost:3000' })).to.equal(null);
  });

  it('refuses a development DSN, site or analytics host', function() {
    const cases = {
      SENTRY_DSN: ['http://key@192.168.1.53:8000/1', 'https://key@glitchtip/1', 'https://key@10.0.0.5/1'],
      SITE_URL: ['http://jobtrigger.app', 'https://127.0.0.1'],
      UMAMI_URL: ['http://localhost:3004'],
    };
    for (const [name, values] of Object.entries(cases)) {
      for (const value of values) {
        const message = invalidConfig({ ...prod, [name]: value });
        expect(message, `${name}=${value}`).to.match(new RegExp(`${name} must be an https`));
        expect(message).not.to.contain(value);
      }
    }
  });

  it('needs a real sender when production sends mail', function() {
    const mail = { ...prod, SMTP_HOST: 'smtp.example.com', RESET_PASSWORD_URL: 'https://jobtrigger.app/reset-password' };
    expect(invalidConfig(mail)).to.match(/MAIL_FROM/);
    expect(invalidConfig({ ...mail, MAIL_FROM: 'JobTrigger <no-reply@jobtrigger.local>' })).to.match(/MAIL_FROM/);
    expect(invalidConfig({ ...mail, MAIL_FROM: 'JobTrigger <no-reply@jobtrigger.app>' })).to.equal(null);
    expect(invalidConfig({ ...mail, MAIL_FROM: 'no-reply@jobtrigger.app' })).to.equal(null);
  });
});

/**
 * Owner decision 2026-11-21: the team plan (US-SUB-11) is in the 1.0.0 code
 * but switched off; release 1.0.1 turns it on. The production blueprint must
 * say so explicitly, not rely on the variable being unset.
 */
describe('1.0.0 production blueprint: team plan off', function() {
  const fs = require('fs');
  const path = require('path');
  const { teamPlanEnabled } = require('../config/env');

  function blueprintValue(key) {
    const yaml = fs.readFileSync(path.join(__dirname, '..', '..', 'render.yaml'), 'utf8');
    const match = yaml.match(new RegExp(`- key: ${key}\\n\\s+value: "?([^"\\n]*)"?`));
    return match ? match[1] : undefined;
  }

  it('sets TEAM_PLAN_ENABLED to "false" in render.yaml', function() {
    expect(blueprintValue('TEAM_PLAN_ENABLED')).to.equal('false');
  });

  it('that value keeps every team route off', function() {
    expect(teamPlanEnabled({ TEAM_PLAN_ENABLED: blueprintValue('TEAM_PLAN_ENABLED') })).to.equal(false);
  });
});
