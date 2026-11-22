const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const subscriptionController = require('../controllers/subscriptionController');
const { subscriptionRefreshLimiter, promoRedeemLimiter } = require('../middleware/rateLimit');

// P20-13/14 (US-SUB-01..05). Every route needs a session.
router.get('/', auth, subscriptionController.get);
router.post('/refresh', auth, subscriptionRefreshLimiter, subscriptionController.refresh);
// US-PROMO-01: a promo or voucher code, in its own `promo` source.
router.post('/promo', auth, promoRedeemLimiter, subscriptionController.redeemPromo);
router.post('/primary/:credentialId', auth, subscriptionController.setPrimary);

module.exports = router;
