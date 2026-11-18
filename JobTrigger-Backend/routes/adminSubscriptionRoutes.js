const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const requireSuperAdmin = require('../middleware/requireSuperAdmin');
const { adminLimiter } = require('../middleware/rateLimit');
const admin = require('../controllers/adminSubscriptionController');

// Release 1.0.0, like /api/admin/students: session, then the rate limit,
// then the role (read from the database). Anyone else gets the same plain
// 404 as an unknown route.
router.use(auth, adminLimiter, requireSuperAdmin);

router.get('/', admin.list);
router.post('/:userId/grant', admin.grant);
router.post('/:userId/revoke', admin.revoke);

module.exports = router;
