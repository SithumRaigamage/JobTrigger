const mongoose = require('mongoose');
const encryptedFields = require('./plugins/encryptedFields');

// Phase 25 (P25-01): one support/feedback report. Content is already
// scrubbed by the controller before it gets here (`lib/errorReporting/
// scrub.js`), so no credential shape is ever stored.
// Phase 31: areas, impact and encrypted screenshots add triage context. The
// image bytes are encrypted with security/secretCipher.js in the controller
// (the encryptedFields plugin only handles strings with fixed AAD names), and
// are `select: false` so a normal read never carries them.
const CATEGORIES = ['bug', 'feature', 'question', 'tool_request', 'account', 'billing', 'other'];
const AREAS = ['jenkins', 'github', 'sonarqube', 'website', 'phone', 'account'];
const IMPACTS = ['blocked', 'major', 'minor'];
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
    // P31-01/P31-02: optional multi-select areas, required-ish impact
    // (defaulted by the controller) and up to three screenshots.
    areas: { type: [String], enum: AREAS, default: [] },
    impact: { type: String, enum: IMPACTS, default: 'minor' },
    screenshots: {
      type: [
        new mongoose.Schema(
          {
            data: { type: String, select: false },
            mime: { type: String, required: true },
            size: { type: Number, required: true },
            hash: { type: String, required: true },
            deleteAt: { type: Date, default: null },
            deletedAt: { type: Date, default: null },
          },
          { timestamps: true }
        ),
      ],
      default: [],
    },
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

supportTicketSchema.index({ 'screenshots.deleteAt': 1 }, { sparse: true });

const SupportTicket = mongoose.model('SupportTicket', supportTicketSchema);

module.exports = SupportTicket;
module.exports.CATEGORIES = CATEGORIES;
module.exports.AREAS = AREAS;
module.exports.IMPACTS = IMPACTS;
module.exports.STATUSES = STATUSES;
