const mongoose = require('mongoose');

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


module.exports = mongoose.model('SonarQubeCredential', sonarQubeCredentialSchema);
