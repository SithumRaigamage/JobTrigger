const { expect } = require('chai');
const {
  looksLikeProduction,
  mongoHosts,
  remoteDatabaseProblem,
} = require('../scripts/localOnly');

// AUD-58: the seed script must never touch a shared database by accident.
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

  it('allows this machine', function() {
    for (const uri of [
      'mongodb://localhost:27017',
      'mongodb://127.0.0.1:27017/jobtrigger',
      'mongodb://[::1]:27017',
    ]) {
      expect(check(uri), uri).to.equal(null);
    }
  });

  it('no longer treats the removed docker-compose service as local (P17-04)', function() {
    expect(check('mongodb://mongo:27017')).to.match(/non-local database \(mongo\)/);
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

  describe('a URI that names production (P17-04)', function() {
    const devAtlas =
      'mongodb+srv://jobtrigger-dev-app:pw@jobtrigger-dev.abc.mongodb.net/jobtrigger?appName=jobtrigger-dev';

    it('allows the Atlas dev cluster when forced, as setup-dev.sh does', function() {
      expect(check(devAtlas, { argv: ['--allow-remote'] })).to.equal(null);
    });

    it('refuses "prod" in the user, cluster, database or appName, even forced', function() {
      for (const uri of [
        'mongodb+srv://jobtrigger-prod-app:pw@cluster.abc.mongodb.net/jobtrigger',
        'mongodb+srv://app:pw@jobtrigger-prod.abc.mongodb.net/jobtrigger',
        'mongodb+srv://app:pw@cluster.abc.mongodb.net/jobtrigger_production',
        'mongodb+srv://app:pw@cluster.abc.mongodb.net/jobtrigger?appName=Prod',
      ]) {
        expect(check(uri, { argv: ['--allow-remote'] }), uri).to.match(/names production/);
      }
    });

    it('ignores the password, and never repeats it', function() {
      const uri = 'mongodb+srv://app:Reproduce9@jobtrigger-dev.abc.mongodb.net/';
      expect(looksLikeProduction(uri)).to.equal(false);
      const prodUri = 'mongodb+srv://app:S3cret@jobtrigger-prod.abc.mongodb.net/';
      expect(check(prodUri, { argv: ['--allow-remote'] })).to.not.include('S3cret');
    });
  });

  it('refuses a missing URI', function() {
    expect(check(undefined)).to.match(/missing/);
  });
});
