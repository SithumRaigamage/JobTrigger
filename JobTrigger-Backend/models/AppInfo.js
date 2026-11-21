const mongoose = require('mongoose');

const appInfoSchema = new mongoose.Schema({
  appVersion: {
    type: String,
    required: true,
  },
  buildNumber: {
    type: String,
    required: true,
  },
  privacyPolicyUrl: {
    type: String,
    required: true,
  },
  termsOfServiceUrl: {
    type: String,
    required: true,
  },
  supportEmail: {
    type: String,
    required: true,
  },
  openSourceLicensesUrl: {
    type: String,
    required: true,
  },
  // US-PROF-03: the website's changelog, shown as "Release notes".
  releaseNotesUrl: {
    type: String,
    default: null,
  },
  // US-PROF-03: an app older than this must update (e.g. "1.0.1"); null
  // means no app is blocked.
  minSupportedVersion: {
    type: String,
    default: null,
  },
}, {
  timestamps: true
});

module.exports = mongoose.model('AppInfo', appInfoSchema);
