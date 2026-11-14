const { expect } = require('chai');
const { appInfoSeed } = require('../scripts/seedAppInfo');
const { invalidConfig, siteUrl } = require('../config/env');

/** PE-01/02: the About JobTrigger links point at the real website. */
describe('AppInfo seed (PE-01)', function() {
  it('links the privacy policy, terms and licenses to SITE_URL', function() {
    const seed = appInfoSeed({ SITE_URL: 'https://jobtrigger.app/' });
    expect(seed.privacyPolicyUrl).to.equal('https://jobtrigger.app/privacy');
    expect(seed.termsOfServiceUrl).to.equal('https://jobtrigger.app/terms');
    expect(seed.openSourceLicensesUrl).to.equal('https://jobtrigger.app/licenses');
  });

  it('never seeds a placeholder link', function() {
    const seed = appInfoSeed({ SITE_URL: 'https://jobtrigger.app' });
    expect(JSON.stringify(seed)).not.to.contain('example.com');
  });

  it('uses the local website when SITE_URL is unset in development', function() {
    expect(appInfoSeed({}).privacyPolicyUrl).to.equal('http://localhost:3000/privacy');
  });

  it('refuses the local default in production', function() {
    expect(() => appInfoSeed({ NODE_ENV: 'production' })).to.throw(/SITE_URL/);
  });

  it('rejects a SITE_URL with a path or query', function() {
    const key = require('crypto').randomBytes(32).toString('base64');
    const base = { CREDENTIALS_ENCRYPTION_KEY: key };
    expect(invalidConfig({ ...base, SITE_URL: 'https://jobtrigger.app/privacy' })).to.match(/SITE_URL/);
    expect(invalidConfig({ ...base, SITE_URL: 'https://jobtrigger.app?x=1' })).to.match(/SITE_URL/);
    expect(invalidConfig({ ...base, SITE_URL: 'https://jobtrigger.app' })).to.equal(null);
    expect(siteUrl({ SITE_URL: ' https://jobtrigger.app// ' })).to.equal('https://jobtrigger.app');
  });
});
