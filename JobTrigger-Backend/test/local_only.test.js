const { expect } = require('chai');
const { mongoHosts, remoteDatabaseProblem } = require('../scripts/localOnly');

// AUD-58: the seed and cleanup scripts must never touch a shared database
// by accident.
describe('Development scripts stay local (AUD-58)', function() {
  const check = (uri, { env = {}, argv = [] } = {}) =>
    remoteDatabaseProblem(uri, { env, argv });

  it('reads the hosts out of a MongoDB URI', function() {
    expect(mongoHosts('mongodb://u:p@a.example:27017,b.example/db?x=1'))
      .to.deep.equal(['a.example', 'b.example']);
    expect(mongoHosts('mongodb+srv://cluster0.abc.mongodb.net/')).to.deep.equal([
      'cluster0.abc.mongodb.net',
    ]);
    expect(mongoHosts('mongodb://[::1]:27017')).to.deep.equal(['[::1]']);
  });

  it('allows this machine and the docker-compose service', function() {
    for (const uri of [
      'mongodb://localhost:27017',
      'mongodb://127.0.0.1:27017/jobtrigger',
      'mongodb://mongo:27017',
      'mongodb://[::1]:27017',
    ]) {
      expect(check(uri), uri).to.equal(null);
    }
  });

  it('refuses a remote database unless explicitly forced', function() {
    const atlas = 'mongodb+srv://user:secret@cluster0.abc.mongodb.net/';
    expect(check(atlas)).to.match(/non-local database \(cluster0\.abc\.mongodb\.net\)/);
    expect(check(atlas)).to.not.include('secret');
    expect(check(atlas, { argv: ['--allow-remote'] })).to.equal(null);
  });

  it('refuses production outright, even forced', function() {
    expect(check('mongodb://localhost', { env: { NODE_ENV: 'production' } }))
      .to.match(/production/);
    expect(check('mongodb://a.example', {
      env: { NODE_ENV: 'production' }, argv: ['--allow-remote'],
    })).to.match(/production/);
  });

  it('refuses a missing URI', function() {
    expect(check(undefined)).to.match(/missing/);
  });
});
