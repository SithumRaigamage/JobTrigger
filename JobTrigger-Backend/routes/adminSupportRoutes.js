const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const requireSuperAdmin = require('../middleware/requireSuperAdmin');
const supportController = require('../controllers/supportController');
const { adminLimiter } = require('../middleware/rateLimit');

// Phase 25 (P25-03): triage, for the owner only. A normal account gets the
// same 404 as a route that does not exist (`requireSuperAdmin`).
router.get('/tickets', auth, requireSuperAdmin, adminLimiter, supportController.listAllTickets);
router.get('/tickets/:id/screenshots/:index', auth, requireSuperAdmin, adminLimiter, supportController.getScreenshot);
router.get('/tickets/:id', auth, requireSuperAdmin, adminLimiter, supportController.getTicket);
router.patch('/tickets/:id', auth, requireSuperAdmin, adminLimiter, supportController.updateTicketStatus);

module.exports = router;