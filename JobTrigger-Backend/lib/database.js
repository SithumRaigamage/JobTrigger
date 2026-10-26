/**
 * P17-03: the one way the server and its scripts connect to MongoDB
 * (Atlas since Phase 17). Same database name everywhere, a short server
 * selection timeout, and a plain-language hint when the connection fails.
 *
 * Never log the URI: it carries the database password.
 */
const mongoose = require('mongoose');

const DB_NAME = 'jobtrigger';

const CONNECT_OPTIONS = Object.freeze({
  dbName: DB_NAME,
  // The driver's default is 30 s. An Atlas cluster that refuses this
  // machine's IP never answers, so fail in 10 s with a hint instead.
  serverSelectionTimeoutMS: 10_000,
});

/** Connects the shared mongoose connection to [uri]. */
function connectDatabase(uri = process.env.MONGODB_URI) {
  return mongoose.connect(uri, CONNECT_OPTIONS);
}

const SETUP_GUIDE = 'docs/mongodb-cloud-setup.md';

/**
 * What to check for a failed connection [err], or null when the cause
 * isn't one we recognise. Checked most specific first: a DNS failure and a
 * refused IP both surface as server-selection errors.
 */
function connectionHint(err) {
  const message = String(err?.message ?? '');
  const code = err?.code;

  if (code === 18 || /bad auth|authentication failed/i.test(message)) {
    return 'The database user or password was rejected: match MONGODB_URI ' +
      `to the user under Atlas Database Access (${SETUP_GUIDE}, step 2).`;
  }
  if (code === 13 || /not authorized/i.test(message)) {
    return `The database user lacks readWrite on "${DB_NAME}" (${SETUP_GUIDE}, step 2).`;
  }
  if (/querySrv|ENOTFOUND|EAI_AGAIN/i.test(message)) {
    return 'The cluster address did not resolve: check the host in ' +
      'MONGODB_URI, or try another network or DNS server.';
  }
  if (
    err?.name === 'MongoServerSelectionError' ||
    /server selection timed out|ReplicaSetNoPrimary|ECONNREFUSED/i.test(message)
  ) {
    return 'The cluster did not answer: add this machine\'s IP under Atlas ' +
      `Network Access (${SETUP_GUIDE}, step 3), or resume a paused cluster.`;
  }
  return null;
}

module.exports = { DB_NAME, CONNECT_OPTIONS, connectDatabase, connectionHint };
