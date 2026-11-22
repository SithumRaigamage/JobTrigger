/**
 * US-PROMO-01: promo and voucher codes. A code gives a Free account a stretch
 * of Pro. The codes are a list in the environment (`PROMO_CODES`,
 * config/env.js), so adding or retiring one is an edit and a redeploy: no
 * database of codes to keep in step, and never a code in a client bundle.
 *
 * The grant is written into its own `promo` source, so it can never overwrite
 * a store or website subscription, and a paid plan always outranks it
 * (billing/combine.js). Expiry is the source's `periodEnd` compared with the
 * clock on every read — no job (billing/entitlements.js `isPro`).
 */
const PromoRedemption = require('../models/PromoRedemption');
const { billingEnabled, promoCodes } = require('../config/env');
const { writeSource } = require('./combine');
const { entitlementsFor } = require('./entitlements');

const DAY_MS = 24 * 60 * 60 * 1000;
const MAX_CODE_LENGTH = 64;

/** Trimmed and upper-cased, so `  launch30 ` is `LAUNCH30`. Never throws. */
const normalizeCode = (raw) =>
  String(raw ?? '').trim().toUpperCase().slice(0, MAX_CODE_LENGTH);

/** Whether either the app or the website should offer the action. */
function promoAvailable() {
  return billingEnabled() && promoCodes().length > 0;
}

/** The configured entry for an already-normalized [code], or null. */
function promoEntry(code) {
  if (!code) return null;
  return promoCodes().find((entry) => entry.code === code) ?? null;
}

/**
 * Whether [entry] can still be used at [now]: its last day has not passed and
 * its total redemption cap is not reached. Counts redemptions, so it awaits.
 */
async function isUsable(entry, now = new Date()) {
  if (!entry) return false;
  if (entry.expiresAt && entry.expiresAt <= now) return false;
  if (entry.maxRedemptions === null) return true;
  const used = await PromoRedemption.countDocuments({ code: entry.code });
  return used < entry.maxRedemptions;
}

/**
 * Redeems [raw] for [userId]. Returns `{ ok: true, entry, periodEnd }` or a
 * refusal `{ status, code, message }` for the controller to send as-is.
 *
 * Order matters: "already used" is answered before the cap and the last day, so
 * an account that used a code always hears that rather than "not valid"; and
 * every refusal about the code itself reads the same whether it is unknown,
 * expired or used up (no enumeration of a secret list).
 */
async function redeemPromo(userId, raw, { now = new Date() } = {}) {
  if (!promoAvailable()) {
    return {
      status: 503,
      code: 'not_available',
      message: "Promo codes aren't available right now.",
    };
  }
  const entry = promoEntry(normalizeCode(raw));
  if (!entry) {
    return {
      status: 400,
      code: 'invalid_code',
      message: "That code isn't valid, or it has expired.",
    };
  }
  if (await PromoRedemption.exists({ code: entry.code, userId })) {
    return {
      status: 409,
      code: 'already_redeemed',
      message: "You've already used that code.",
    };
  }
  if (!(await isUsable(entry, now))) {
    return {
      status: 400,
      code: 'invalid_code',
      message: "That code isn't valid, or it has expired.",
    };
  }
  // A code adds Pro to a Free account; on a Pro account it would change
  // nothing visible, so say so instead of silently doing nothing.
  const before = await entitlementsFor(userId, { now });
  if (before.plan === 'pro') {
    return {
      status: 409,
      code: 'already_pro',
      message: 'Your account already has Pro, so this code would add nothing.',
    };
  }

  const periodEnd = new Date(now.getTime() + entry.days * DAY_MS);
  try {
    await PromoRedemption.create({ code: entry.code, userId, days: entry.days, periodEnd });
  } catch (err) {
    // The unique { code, userId } index: a second request lost the race.
    if (err?.code === 11000) {
      return {
        status: 409,
        code: 'already_redeemed',
        message: "You've already used that code.",
      };
    }
    throw err;
  }
  try {
    await writeSource(
      userId,
      'promo',
      {
        plan: 'pro',
        status: 'active',
        source: 'promo',
        // The owner console shows which code was used.
        productId: entry.code,
        startsAt: now,
        periodEnd,
        willRenew: false,
      },
      { now },
    );
  } catch (err) {
    // No Pro was written, so let the account try the same code again.
    await PromoRedemption.deleteOne({ code: entry.code, userId }).catch(() => {});
    throw err;
  }
  return { ok: true, entry, periodEnd };
}

module.exports = {
  DAY_MS,
  normalizeCode,
  promoAvailable,
  promoEntry,
  isUsable,
  redeemPromo,
};
