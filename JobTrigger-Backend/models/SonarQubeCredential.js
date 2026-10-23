const mongoose = require('mongoose');
const encryptedFields = require('./plugins/encryptedFields');

const sonarQubeCredentialSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  label: {
    type: String,
    required: true
  },
  baseUrl: {
    type: String, // SonarCloud or a self-hosted SonarQube Server instance
    required: true,
    default: 'https://sonarcloud.io'
  },
  token: {
    type: String, // SonarQube User Token
    required: true
  },
  defaultOrganization: {
    type: String, // required in practice for SonarCloud, meaningless for self-hosted Server
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
sonarQubeCredentialSchema.plugin(encryptedFields, { fields: ['token'] });

// AUD-13: every credential list filters by `userId`, and the "which one is
// the default?" query filters by `userId` + `isDefault`. Without these
// indexes every list is a collection scan, which grows with the number of
// users rather than the number of credentials the caller asked for.
sonarQubeCredentialSchema.index({ userId: 1 });
sonarQubeCredentialSchema.index({ userId: 1, isDefault: 1 });

module.exports = mongoose.model('SonarQubeCredential', sonarQubeCredentialSchema);
