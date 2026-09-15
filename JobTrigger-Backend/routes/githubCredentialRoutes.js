const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const githubCredentialsController = require('../controllers/githubCredentialsController');

router.get('/', auth, githubCredentialsController.getCredentials);
router.post('/', auth, githubCredentialsController.addCredential);
router.put('/:id', auth, githubCredentialsController.updateCredential);
router.delete('/:id', auth, githubCredentialsController.deleteCredential);
// Switch active GitHub credential for the user
router.post('/switch/:id', auth, githubCredentialsController.setActiveCredential);

module.exports = router;
