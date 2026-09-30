const { api } = require('./support/api');
const { expect } = require('chai');
const mongoose = require('mongoose');

describe('Health check (AUD-17)', function() {
  it('is 200 while MongoDB is connected', async function() {
    const res = await api().get('/healthz');
    expect(res.status).to.equal(200);
    expect(res.body).to.deep.equal({ status: 'ok' });
  });

  it('is 503 while MongoDB is not connected', async function() {
    const original = Object.getOwnPropertyDescriptor(
      mongoose.connection,
      'readyState',
    );
    // 0 = disconnected. Stubbed rather than disconnecting the shared
    // in-memory server the other suites use.
    Object.defineProperty(mongoose.connection, 'readyState', {
      configurable: true,
      get: () => 0,
    });
    try {
      const res = await api().get('/healthz');
      expect(res.status).to.equal(503);
      expect(res.body).to.deep.equal({ status: 'unavailable' });
    } finally {
      if (original) {
        Object.defineProperty(mongoose.connection, 'readyState', original);
      } else {
        delete mongoose.connection.readyState;
      }
    }
  });
});
