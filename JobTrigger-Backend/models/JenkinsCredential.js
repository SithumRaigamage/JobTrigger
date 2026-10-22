const mongoose = require('mongoose');
const encryptedFields = require('./plugins/encryptedFields');

const jenkinsCredentialSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  serverName: {
    type: String,
    required: true
  },
  jenkinsURL: {
    type: String,
    required: true
  },
  username: {
    type: String,
    required: true
  },
  password: {
    type: String, // Jenkins password or API token
    required: true
  },
  paramToken: {
    type: String,
    default: ''
  },
  isDefault: {
    type: Boolean,
    default: false
  }
}, {
  // AUD-23: maintained on save *and* on findOneAndUpdate.
  timestamps: true
});

// AUD-03: secrets are encrypted at rest.
jenkinsCredentialSchema.plugin(encryptedFields, { fields: ['password', 'paramToken'] });

// AUD-13: every credential list filters by `userId`, and the "which one is
// the default?" query filters by `userId` + `isDefault`. Without these
// indexes every list is a collection scan, which grows with the number of
// users rather than the number of credentials the caller asked for.
jenkinsCredentialSchema.index({ userId: 1 });
jenkinsCredentialSchema.index({ userId: 1, isDefault: 1 });

module.exports = mongoose.model('JenkinsCredential', jenkinsCredentialSchema);
