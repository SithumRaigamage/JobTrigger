/**
 * P20-12/13: the server-side plan limits on saved credentials. The backend
 * owns credentials, so these can't be bypassed by a modified client. Other
 * Pro features are gated in the app, which is where they run.
 */
const CREDENTIAL_TARGETS = require('../models/credentialTargets');
const { entitlementsFor } = require('./entitlements');

const PLAN_LIMIT = 'PLAN_LIMIT';

const MESSAGES = {
  multiTool: 'Your plan covers one CI tool. Upgrade to Pro to add servers for every tool.',
  maxCredentialsTotal: (n) =>
    `Your plan allows ${n} saved server${n === 1 ? '' : 's'}. Upgrade to Pro to add more.`,
  maxCredentialsPerTool: (n) => `You can save up to ${n} servers for one tool.`,
  locked: 'This server is locked on your plan. Upgrade to Pro, or choose it as your one server.',
};

/** Sends the 403 body every client maps to PlanLimitFailure. */
function sendPlanLimit(res, limit, message) {
  return res.status(403).json({ message, code: PLAN_LIMIT, limit });
}

/** The user's credentials across every tool, oldest first: `{ id, tool, createdAt }`. */
async function allCredentials(userId) {
  const rows = await Promise.all(
    CREDENTIAL_TARGETS.map(async ({ tool, Model }) => {
      const docs = await Model.find({ userId }, { _id: 1, createdAt: 1 }).lean();
      return docs.map((doc) => ({ id: String(doc._id), tool, createdAt: doc.createdAt ?? new Date(0) }));
    }),
  );
  return rows.flat().sort((a, b) => new Date(a.createdAt) - new Date(b.createdAt));
}

/**
 * Why [userId] may not save another [tool] credential, as
 * `{ limit, message }`, or null when they may.
 */
async function createProblem(userId, tool) {
  const ent = await entitlementsFor(userId);
  const existing = await allCredentials(userId);
  const forTool = existing.filter((c) => c.tool === tool).length;
  const { maxCredentialsTotal: total, maxCredentialsPerTool: perTool } = ent.limits;

  if (!ent.features.multiTool && existing.some((c) => c.tool !== tool)) {
    return { limit: 'multiTool', message: MESSAGES.multiTool };
  }
  if (total !== null && existing.length >= total) {
    return { limit: 'maxCredentialsTotal', message: MESSAGES.maxCredentialsTotal(total) };
  }
  if (perTool !== null && forTool >= perTool) {
    return { limit: 'maxCredentialsPerTool', message: MESSAGES.maxCredentialsPerTool(perTool) };
  }
  return null;
}

/**
 * US-SUB-05: ids of the credentials usable on the user's plan. Pro: all.
 * Free: one — the chosen primary if it still exists, else the oldest.
 * Nothing is ever deleted; the rest are listed with `locked: true`.
 */
async function unlockedIds(userId) {
  const ent = await entitlementsFor(userId);
  const all = await allCredentials(userId);
  if (ent.limits.maxCredentialsTotal === null) return new Set(all.map((c) => c.id));
  const primary = ent.subscription?.primaryCredentialId
    ? String(ent.subscription.primaryCredentialId)
    : null;
  const keep = all.some((c) => c.id === primary) ? [primary] : all.slice(0, 1).map((c) => c.id);
  // A total above one (should the plans change) keeps the oldest after the primary.
  for (const c of all) {
    if (keep.length >= ent.limits.maxCredentialsTotal) break;
    if (!keep.includes(c.id)) keep.push(c.id);
  }
  return new Set(keep);
}

module.exports = {
  PLAN_LIMIT,
  MESSAGES,
  sendPlanLimit,
  allCredentials,
  createProblem,
  unlockedIds,
};
