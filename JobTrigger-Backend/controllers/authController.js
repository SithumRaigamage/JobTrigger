const User = require('../models/User');
const { issueTokens, verifyToken, isCurrent } = require('../security/tokens');

// AUD-26: kept in step with the client's AuthValidation
// (JobTrigger-Frontend/lib/domain/auth/auth_validation.dart).
const MIN_PASSWORD_LENGTH = 8;
// bcrypt ignores everything past 72 bytes; refuse rather than silently
// truncate a new password.
const MAX_PASSWORD_BYTES = 72;
const MAX_EMAIL_LENGTH = 254;
const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

/**
 * AUD-04: `email` and `password` must be non-empty strings. Anything else
 * (an object such as `{"$gt": ""}`, a number, an array) is a 400 before it
 * can reach a query. Returns the trimmed, lower-cased email, or null after
 * sending the 400.
 */
function readCredentials(req, res) {
  const { email, password } = req.body ?? {};
  if (typeof email !== 'string' || typeof password !== 'string' ||
      !email.trim() || !password) {
    res.status(400).json({ message: 'Email and password are required' });
    return null;
  }
  return { email: email.trim().toLowerCase(), password };
}

exports.signup = async (req, res, next) => {
  try {
    const credentials = readCredentials(req, res);
    if (!credentials) return;
    const { email, password } = credentials;

    if (email.length > MAX_EMAIL_LENGTH || !EMAIL_PATTERN.test(email)) {
      return res.status(400).json({ message: 'Enter a valid email address' });
    }
    if (password.length < MIN_PASSWORD_LENGTH) {
      return res.status(400).json({
        message: `Password must be at least ${MIN_PASSWORD_LENGTH} characters long`,
      });
    }
    if (Buffer.byteLength(password, 'utf8') > MAX_PASSWORD_BYTES) {
      return res.status(400).json({ message: 'Password is too long' });
    }

    // Check if user exists
    let user = await User.findOne({ email });
    if (user) {
      return res.status(400).json({ message: 'User already exists' });
    }

    user = new User({ email, password });
    await user.save();

    // A 15-minute access token and a refresh token (AUD-26).
    res.status(201).json({ ...issueTokens(user), user: { _id: user._id, email: user.email } });
  } catch (err) {
    next(err);
  }
};

exports.login = async (req, res, next) => {
  try {
    // Type checks only: accounts created under older rules must still be
    // able to sign in.
    const credentials = readCredentials(req, res);
    if (!credentials) return;
    const { email, password } = credentials;

    // Find user
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    // Check password
    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    // A 15-minute access token and a refresh token (AUD-26).
    res.json({ ...issueTokens(user), user: { _id: user._id, email: user.email } });
  } catch (err) {
    next(err);
  }
};

/**
 * AUD-26: trades a refresh token for a new pair. The old refresh token
 * keeps working until it expires (they aren't stored), but the pair it
 * returns carries the current tokenVersion, and a logout-everywhere
 * revokes both.
 */
exports.refresh = async (req, res, next) => {
  try {
    const payload = verifyToken(req.body?.refreshToken, 'refresh');
    const user = payload && (await User.findById(payload.id));
    if (!user || !isCurrent(payload, user)) {
      return res.status(401).json({ message: 'Session expired' });
    }
    res.json({ ...issueTokens(user), user: { _id: user._id, email: user.email } });
  } catch (err) {
    next(err);
  }
};

/** AUD-26: revokes every access and refresh token the user holds. */
exports.logoutAll = async (req, res, next) => {
  try {
    await User.updateOne({ _id: req.user.id }, { $inc: { tokenVersion: 1 } });
    res.json({ message: 'Signed out everywhere' });
  } catch (err) {
    next(err);
  }
};
