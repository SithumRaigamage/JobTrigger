const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const studentController = require('../controllers/studentController');
const { studentEmailConfirmLimiter, studentEmailStartLimiter } = require('../middleware/rateLimit');

// Phase 21 (SP-2). Every route needs a session.
router.get('/', auth, studentController.status);
router.post('/email/start', auth, studentEmailStartLimiter, studentController.emailStart);
router.post('/email/confirm', auth, studentEmailConfirmLimiter, studentController.emailConfirm);

module.exports = router;
