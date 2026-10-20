const GitHubCredential = require('../models/GitHubCredential');
const { makeCredentialController } = require('./credentialControllerFactory');

// The user's GitHub credentials (AUD-31: shared implementation).
const controller = makeCredentialController(GitHubCredential, ['label', 'token', 'defaultOwner']);

module.exports = {
  getCredentials: controller.list,
  addCredential: controller.create,
  updateCredential: controller.update,
  deleteCredential: controller.remove,
  setActiveCredential: controller.setDefault,
};
