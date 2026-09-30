const jwt = require('jsonwebtoken');
const User = require('../models/User');

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

exports.signup = async (req, res) => {
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

    // Create JWT
    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, { expiresIn: '7d' });

    res.status(201).json({ token, user: { _id: user._id, email: user.email } });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

exports.login = async (req, res) => {
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

    // Create JWT
    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, { expiresIn: '7d' });

    res.json({ token, user: { _id: user._id, email: user.email } });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};
