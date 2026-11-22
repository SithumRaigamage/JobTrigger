const JenkinsCredential = require('./JenkinsCredential');
const GitHubCredential = require('./GitHubCredential');
const SonarQubeCredential = require('./SonarQubeCredential');

/**
 * The credential models, the tool each belongs to (P20-12: plan limits
 * count per tool) and the fields that hold a secret. One list, so
 * the backfill script (scripts/encrypt-credentials.js) and the startup
 * key-id audit (security/keyIdAudit.js) can't drift apart and leave a
 * collection unencrypted.
 */
module.exports = [
  { tool: 'jenkins', Model: JenkinsCredential, fields: ['password', 'paramToken', 'jenkinsURL', 'username'] },
  { tool: 'github', Model: GitHubCredential, fields: ['token'] },
  { tool: 'sonarqube', Model: SonarQubeCredential, fields: ['token', 'baseUrl'] },
];
