const express = require('express');
const router = express.Router();
const billingWebhookController = require('../controllers/billingWebhookController');
const { billingWebhookLimiter } = require('../middleware/rateLimit');

// P20-16: RevenueCat's webhook. No JWT: it authenticates with the shared
// Authorization value (REVENUECAT_WEBHOOK_AUTH), checked in the controller.
router.post('/revenuecat', billingWebhookLimiter, billingWebhookController.revenuecat);

module.exports = router;
