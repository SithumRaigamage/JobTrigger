const mongoose = require('mongoose');

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
    subject: { type: String, required: true, maxlength: 120 },
    message: { type: String, required: true, maxlength: 4000 },
    replyEmail: { type: String, required: true, maxlength: 254 },
    // P25-01 diagnostics: the app's version, the tool in use, the platform
    // and the server's scheme+host+port only (never a full URL).
    appVersion: { type: String, maxlength: 40 },
    buildNumber: { type: String, maxlength: 40 },
    tool: { type: String, maxlength: 40 },
    platform: { type: String, maxlength: 40 },
    serverHost: { type: String, maxlength: 200 },
    status: { type: String, enum: STATUSES, default: 'open', index: true },
  },
  { timestamps: true }
);

const SupportTicket = mongoose.model('SupportTicket', supportTicketSchema);

module.exports = SupportTicket;
module.exports.CATEGORIES = CATEGORIES;
module.exports.STATUSES = STATUSES;