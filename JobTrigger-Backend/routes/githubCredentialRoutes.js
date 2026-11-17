const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { credentialSecretLimiter } = require('../middleware/rateLimit');
const githubCredentialsController = require('../controllers/githubCredentialsController');

router.get('/', auth, githubCredentialsController.getCredentials);
router.post('/', auth, githubCredentialsController.addCredential);
router.put('/:id', auth, githubCredentialsController.updateCredential);
router.delete('/:id', auth, githubCredentialsController.deleteCredential);
// Switch active GitHub credential for the user
router.post('/switch/:id', auth, githubCredentialsController.setActiveCredential);

// E4 (PE-32): the only response with a decrypted secret.
router.get('/:id/secret', auth, credentialSecretLimiter, githubCredentialsController.getSecret);

module.exports = router;
