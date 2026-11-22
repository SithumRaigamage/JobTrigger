const mongoose = require('mongoose');
const encryptedFields = require('./plugins/encryptedFields');

// Phase 25 (P25-01): one support/feedback report. Content is already
// scrubbed by the controller before it gets here (`lib/errorReporting/
// scrub.js`), so no credential shape is ever stored.
const CATEGORIES = ['bug', 'feature', 'question', 'tool_request'];
const STATUSES = ['open', 'triaged', 'closed'];

const supportTicketSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    category: { type: String, enum: CATEGORIES, required: true },
    // NFR-SEC-08: subject, message, replyEmail and serverHost are
    // encrypted at rest; their length limits are checked by the plugin.
    subject: { type: String, required: true },
    message: { type: String, required: true },
    replyEmail: { type: String, required: true },
    // P25-01 diagnostics: the app's version, the tool in use, the platform
    // and the server's scheme+host+port only (never a full URL).
    appVersion: { type: String, maxlength: 40 },
    buildNumber: { type: String, maxlength: 40 },
    tool: { type: String, maxlength: 40 },
    platform: { type: String, maxlength: 40 },
    serverHost: { type: String },
    status: { type: String, enum: STATUSES, default: 'open', index: true },
  },
  { timestamps: true }
);

supportTicketSchema.plugin(encryptedFields, {
  fields: [
    { path: 'subject', maxLength: 120 },
    { path: 'message', maxLength: 4000 },
    { path: 'replyEmail', maxLength: 254 },
    { path: 'serverHost', maxLength: 200 },
  ],
  flagUnreadable: false,
  logEvent: 'pii.decrypt_failed',
});

const SupportTicket = mongoose.model('SupportTicket', supportTicketSchema);

module.exports = SupportTicket;
module.exports.CATEGORIES = CATEGORIES;
module.exports.STATUSES = STATUSES;