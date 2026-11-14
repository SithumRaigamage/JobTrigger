const SonarQubeCredential = require('../models/SonarQubeCredential');
const { makeCredentialController } = require('./credentialControllerFactory');

// The user's SonarQube credentials (AUD-31: shared implementation).
const controller = makeCredentialController(SonarQubeCredential, ['label', 'baseUrl', 'token', 'defaultOrganization'], { tool: 'sonarqube', secrets: ['token'] });

module.exports = {
  getCredentials: controller.list,
  addCredential: controller.create,
  updateCredential: controller.update,
  deleteCredential: controller.remove,
  setActiveCredential: controller.setDefault,
  getSecret: controller.secret,
};
