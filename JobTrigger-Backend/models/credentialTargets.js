const JenkinsCredential = require('./JenkinsCredential');
const GitHubCredential = require('./GitHubCredential');
const SonarQubeCredential = require('./SonarQubeCredential');

/**
 * The credential models and the fields that hold a secret. One list, so
 * the backfill script (scripts/encrypt-credentials.js) and the startup
 * key-id audit (security/keyIdAudit.js) can't drift apart and leave a
 * collection unencrypted.
 */
module.exports = [
  { Model: JenkinsCredential, fields: ['password', 'paramToken'] },
  { Model: GitHubCredential, fields: ['token'] },
  { Model: SonarQubeCredential, fields: ['token'] },
];
