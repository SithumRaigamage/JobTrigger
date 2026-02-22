const request = require('supertest');
const { expect } = require('chai');
const { app } = require('../server');
const AppInfo = require('../models/AppInfo');

describe('AppInfo API', function() {
  it('should return 404 when no AppInfo exists, then return seeded info', async function() {
    // Ensure none exists
    const getEmpty = await request(app).get('/api/appinfo');
    expect(getEmpty.status).to.equal(404);

    // Create AppInfo directly via model
    const seed = await AppInfo.create({
      appVersion: '9.9.9',
      buildNumber: '99',
      privacyPolicyUrl: 'https://p',
      termsOfServiceUrl: 'https://t',
      supportEmail: 's@x.com',
      openSourceLicensesUrl: 'https://l'
    });

    const getSeeded = await request(app).get('/api/appinfo');
    expect(getSeeded.status).to.equal(200);
    expect(getSeeded.body.appVersion).to.equal('9.9.9');
  });
});
