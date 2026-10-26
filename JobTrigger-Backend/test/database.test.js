const { expect } = require('chai');
const mongoose = require('mongoose');

const { CONNECT_OPTIONS, DB_NAME, connectionHint } = require('../lib/database');

/** A driver-shaped error. */
function driverError(message, { name = 'MongoError', code } = {}) {
  const err = new Error(message);
  err.name = name;
  if (code !== undefined) err.code = code;
  return err;
}

describe('Database connection (P17-03)', function() {
  describe('options', function() {
    it('always selects the jobtrigger database', function() {
      expect(DB_NAME).to.equal('jobtrigger');
      expect(CONNECT_OPTIONS.dbName).to.equal(DB_NAME);
    });

    it('gives up on an unreachable cluster in 10 s, not the driver\'s 30 s', function() {
      expect(CONNECT_OPTIONS.serverSelectionTimeoutMS).to.equal(10_000);
    });

    it('is the connection the server is using', function() {
      // test/setup.js starts the server, which connects through
      // connectDatabase(); the shared connection carries its options.
      expect(mongoose.connection.name).to.equal(DB_NAME);
    });
  });

  describe('connectionHint', function() {
    it('points a rejected login at the Atlas database user', function() {
      for (const err of [
        driverError('bad auth : Authentication failed.', { name: 'MongoServerError', code: 8000 }),
        driverError('Authentication failed.', { name: 'MongoServerError', code: 18 }),
      ]) {
        expect(connectionHint(err)).to.match(/user or password was rejected/);
      }
    });

    it('points a missing privilege at the readWrite role', function() {
      const err = driverError('not authorized on jobtrigger to execute command', {
        name: 'MongoServerError',
        code: 13,
      });
      expect(connectionHint(err)).to.match(/readWrite on "jobtrigger"/);
    });

    it('treats an SRV lookup failure as DNS, not as a refused IP', function() {
      const err = driverError('querySrv ENOTFOUND _mongodb._tcp.nope.mongodb.net', {
        name: 'MongoServerSelectionError',
      });
      expect(connectionHint(err)).to.match(/did not resolve/);
    });

    it('points a server-selection timeout at the IP allow list', function() {
      for (const err of [
        driverError('Server selection timed out after 10000 ms', { name: 'MongoServerSelectionError' }),
        driverError('connect ECONNREFUSED 127.0.0.1:27017'),
      ]) {
        expect(connectionHint(err)).to.match(/Network Access/);
      }
    });

    it('returns null for an error it does not recognise', function() {
      expect(connectionHint(new Error('something else'))).to.equal(null);
      expect(connectionHint(undefined)).to.equal(null);
    });

    it('never repeats the connection string it was given', function() {
      const uri = 'mongodb+srv://app:S3cretPassw0rd@cluster.example.mongodb.net/jobtrigger';
      const err = driverError(`bad auth for ${uri}`, { code: 18 });
      expect(connectionHint(err)).to.not.include('S3cretPassw0rd');
    });
  });
});
