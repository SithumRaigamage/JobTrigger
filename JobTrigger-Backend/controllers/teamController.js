/**
 * US-SUB-11: /api/team. Every route needs a signed-in user and the team
 * plan switched on (middleware/teamOnly.js). Rules live in lib/team.js.
 * Responses carry member emails to that team's members only, and secrets
 * only from GET /servers/jenkins/:id/secret.
 */
const mongoose = require('mongoose');
const User = require('../models/User');
const team = require('../lib/team');
const paddle = require('../billing/paddleClient');
const { maskSecret } = require('../security/secretMask');
const { sendMail } = require('../lib/mailer');
const { teamInviteEmail } = require('../emails/team');
const { billingEnabled, paddleConfig, paddleTeamPrices, siteUrl } = require('../config/env');
const { logger } = require('../lib/logger');

const { TeamError } = team;

/** Wraps a handler: TeamError → its status and code; anything else → next. */
const handle = (fn) => async (req, res, next) => {
  try {
    await fn(req, res);
  } catch (err) {
    if (err instanceof TeamError) return res.status(err.status).json({ code: err.code, message: err.message });
    next(err);
  }
};

const isOwner = (doc, userId) => String(doc.ownerId) === String(userId);

/** The team as [userId] may see it. */
async function view(doc, userId, now = new Date()) {
  const owner = isOwner(doc, userId);
  const users = await User.find({ _id: mongoose.trusted({ $in: doc.members.map((m) => m.userId) }) }, { email: 1 }).lean();
  const emails = new Map(users.map((u) => [String(u._id), u.email]));
  return {
    id: String(doc._id),
    name: doc.name,
    role: owner ? 'owner' : 'member',
    seats: doc.seats,
    seatsUsed: team.seatsUsed(doc, now),
    active: team.teamIsPro(doc, now),
    billing: {
      status: doc.billing?.status ?? 'none',
      period: doc.billing?.period ?? null,
      periodEnd: doc.billing?.periodEnd ? new Date(doc.billing.periodEnd).toISOString() : null,
      willRenew: Boolean(doc.billing?.willRenew),
    },
    members: doc.members.map((m) => ({
      userId: String(m.userId),
      email: emails.get(String(m.userId)) ?? null,
      owner: String(m.userId) === String(doc.ownerId),
      joinedAt: new Date(m.joinedAt).toISOString(),
    })),
    // Pending invites are the owner's business only.
    invites: owner
      ? doc.invites
        .filter((i) => new Date(i.expiresAt) > now)
        .map((i) => ({ id: String(i._id), email: i.email, expiresAt: new Date(i.expiresAt).toISOString() }))
      : [],
    sharedServerIds: doc.sharedServers.map((s) => String(s.credentialId)),
    prices: { monthly: team.PRICES.monthly, yearly: team.PRICES.yearly, minSeats: team.MIN_SEATS, maxSeats: team.MAX_SEATS },
  };
}

const send = async (res, doc, userId) => {
  res.set('Cache-Control', 'no-store');
  res.json(doc ? await view(doc, userId) : null);
};

exports.get = handle(async (req, res) => send(res, await team.teamOf(req.user.id), req.user.id));

exports.create = handle(async (req, res) => {
  const doc = await team.createTeam(req.user.id, req.body?.name);
  res.status(201);
  await send(res, doc, req.user.id);
});

exports.remove = handle(async (req, res) => {
  await team.deleteTeam(req.user.id);
  res.json({ message: 'Team deleted' });
});

exports.invite = handle(async (req, res) => {
  const { team: doc, token } = await team.invite(req.user.id, req.body?.email);
  const invited = doc.invites[doc.invites.length - 1];
  const inviter = await User.findById(req.user.id, { email: 1 }).lean();
  const link = `${siteUrl()}/account/team/join?token=${encodeURIComponent(token)}`;
  // The token is only ever in this email, never in a response or a log.
  try {
    await sendMail({
      to: invited.email,
      ...teamInviteEmail({ teamName: doc.name, inviterEmail: inviter?.email ?? 'Your team', link, days: team.INVITE_DAYS }),
      kind: 'team_invite',
    });
  } catch (err) {
    logger.warn('team.invite_mail_failed', { error: err.message });
  }
  res.status(201);
  await send(res, doc, req.user.id);
});

exports.cancelInvite = handle(async (req, res) =>
  send(res, await team.cancelInvite(req.user.id, req.params.inviteId), req.user.id));

