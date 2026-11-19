const { sandboxBillingEnabled } = require('../config/env');

/**
 * Keeps the sandbox billing routes out of every deployment that is not an
 * explicit development run: a production build, or any build without
 * SANDBOX_BILLING=true, gets the same plain 404 as an unknown route.
 */
module.exports = (req, res, next) => {
  if (!sandboxBillingEnabled()) return res.status(404).json({ message: 'Not found' });
  next();
};
