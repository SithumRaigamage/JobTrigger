const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { loginLimiter, signupLimiter } = require('../middleware/rateLimit');

router.post('/signup', signupLimiter, authController.signup);
router.post('/login', loginLimiter, authController.login);

module.exports = router;
