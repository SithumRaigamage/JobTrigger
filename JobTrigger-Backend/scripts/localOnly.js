/**
 * AUD-58: guards the development scripts that write fixed data or drop
 * databases (setup-migrations.js seeds an account whose password is in the
 * README; cleanup-test-database.js drops the "test" database). They only
 * run against a MongoDB on this machine or the docker-compose service,
 * never under NODE_ENV=production, unless --allow-remote is passed for a
 * deliberate, non-production remote run.
 */
const LOCAL_HOSTS = new Set(['localhost', '127.0.0.1', '::1', '[::1]', 'mongo']);

/** The hosts named in a mongodb:// or mongodb+srv:// URI. */
function mongoHosts(uri) {
  const match = /^mongodb(?:\+srv)?:\/\/(?:[^@/]*@)?([^/?]+)/.exec(uri ?? '');
  if (!match) return [];
  return match[1].split(',').map((host) =>
    host.startsWith('[') ? host.slice(0, host.indexOf(']') + 1) : host.split(':')[0],
  );
}

/** Why this run must not touch [uri], or null when it may. */
function remoteDatabaseProblem(uri, { env = process.env, argv = process.argv } = {}) {
  if (env.NODE_ENV === 'production') {
    return 'Refusing to run with NODE_ENV=production.';
  }
  const hosts = mongoHosts(uri);
  if (hosts.length === 0) return 'MONGODB_URI is missing or not a MongoDB URI.';
  const remote = hosts.filter((host) => !LOCAL_HOSTS.has(host.toLowerCase()));
  if (remote.length > 0 && !argv.includes('--allow-remote')) {
    return `Refusing to write to a non-local database (${remote.join(', ')}). ` +
      'This script is for local development; pass --allow-remote only for a ' +
      'deliberate, non-production run.';
  }
  return null;
}

/** Exits the process with the problem, if there is one. */
function requireLocalDatabase(uri) {
  const problem = remoteDatabaseProblem(uri);
  if (problem) {
    console.error(problem);
    process.exit(1);
  }
}

module.exports = { mongoHosts, remoteDatabaseProblem, requireLocalDatabase };
