const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const credentialsController = require('../controllers/credentialsController');

router.get('/', auth, credentialsController.getCredentials);
router.post('/', auth, credentialsController.addCredential);
router.put('/:id', auth, credentialsController.updateCredential);
router.delete('/:id', auth, credentialsController.deleteCredential);
// Switch active Jenkins server for the user
router.post('/switch/:id', auth, credentialsController.setActiveServer);

module.exports = router;
