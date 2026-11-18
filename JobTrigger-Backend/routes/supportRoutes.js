const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const supportController = require('../controllers/supportController');
const { supportTicketLimiter } = require('../middleware/rateLimit');

// Phase 25 (P25-02). Every route needs a session.
router.post('/tickets', auth, supportTicketLimiter, supportController.createTicket);
router.get('/tickets', auth, supportController.listMyTickets);

module.exports = router;