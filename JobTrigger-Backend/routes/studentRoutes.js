const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const studentController = require('../controllers/studentController');
const { studentDocumentLimiter, studentEmailConfirmLimiter, studentEmailStartLimiter } = require('../middleware/rateLimit');

// Phase 21 (SP-2). Every route needs a session.
router.get('/', auth, studentController.status);
router.post('/email/start', auth, studentEmailStartLimiter, studentController.emailStart);
router.post('/email/confirm', auth, studentEmailConfirmLimiter, studentController.emailConfirm);
router.post('/document', auth, studentDocumentLimiter, studentController.documentUpload);

module.exports = router;
