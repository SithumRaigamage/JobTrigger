const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const sonarqubeCredentialsController = require('../controllers/sonarqubeCredentialsController');

router.get('/', auth, sonarqubeCredentialsController.getCredentials);
router.post('/', auth, sonarqubeCredentialsController.addCredential);
router.put('/:id', auth, sonarqubeCredentialsController.updateCredential);
router.delete('/:id', auth, sonarqubeCredentialsController.deleteCredential);
// Switch active SonarQube credential for the user
router.post('/switch/:id', auth, sonarqubeCredentialsController.setActiveCredential);

module.exports = router;
