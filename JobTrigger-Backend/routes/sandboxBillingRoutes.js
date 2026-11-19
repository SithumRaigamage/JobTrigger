const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const sandboxOnly = require('../middleware/sandboxOnly');
const { adminLimiter } = require('../middleware/rateLimit');
const sandbox = require('../controllers/sandboxBillingController');

// Development only (sandboxOnly answers 404 everywhere else). A signed-in
// account can run the store flow without Apple, Google or RevenueCat.
// Generous: a tester runs buy → cancel → expire → resubscribe repeatedly.
router.use(sandboxOnly, auth, adminLimiter);

router.post('/purchase', sandbox.purchase);
router.post('/cancel', sandbox.cancel);
router.post('/resubscribe', sandbox.resubscribe);
router.post('/expire', sandbox.expire);

module.exports = router;
