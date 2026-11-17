const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { registerDevice, unregisterDevice } = require('../controllers/deviceController');

// NR-06 (BACKLOG-02): the app's push-token registration.
router.post('/', auth, registerDevice);
router.delete('/:token', auth, unregisterDevice);

module.exports = router;
