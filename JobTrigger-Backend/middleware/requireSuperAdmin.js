const User = require('../models/User');
const { logger } = require('../lib/logger');

/**
 * Phase 21 (SP-31): after `auth`. The role is read from the database on
 * every request (never from the token), and anyone who isn't a super admin
 * gets the same 404 as a route that doesn't exist, so the admin API isn't
 * advertised to normal accounts.
 */
module.exports = async function requireSuperAdmin(req, res, next) {
  try {
    const user = await User.findById(req.user.id).select('role').lean();
    if (user?.role !== 'superAdmin') {
      logger.warn('admin.denied', { requestId: req.requestId, userId: req.user.id, path: req.logPath ?? req.path });
      return res.status(404).json({ message: 'Not found' });
    }
    next();
  } catch (err) {
    next(err);
  }
};
