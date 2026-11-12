const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const billingWebhookController = require('../controllers/billingWebhookController');
const paddleController = require('../controllers/paddleController');
const { billingWebhookLimiter, subscriptionRefreshLimiter } = require('../middleware/rateLimit');

// P20-16: RevenueCat's webhook. No JWT: it authenticates with the shared
// Authorization value (REVENUECAT_WEBHOOK_AUTH), checked in the controller.
router.post('/revenuecat', billingWebhookLimiter, billingWebhookController.revenuecat);

// Website checkout (Paddle). The webhook's body arrives raw (server.js) so
// the signature can be checked against the exact bytes Paddle sent.
router.post('/paddle/webhook', billingWebhookLimiter, paddleController.webhook);
router.post('/paddle/checkout', auth, subscriptionRefreshLimiter, paddleController.checkout);
router.post('/paddle/portal', auth, subscriptionRefreshLimiter, paddleController.portal);

module.exports = router;
