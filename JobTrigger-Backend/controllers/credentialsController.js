const JenkinsCredential = require('../models/JenkinsCredential');
const { makeCredentialController } = require('./credentialControllerFactory');

// The user's Jenkins servers (AUD-31: shared implementation).
const controller = makeCredentialController(JenkinsCredential, ['serverName', 'jenkinsURL', 'username', 'password', 'paramToken']);

module.exports = {
  getCredentials: controller.list,
  addCredential: controller.create,
  updateCredential: controller.update,
  deleteCredential: controller.remove,
  setActiveServer: controller.setDefault,
};
