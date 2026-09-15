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
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
});

// Update the updatedAt field before saving
sonarQubeCredentialSchema.pre('save', function() {
  this.updatedAt = Date.now();
});

module.exports = mongoose.model('SonarQubeCredential', sonarQubeCredentialSchema);