exports.join = handle(async (req, res) => send(res, await team.accept(req.user.id, req.body?.token), req.user.id));

exports.removeMember = handle(async (req, res) =>
  send(res, await team.removeMember(req.user.id, req.params.userId), req.user.id));

exports.leave = handle(async (req, res) => {
  await team.leave(req.user.id);
  res.json({ message: 'You left the team' });
});

const unavailable = (res) => res.status(503).json({
  code: 'TEAM_BILLING_UNAVAILABLE',
  message: "Buying for a team isn't available right now.",
});

/** AC9: a subscribed team's quantity changes in Paddle first. */
exports.setSeats = handle(async (req, res) => {
  const seats = Number(req.body?.seats);
  const doc = await team.checkSeats(req.user.id, seats);
  const subscriptionId = doc.billing?.paddleSubscriptionId;
  if (subscriptionId && team.teamIsPro(doc)) {
    const prices = paddleTeamPrices();
    if (!paddleConfig() || !prices) return unavailable(res);
    await paddle.updateSubscriptionQuantity({
      subscriptionId,
      priceId: prices[doc.billing.period === 'yearly' ? 'yearly' : 'monthly'],
      quantity: seats,
    });
  }
  doc.seats = seats;
  await doc.save();
  await send(res, doc, req.user.id);
});

/** AC3: the owner buys seats on the website. */
exports.checkout = handle(async (req, res) => {
  const prices = paddleTeamPrices();
  const config = paddleConfig();
  if (!billingEnabled() || !config || !prices) return unavailable(res);
  const { period } = req.body ?? {};
  if (period !== 'monthly' && period !== 'yearly') {
    return res.status(400).json({ code: 'INVALID_PERIOD', message: 'Choose monthly or yearly' });
  }
  const seats = Number(req.body?.seats);
  const doc = await team.checkSeats(req.user.id, seats);
  if (team.teamIsPro(doc) && doc.billing.willRenew) {
    return res.status(409).json({ code: 'ALREADY_SUBSCRIBED', message: 'Your team already has a subscription. Change its seats instead.' });
  }
  const { transactionId } = await paddle.createTransaction({
    priceId: prices[period],
    quantity: seats,
    customData: { teamId: String(doc._id) },
  });
  res.set('Cache-Control', 'no-store');
  res.json({ transactionId, environment: config.environment });
});

const presentServer = (cred, ownerEmail) => {
  const json = cred.toJSON();
  return {
    id: String(cred._id),
    tool: 'jenkins',
    serverName: json.serverName,
    jenkinsURL: json.jenkinsURL,
    username: json.username,
    secretMask: maskSecret(json.password),
    hasParamToken: Boolean(json.paramToken),
    needsReentry: Boolean(json.needsReentry),
    sharedBy: ownerEmail,
    updatedAt: json.updatedAt ? new Date(json.updatedAt).toISOString() : null,
  };
};

/** AC10: members of an active team, masked. */
exports.listServers = handle(async (req, res) => {
  const { team: doc, credentials } = await team.sharedCredentialsFor(req.user.id);
  const owner = doc ? await User.findById(doc.ownerId, { email: 1 }).lean() : null;
  res.set('Cache-Control', 'no-store');
  res.json(credentials.map((c) => presentServer(c, owner?.email ?? null)));
});

exports.shareServer = handle(async (req, res) =>
  send(res, await team.share(req.user.id, req.body?.credentialId), req.user.id));

exports.unshareServer = handle(async (req, res) =>
  send(res, await team.unshare(req.user.id, req.params.id), req.user.id));

/** AC10: the one place a shared secret leaves the backend. */
exports.serverSecret = handle(async (req, res) => {
  const { id } = req.params;
  if (!mongoose.Types.ObjectId.isValid(id)) return res.status(400).json({ message: 'Invalid credential id' });
  const { credentials } = await team.sharedCredentialsFor(req.user.id);
  const credential = credentials.find((c) => String(c._id) === id);
  if (!credential) return res.status(404).json({ message: 'Credential not found' });
  const json = credential.toJSON();
  res.set('Cache-Control', 'no-store');
  res.set('Pragma', 'no-cache');
  res.json({
    password: json.password ?? null,
    paramToken: json.paramToken ?? null,
    needsReentry: Boolean(json.needsReentry),
    version: new Date(json.updatedAt).toISOString(),
  });
});
