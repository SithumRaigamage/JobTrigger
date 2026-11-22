const bcrypt = require('bcrypt');
const User = require('../models/User');
const JenkinsCredential = require('../models/JenkinsCredential');
const GitHubCredential = require('../models/GitHubCredential');
const SonarQubeCredential = require('../models/SonarQubeCredential');
const PasswordResetToken = require('../models/PasswordResetToken');
const { onAccountDeletion, TeamError } = require('../lib/team');
const Subscription = require('../models/Subscription');
const StudentVerification = require('../models/StudentVerification');
const SupportTicket = require('../models/SupportTicket');
const revenueCat = require('../billing/revenuecatClient');
const paddle = require('../billing/paddleClient');
const { activePaidSource } = require('../billing/entitlements');
const { ensureOwnerGrant, isOwnerEmail } = require('../billing/owner');
const { revenueCatConfig, paddleConfig } = require('../config/env');
const { logger } = require('../lib/logger');
const { issueTokens, verifyToken, isCurrent } = require('../security/tokens');

// AUD-26: kept in step with the client's AuthValidation
// (JobTrigger-Frontend/lib/domain/auth/auth_validation.dart).
const MIN_PASSWORD_LENGTH = 8;
// bcrypt ignores everything past 72 bytes; refuse rather than silently
// truncate a new password.
const MAX_PASSWORD_BYTES = 72;
const MAX_EMAIL_LENGTH = 254;
const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

// AUD-55: compared against when the email has no account, so "no such
// account" costs the same bcrypt work as "wrong password" and response
// time doesn't reveal which emails are registered. Same cost as User's
// (NFR-SEC-08 AC7).
const DUMMY_HASH = bcrypt.hashSync('no account has this password', User.BCRYPT_COST);

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

/** Why [password] can't be a new password, or null (signup, change). */
function newPasswordProblem(password) {
  if (password.length < MIN_PASSWORD_LENGTH) {
    return `Password must be at least ${MIN_PASSWORD_LENGTH} characters long`;
  }
  if (Buffer.byteLength(password, 'utf8') > MAX_PASSWORD_BYTES) {
    return 'Password is too long';
  }
  return null;
}

/**
 * Release 1.0.0 (US-SUB-01): the owner's permanent Pro grant. Best effort:
 * a grant failure must never stop the owner signing in, and must never
 * block anyone else (only this one email is affected).
 */
async function applyOwnerGrant(user) {
  if (!isOwnerEmail(user.email)) return;
  try {
    await ensureOwnerGrant(user._id);
  } catch (err) {
    logger.warn('billing.owner_grant_failed', { error: err.message });
  }
}

/**
 * AUD-48: the signed-in user, after re-checking [password] (a stolen
 * access token alone can't delete the account or change its password).
 * Sends the 400/401 and returns null when it doesn't check out. A wrong
 * password is a 400, like login, so the client doesn't read it as an
 * expired session.
 */
async function reauthenticate(req, res, password) {
  if (typeof password !== 'string' || !password) {
    res.status(400).json({ message: 'Current password is required' });
    return null;
  }
  const user = await User.findById(req.user.id);
  if (!user) {
    res.status(401).json({ message: 'Token is not valid' });
    return null;
  }
  if (!(await user.comparePassword(password))) {
    res.status(400).json({ message: 'Current password is incorrect' });
    return null;
  }
  return user;
}

