/**
 * AUD-58: guards the development script that writes fixed data
 * (setup-migrations.js seeds an account whose password is in the README).
 * It runs against a MongoDB on this machine, or a remote one only with
 * --allow-remote, which setup-dev.sh passes for the Atlas dev cluster
 * (Phase 17). Never under NODE_ENV=production, and never against a URI
 * that names production, even forced.
 */
const LOCAL_HOSTS = new Set(['localhost', '127.0.0.1', '::1', '[::1]']);

/**
 * True when [uri] names production: "prod" in its user, hosts, database or
 * options (e.g. a `jobtrigger-prod` cluster or appName). The password is
 * removed first: it is never inspected, and could hold "prod" by chance.
 */
function looksLikeProduction(uri) {
  const withoutPassword = String(uri ?? '').replace(/^([a-z+]+:\/\/[^:@/]*):[^@]*@/i, '$1@');
  return /prod/i.test(withoutPassword);
}

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
  if (looksLikeProduction(uri)) {
    return 'Refusing to seed a database whose URI names production ("prod" ' +
      'in its user, cluster, database or appName). Seed only the dev cluster.';
  }
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

module.exports = {
  looksLikeProduction,
  mongoHosts,
  remoteDatabaseProblem,
  requireLocalDatabase,
};
