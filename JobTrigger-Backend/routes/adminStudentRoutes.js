const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const requireSuperAdmin = require('../middleware/requireSuperAdmin');
const { adminLimiter } = require('../middleware/rateLimit');
const admin = require('../controllers/adminStudentController');

// Phase 21 (SP-31). Session, then the rate limit, then the role (server-side,
// from the database): anyone else gets the same 404 as an unknown route.
router.use(auth, adminLimiter, requireSuperAdmin);

router.get('/', admin.list);
router.get('/:id', admin.get);
router.get('/:id/document', admin.document);
router.post('/:id/approve', admin.approve);
router.post('/:id/reject', admin.reject);

module.exports = router;
