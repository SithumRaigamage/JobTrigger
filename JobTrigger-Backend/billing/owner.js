/**
 * Release 1.0.0 (US-SUB-01): the owner's account is Pro forever and is
 * never billed. It is an explicit grant tied to this email — not a side
 * effect of the superAdmin role — so changing someone's role can never
 * change what they are charged (or not charged).
 *
 * The email lives in code, not environment configuration: a fresh
 * deployment or a restored database must not silently lose the grant.
 * `ensureOwnerGrant` is called after signup and login, so an account that
 * existed before this rule also picks it up the next time it signs in.
 * `scripts/grant-plan.js` remains the way to grant anyone else by hand.
 */
const Subscription = require('../models/Subscription');
const { writeSource } = require('./combine');

const OWNER_EMAIL = 'developer@jobtrigger.app';

/** The owner's permanent, never-renewing grant. */
const OWNER_GRANT = Object.freeze({
  plan: 'pro',
  status: 'active',
  source: 'admin',
  productId: null,
  periodEnd: null,
  willRenew: false,
});

const isOwnerEmail = (email) =>
  String(email ?? '').trim().toLowerCase() === OWNER_EMAIL;

/**
 * Makes sure [userId] has the owner grant. Idempotent: an existing grant
 * with no end is left untouched, so signing in doesn't rewrite history (or
 * overwrite a longer manual grant). Returns the current Subscription, or
 * the freshly written one.
 */
async function ensureOwnerGrant(userId) {
  const current = await Subscription.findOne({ userId }).select('grant').lean();
  const grant = current?.grant;
  if (
    grant &&
    grant.plan === 'pro' &&
    grant.status === 'active' &&
    grant.source === 'admin' &&
    !grant.periodEnd
  ) {
    return current;
  }
  return writeSource(userId, 'grant', { ...OWNER_GRANT });
}

module.exports = { OWNER_EMAIL, OWNER_GRANT, isOwnerEmail, ensureOwnerGrant };
