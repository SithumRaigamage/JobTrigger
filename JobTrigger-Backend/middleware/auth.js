const User = require('../models/User');
const { verifyToken, isCurrent } = require('../security/tokens');
const { logger } = require('../lib/logger');

module.exports = async (req, res, next) => {
  // §19: every authentication attempt leaves a line, so a client that
  // suddenly gets 401s can be traced. Never the token itself, nor any
  // part of it.
  const log = logger.child({ requestId: req.requestId });

  // Get token from header
  const token = req.header('x-auth-token');

  // Check if no token
  if (!token) {
    log.warn('auth.no_token');
    return res.status(401).json({ message: 'No token, authorization denied' });
  }

  // An access token only: a refresh token is refused here (AUD-26).
  const decoded = verifyToken(token, 'access');
  if (!decoded) {
    log.warn('auth.invalid_token');
    return res.status(401).json({ message: 'Token is not valid' });
  }

  // A token stays valid until it expires even if the user it names has
  // since been deleted, or has signed out everywhere since it was issued
  // (tokenVersion, AUD-26) -- confirm both rather than trusting the payload.
  const user = await User.findById(decoded.id);
  if (!user || !isCurrent(decoded, user)) {
    log.warn('auth.token_not_current');
    return res.status(401).json({ message: 'Token is not valid' });
  }

  req.user = { id: decoded.id };
  log.info('auth.ok', { userId: decoded.id });
  next();
};
