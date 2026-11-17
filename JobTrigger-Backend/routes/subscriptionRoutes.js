const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const subscriptionController = require('../controllers/subscriptionController');
const { subscriptionRefreshLimiter } = require('../middleware/rateLimit');

// P20-13/14 (US-SUB-01..05). Every route needs a session.
router.get('/', auth, subscriptionController.get);
router.post('/refresh', auth, subscriptionRefreshLimiter, subscriptionController.refresh);
router.post('/primary/:credentialId', auth, subscriptionController.setPrimary);

module.exports = router;
