const mongoose = require('mongoose');

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


module.exports = mongoose.model('GitHubCredential', githubCredentialSchema);
