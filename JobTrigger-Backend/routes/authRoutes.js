const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const auth = require('../middleware/auth');
const { loginLimiter, refreshLimiter, signupLimiter } = require('../middleware/rateLimit');

router.post('/signup', signupLimiter, authController.signup);
router.post('/login', loginLimiter, authController.login);
router.post('/refresh', refreshLimiter, authController.refresh);
router.post('/logout-all', auth, authController.logoutAll);
// AUD-48. Both re-check the current password, and wrong guesses share the
// login limiter's failure budget.
router.post('/password', auth, loginLimiter, authController.changePassword);
router.delete('/account', auth, loginLimiter, authController.deleteAccount);

module.exports = router;
