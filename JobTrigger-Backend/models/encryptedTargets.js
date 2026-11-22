const CREDENTIAL_TARGETS = require('./credentialTargets');
const User = require('./User');
const StudentVerification = require('./StudentVerification');
const SupportTicket = require('./SupportTicket');
const Team = require('./Team');

/**
 * NFR-SEC-08: every encrypted field in the database, so the backfill
 * (scripts/encrypt-credentials.js) and the startup key-id audit
 * (security/keyIdAudit.js) cover personal data as well as tool secrets.
 * `hashes` maps an encrypted field to its lookup hash field. A field may
 * reach into a subdocument array (`invites.email`). Keep this in step with
 * the `encryptedFields` plugin options on each model.
 */
module.exports = [
  ...CREDENTIAL_TARGETS.map(({ Model, fields }) => ({ Model, fields })),
  { Model: User, fields: ['email'], hashes: { email: 'emailHash' } },
  {
    Model: StudentVerification,
    fields: ['fullName', 'universityEmail'],
    hashes: { universityEmail: 'universityEmailHash' },
  },
  { Model: SupportTicket, fields: ['subject', 'message', 'replyEmail', 'serverHost'] },
  { Model: Team, fields: ['invites.email'] },
];
