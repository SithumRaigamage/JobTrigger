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
  }
}, {
  timestamps: true
});

module.exports = mongoose.model('AppInfo', appInfoSchema);
