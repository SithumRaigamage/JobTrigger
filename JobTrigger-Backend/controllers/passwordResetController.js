/**
 * US-AUTH-08 / P20-73: reset a forgotten password by email.
 *
 * - No account enumeration: `request` answers 202 with the same body for
 *   every well-formed email, and does the lookup and the send *after*
 *   responding, so response time doesn't reveal registered emails either.
 * - Tokens: 32 random bytes, single use, 15 minutes. Only the SHA-256 is
 *   stored; a new request replaces older pending tokens.
 * - `confirm` sets the password, bumps tokenVersion (signs out every
 *   device, AUD-26) and deletes the user's remaining tokens.
 */
const crypto = require('crypto');
const User = require('../models/User');
const PasswordResetToken = require('../models/PasswordResetToken');
const { newPasswordProblem, MAX_EMAIL_LENGTH } = require('./authController');
const { sendMail } = require('../lib/mailer');
const { track } = require('../lib/analytics');
const { resetLinkConfig } = require('../config/env');
const { passwordResetEmail } = require('../emails/passwordReset');
const { logger } = require('../lib/logger');

const TOKEN_MINUTES = 15;
const TOKEN_PATTERN = /^[a-f0-9]{64}$/;
const REQUEST_MESSAGE =
  "If an account exists for that email, we've sent a link to reset its password.";
const INVALID_LINK = 'This reset link is invalid or has expired. Ask for a new one.';

const hashToken = (token) => crypto.createHash('sha256').update(token).digest('hex');

// Work started after a response. Tests wait for it with whenIdle().
const inFlight = new Set();

/** Resolves once every reset email started so far has been handled. */
async function whenIdle() {
  while (inFlight.size > 0) await Promise.allSettled([...inFlight]);
}

function linksFor(token) {
  const { webUrl, appUrl } = resetLinkConfig();
  const query = `token=${token}`;
  return {
    webUrl: webUrl ? `${webUrl}?${query}` : null,
    appUrl: `${appUrl}?${query}`,
  };
}

/** The lookup, token and email for [email]. Never throws. */
async function processRequest(email, requestId) {
  const log = logger.child({ requestId });
  try {
    const user = await User.findOne({ email });
    if (!user) {
      log.info('password_reset.no_account');
      return;
    }
    const token = crypto.randomBytes(32).toString('hex');
    await PasswordResetToken.deleteMany({ userId: user._id });
    await PasswordResetToken.create({
      userId: user._id,
      tokenHash: hashToken(token),
      expiresAt: new Date(Date.now() + TOKEN_MINUTES * 60 * 1000),
    });
    const message = passwordResetEmail({ ...linksFor(token), minutes: TOKEN_MINUTES });
    await sendMail({ to: user.email, ...message, kind: 'password_reset' });
    log.info('password_reset.requested');
    track('password_reset_requested');
  } catch (err) {
    log.error('password_reset.request_failed', { error: err.message });
  }
}

exports.request = (req, res) => {
  const { email } = req.body ?? {};
  if (typeof email !== 'string' || !email.trim()) {
    return res.status(400).json({ message: 'Email is required' });
  }
  const normalized = email.trim().toLowerCase();
  res.status(202).json({ message: REQUEST_MESSAGE });
  if (normalized.length > MAX_EMAIL_LENGTH) return;

  const work = processRequest(normalized, req.requestId);
  inFlight.add(work);
  work.finally(() => inFlight.delete(work));
};

exports.confirm = async (req, res, next) => {
  try {
    const { token, newPassword } = req.body ?? {};
    if (typeof newPassword !== 'string') {
      return res.status(400).json({ message: 'New password is required' });
    }
    if (typeof token !== 'string' || !TOKEN_PATTERN.test(token)) {
      return res.status(400).json({ message: INVALID_LINK });
    }
    // Before spending the token: a weak password lets the user try again.
    const problem = newPasswordProblem(newPassword);
    if (problem) return res.status(400).json({ message: problem });

    // Atomic: two requests with the same token can't both succeed.
    const record = await PasswordResetToken.findOneAndUpdate(
      { tokenHash: hashToken(token), usedAt: null, expiresAt: { $gt: new Date() } },
      { $set: { usedAt: new Date() } },
    );
    if (!record) return res.status(400).json({ message: INVALID_LINK });

    const user = await User.findById(record.userId);
    if (!user) return res.status(400).json({ message: INVALID_LINK });

    user.password = newPassword; // Hashed by the pre-save hook.
    user.tokenVersion = (user.tokenVersion ?? 0) + 1;
    await user.save();
    await PasswordResetToken.deleteMany({ userId: user._id });

    logger.info('password_reset.completed', { requestId: req.requestId });
    track('password_reset_completed');
    res.json({ message: 'Your password has been reset. Sign in with the new password.' });
  } catch (err) {
    next(err);
  }
};

exports.whenIdle = whenIdle;
exports.hashToken = hashToken;
exports.TOKEN_MINUTES = TOKEN_MINUTES;