exports.signup = async (req, res, next) => {
  try {
    const credentials = readCredentials(req, res);
    if (!credentials) return;
    const { email, password } = credentials;

    if (email.length > MAX_EMAIL_LENGTH || !EMAIL_PATTERN.test(email)) {
      return res.status(400).json({ message: 'Enter a valid email address' });
    }
    const problem = newPasswordProblem(password);
    if (problem) return res.status(400).json({ message: problem });

    // Check if user exists
    let user = await User.findOne({ email });
    if (user) {
      return res.status(400).json({ message: 'User already exists' });
    }

    user = new User({ email, password });
    await user.save();
    await applyOwnerGrant(user);

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
      await bcrypt.compare(password, DUMMY_HASH); // AUD-55: same work.
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    // Check password
    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }
    // NFR-SEC-08 AC7: a hash made at an older, cheaper cost is replaced
    // now that we hold the right password. Same password, no sign-out.
    if (user.needsRehash()) {
      user.password = password;
      await user.save();
    }
    // Release 1.0.0: an owner account that existed before the grant rule
    // picks up permanent Pro the next time it signs in.
    await applyOwnerGrant(user);

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

/**
 * Re-checks the signed-in user's password and changes nothing: the same
 * `reauthenticate` check Change password and Delete account use (400 when
 * missing or wrong). For clients that guard a sensitive read, such as the
 * website's "show saved token", behind the password.
 */
exports.verifyPassword = async (req, res, next) => {
  try {
    const user = await reauthenticate(req, res, req.body?.password);
    if (!user) return;
    res.json({ message: 'Password confirmed' });
  } catch (err) {
    next(err);
  }
};

/**
 * AUD-48: changes the password and revokes every session (bumping
 * tokenVersion), then hands this device a fresh pair so it stays signed in.
 */
exports.changePassword = async (req, res, next) => {
  try {
    const { currentPassword, newPassword } = req.body ?? {};
    if (typeof newPassword !== 'string') {
      return res.status(400).json({ message: 'New password is required' });
    }
    const problem = newPasswordProblem(newPassword);
    if (problem) return res.status(400).json({ message: problem });

    const user = await reauthenticate(req, res, currentPassword);
    if (!user) return;

    user.password = newPassword; // Hashed by the pre-save hook.
    user.tokenVersion = (user.tokenVersion ?? 0) + 1;
    await user.save();
    res.json({ ...issueTokens(user), user: { _id: user._id, email: user.email } });
  } catch (err) {
    next(err);
  }
};

/**
 * AUD-48 (App Store 5.1.1(v), Google Play data deletion): deletes the
 * account and every tool credential stored for it. Credentials go first,
 * so an interrupted request leaves an account the user can still sign in
 * to and delete again, never orphaned secrets. Student applications go too
 * (documents included); only the one-way hashes in StudentClaim stay, so the
 * same university email or document can't claim a second grant (Phase 21).
 * Support tickets filed by the account go too (Phase 25): a report keeps the
 * reply address and the user's own words, so it isn't kept after the account.
 */
exports.deleteAccount = async (req, res, next) => {
  try {
    const user = await reauthenticate(req, res, req.body?.password);
    if (!user) return;
    // Read before the delete: a web subscription is cancelled below so a
    // deleted account isn't charged again. Store subscriptions can only be
    // cancelled by the user in their store (US-SUB-07).
    const subscription = await Subscription.findOne({ userId: user._id }).lean();

    // changes.md §4: a paid subscription that is still billing blocks
    // deletion — the user must cancel it in its store (or on the website)
    // first. Free accounts, expired/cancelled subscriptions, grants and
    // student years are all deletable. Nothing is removed when we return.
    const blockingSource = activePaidSource(subscription);
    if (blockingSource) {
      const where = blockingSource === 'web'
        ? 'in your account on the JobTrigger website'
        : 'in your App Store or Google Play subscription settings';
      return res.status(403).json({
        code: 'SUBSCRIPTION_ACTIVE',
        message:
          'Cancel your active Pro subscription ' + where +
          ' before deleting your account, so you are not charged after it is gone.',
      });
    }

    // US-SUB-11 AC11: an owner deletes the team first; a member's
    // membership goes with the account. Checked whether or not the team plan
    // is on now, since team data may exist from when it was.
    try {
      await onAccountDeletion(user._id);
    } catch (err) {
      if (err instanceof TeamError) return res.status(err.status).json({ code: err.code, message: err.message });
      throw err;
    }

    await Promise.all(
      [JenkinsCredential, GitHubCredential, SonarQubeCredential, PasswordResetToken, Subscription, StudentVerification, SupportTicket].map((Model) =>
        Model.deleteMany({ userId: user._id }),
      ),
    );
    await User.deleteOne({ _id: user._id });
    // P20-18: RevenueCat's copy of the customer goes too. Best effort: the
    // account is already gone, so a RevenueCat outage is logged, not
    // surfaced. Deleting doesn't cancel a store subscription (US-SUB-07).
    if (revenueCatConfig()) {
      revenueCat.deleteSubscriber(String(user._id)).catch((err) => {
        logger.warn('billing.delete_subscriber_failed', { requestId: req.requestId, error: err.message });
      });
    }
    const webSub = subscription?.web;
    if (paddleConfig() && webSub?.paddleSubscriptionId && webSub.plan === 'pro' && webSub.willRenew) {
      paddle.cancelSubscription({ subscriptionId: webSub.paddleSubscriptionId }).catch((err) => {
        logger.warn('billing.paddle_cancel_failed', { requestId: req.requestId, error: err.message });
      });
    }
    res.json({ message: 'Account deleted' });
  } catch (err) {
    next(err);
  }
};

// Shared with passwordResetController (US-AUTH-08): one set of rules for
// every new password.
exports.newPasswordProblem = newPasswordProblem;
exports.MAX_EMAIL_LENGTH = MAX_EMAIL_LENGTH;
