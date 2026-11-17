const mongoose = require('mongoose');
const encryptedFields = require('./plugins/encryptedFields');

const githubCredentialSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  label: {
    type: String,
    required: true
  },
  token: {
    type: String, // GitHub Personal Access Token
    required: true
  },
  defaultOwner: {
    type: String, // optional org/user filter for the repo list
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
githubCredentialSchema.plugin(encryptedFields, { fields: ['token'] });

// AUD-13: every credential list filters by `userId`, and the "which one is
// the default?" query filters by `userId` + `isDefault`. Without these
// indexes every list is a collection scan, which grows with the number of
// users rather than the number of credentials the caller asked for.
githubCredentialSchema.index({ userId: 1 });
githubCredentialSchema.index({ userId: 1, isDefault: 1 });

module.exports = mongoose.model('GitHubCredential', githubCredentialSchema);
