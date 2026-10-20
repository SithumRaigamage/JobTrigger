const User = require('../models/User');
const { verifyToken, isCurrent } = require('../security/tokens');

module.exports = async (req, res, next) => {
  // Get token from header
  const token = req.header('x-auth-token');

  // Check if no token
  if (!token) {
    return res.status(401).json({ message: 'No token, authorization denied' });
  }

  // An access token only: a refresh token is refused here (AUD-26).
  const decoded = verifyToken(token, 'access');
  if (!decoded) {
    return res.status(401).json({ message: 'Token is not valid' });
  }

  // A token stays valid until it expires even if the user it names has
  // since been deleted, or has signed out everywhere since it was issued
  // (tokenVersion, AUD-26) -- confirm both rather than trusting the payload.
  const user = await User.findById(decoded.id);
  if (!user || !isCurrent(decoded, user)) {
    return res.status(401).json({ message: 'Token is not valid' });
  }

  req.user = { id: decoded.id };
  next();
};
