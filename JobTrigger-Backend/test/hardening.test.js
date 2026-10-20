const request = require('supertest');
const { api } = require('./support/api');
const { expect } = require('chai');
const express = require('express');
const { missingConfig, corsOrigins } = require('../config/env');
const { errorHandler, notFound } = require('../middleware/errorHandler');
const AppInfo = require('../models/AppInfo');

describe('Error handling (AUD-06)', function() {
  it('hides internal error details behind a generic 500', async function() {
    const original = AppInfo.findOne;
    AppInfo.findOne = async () => {
      throw new Error('E11000 duplicate key in collection jobtrigger.appinfos');
    };
    const logged = console.error;
    console.error = () => {}; // Expected server-side log; keep output clean.
    try {
      const res = await api().get('/api/appinfo');
      expect(res.status).to.equal(500);
      expect(res.body).to.deep.equal({ message: 'Server error' });
      expect(JSON.stringify(res.body)).to.not.match(/E11000|appinfos/);
    } finally {
      AppInfo.findOne = original;
      console.error = logged;
    }
  });

  it('answers malformed JSON with a 400', async function() {
    const res = await api()
      .post('/api/auth/login')
      .set('Content-Type', 'application/json')
      .send('{"email": ');
    expect(res.status).to.equal(400);
    expect(res.body).to.deep.equal({ message: 'Malformed JSON body' });
  });

  it('answers unknown routes with a JSON 404', async function() {
    const res = await api().get('/api/nope');
    expect(res.status).to.equal(404);
    expect(res.body).to.deep.equal({ message: 'Not found' });
  });

  it('turns a validation error into a 400 naming only the fields', async function() {
    const probe = express();
    probe.get('/', () => {
      const err = new Error('Credential validation failed: secret: Path `secret` is required.');
      err.name = 'ValidationError';
      err.errors = { secret: {} };
      throw err;
    });
    probe.use(notFound);
    probe.use(errorHandler);
    const res = await request(probe).get('/');
    expect(res.status).to.equal(400);
    expect(res.body).to.deep.equal({ message: 'Invalid data', fields: ['secret'] });
  });
});

describe('Headers, CORS, and config (AUD-25)', function() {
  it('sends security headers', async function() {
    const res = await api().get('/');
    expect(res.headers['x-content-type-options']).to.equal('nosniff');
    expect(res.headers['x-powered-by']).to.be.undefined;
  });

  it('allows no browser origins unless configured', async function() {
    const res = await api().get('/').set('Origin', 'https://evil.example');
    expect(res.headers['access-control-allow-origin']).to.be.undefined;
  });

  it('reads the allow-list from CORS_ORIGINS', function() {
    expect(corsOrigins({})).to.deep.equal([]);
    expect(
      corsOrigins({ CORS_ORIGINS: ' https://a.example , ,https://b.example ' }),
    ).to.deep.equal(['https://a.example', 'https://b.example']);
  });

  it('names missing or blank required config', function() {
    expect(
      missingConfig({ JWT_SECRET: 's', MONGODB_URI: 'm', CREDENTIALS_ENCRYPTION_KEY: 'k' }),
    ).to.deep.equal([]);
    expect(missingConfig({ JWT_SECRET: '  ' })).to.deep.equal([
      'JWT_SECRET',
      'MONGODB_URI',
      'CREDENTIALS_ENCRYPTION_KEY',
    ]);
  });
});
