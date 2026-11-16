/**
 * Web (Paddle) + app stores (RevenueCat): the plan is the best of the
 * user's sources. Pro from any source wins; between two Pro sources, the
 * one that lasts longer (no end beats any end). With no Pro source, the
 * most recent ended one is shown, so "expired" still reads as expired.
 *
 * Phase 21: the student year is the exception to "lasts longer wins". A
 * paid or granted Pro always outranks it, so a student who subscribes sees
 * (and is managed as) a paid user, and the student year is not what the
 * account shows while something else is active.
 */
const Subscription = require('../models/Subscription');
const { isPro } = require('./entitlements');

const PLAN_FIELDS = ['plan', 'status', 'source', 'productId', 'periodEnd', 'willRenew'];
const NONE = { plan: 'free', status: 'none', source: null, productId: null, periodEnd: null, willRenew: false };

const endOf = (s) => (s.periodEnd ? new Date(s.periodEnd).getTime() : Infinity);
const pick = (s) => Object.fromEntries(PLAN_FIELDS.map((f) => [f, s[f] ?? NONE[f]]));

/** The derived top-level fields for a Subscription [doc] at [now]. Pure. */
function derive(doc, now = new Date()) {
  // Before sources existed, grant-plan.js wrote an admin grant at the top.
  const legacyGrant = !doc?.grant && doc?.source === 'admin' ? doc : null;
  const sources = [doc?.store, doc?.web, doc?.grant ?? legacyGrant, doc?.student].filter(Boolean);
  const rank = (s) => (s.source === 'student' ? 1 : 0);
  const pro = sources.filter((s) => isPro(s, now)).sort((a, b) => rank(a) - rank(b) || endOf(b) - endOf(a));
  if (pro.length > 0) return pick(pro[0]);
  const ended = sources
    .filter((s) => s.status && s.status !== 'none')
    .sort((a, b) => (b.periodEnd ? new Date(b.periodEnd) : 0) - (a.periodEnd ? new Date(a.periodEnd) : 0));
  return ended.length > 0 ? { ...pick(ended[0]), plan: 'free' } : { ...NONE };
}

/**
 * Writes [fields] into the user's [key] source (`store`, `web`, `grant`)
 * and recomputes the plan. Other sources and the Free-plan primary are
 * left alone. Returns the saved document (lean).
 */
async function writeSource(userId, key, fields, { now = new Date() } = {}) {
  const current = (await Subscription.findOne({ userId }).lean()) ?? {};
  const next = { ...current, [key]: { ...(current[key] ?? {}), ...fields } };
  if (key !== 'grant' && !current.grant && current.source === 'admin') {
    next.grant = pick(current); // keep a legacy admin grant as a source
  }
  const set = { [key]: next[key], ...derive(next, now) };
  if (next.grant && !current.grant) set.grant = next.grant;
  return Subscription.findOneAndUpdate(
    { userId },
    { $set: set },
    { upsert: true, returnDocument: 'after', setDefaultsOnInsert: true },
  ).lean();
}

module.exports = { derive, writeSource, NONE };
