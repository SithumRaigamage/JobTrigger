/**
 * US-SUB-11: the team plan's rules, in one place. Controllers turn a
 * TeamError into its HTTP status; nothing here knows about Express.
 * Story: docs/user-stories/billing/18-subscriptions.md (AC2–AC11).
 */
// Operators below are built here, never taken from a client (sanitizeFilter,
// AUD-04), so they are marked trusted.
const crypto = require('crypto');
const mongoose = require('mongoose');
const Team = require('../models/Team');
const User = require('../models/User');
const JenkinsCredential = require('../models/JenkinsCredential');

const MIN_SEATS = 2;
const MAX_SEATS = 100;
const INVITE_DAYS = 7;
const DAY_MS = 24 * 60 * 60 * 1000;
/** USD per seat; the Paddle prices carry the real amounts. */
const PRICES = { monthly: 6.99, yearly: 69.9 };

/** The statuses that keep Pro inside the period (billing/entitlements.js). */
const PRO_STATUSES = new Set(['trialing', 'active', 'grace', 'billing_issue', 'cancelled']);

class TeamError extends Error {
  constructor(status, code, message) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

const hashToken = (token) => crypto.createHash('sha256').update(String(token)).digest('hex');
const sameId = (a, b) => String(a) === String(b);
const validSeats = (n) => Number.isInteger(n) && n >= MIN_SEATS && n <= MAX_SEATS;

/** AC7: whether [team]'s subscription grants Pro at [now]. Pure. */
function teamIsPro(team, now = new Date()) {
  const billing = team?.billing;
  if (!billing || billing.plan !== 'pro' || !PRO_STATUSES.has(billing.status)) return false;
  return Boolean(billing.periodEnd) && new Date(billing.periodEnd) > now;
}

/** Members plus invites that haven't expired. Pure. */
function seatsUsed(team, now = new Date()) {
  const pending = (team.invites ?? []).filter((invite) => new Date(invite.expiresAt) > now);
  return (team.members ?? []).length + pending.length;
}

const teamOf = (userId) => Team.findOne({ 'members.userId': userId });

async function activeTeamFor(userId, now = new Date()) {
  const team = await Team.findOne({ 'members.userId': userId }).lean();
  return team && teamIsPro(team, now) ? team : null;
}

function requireOwner(team, userId) {
  if (!team) throw new TeamError(404, 'NO_TEAM', "You aren't in a team.");
  if (!sameId(team.ownerId, userId)) {
    throw new TeamError(403, 'NOT_OWNER', "Only the team's owner can do that.");
  }
}

/** AC2. */
async function createTeam(userId, name) {
  const trimmed = typeof name === 'string' ? name.trim() : '';
  if (trimmed.length < 1 || trimmed.length > 60) {
    throw new TeamError(400, 'INVALID_NAME', 'Give the team a name of 1 to 60 characters.');
  }
  if (await Team.exists({ 'members.userId': userId })) {
    throw new TeamError(409, 'ALREADY_IN_TEAM', "You're already in a team.");
  }
  try {
    return await Team.create({ name: trimmed, ownerId: userId, members: [{ userId }] });
  } catch (err) {
    if (err.code === 11000) throw new TeamError(409, 'ALREADY_IN_TEAM', "You're already in a team.");
    throw err;
  }
}

/** AC5. Returns the team and the raw token, which only goes into the email. */
async function invite(userId, email, now = new Date()) {
  const team = await teamOf(userId);
  requireOwner(team, userId);
  const address = typeof email === 'string' ? email.trim().toLowerCase() : '';
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(address) || address.length > 254) {
    throw new TeamError(400, 'INVALID_EMAIL', 'Enter an email address.');
  }
  const memberIds = team.members.map((m) => m.userId);
  if (await User.exists({ _id: mongoose.trusted({ $in: memberIds }), email: address })) {
    throw new TeamError(409, 'ALREADY_MEMBER', "That person is already in the team.");
  }
  // Inviting the same address again replaces the old invite.
  team.invites = team.invites.filter((i) => i.email !== address && new Date(i.expiresAt) > now);
  if (seatsUsed(team, now) >= team.seats) {
    throw new TeamError(403, 'SEATS_FULL', 'Every seat is taken. Add seats to invite someone else.');
  }
  const token = crypto.randomBytes(32).toString('base64url');
  team.invites.push({
    email: address,
    tokenHash: hashToken(token),
    expiresAt: new Date(now.getTime() + INVITE_DAYS * DAY_MS),
    invitedBy: userId,
  });
  await team.save();
  return { team, token };
}

async function cancelInvite(userId, inviteId) {
  const team = await teamOf(userId);
  requireOwner(team, userId);
  const before = team.invites.length;
  team.invites = team.invites.filter((i) => !sameId(i._id, inviteId));
  if (team.invites.length === before) throw new TeamError(404, 'NO_INVITE', 'That invite no longer exists.');
  await team.save();
  return team;
}

/** AC6. */
async function accept(userId, token, now = new Date()) {
  if (typeof token !== 'string' || token.length < 20 || token.length > 100) {
    throw new TeamError(404, 'INVITE_UNKNOWN', "This invite link isn't valid.");
  }
  const tokenHash = hashToken(token);
  const team = await Team.findOne({ 'invites.tokenHash': tokenHash });
  const found = team?.invites.find((i) => i.tokenHash === tokenHash);
  if (!found) throw new TeamError(404, 'INVITE_UNKNOWN', "This invite link isn't valid.");
  if (new Date(found.expiresAt) <= now) {
    throw new TeamError(410, 'INVITE_EXPIRED', 'This invite has expired. Ask for a new one.');
  }
  const user = await User.findById(userId, { email: 1 }).lean();
  if (!user || String(user.email).toLowerCase() !== found.email) {
    throw new TeamError(403, 'INVITE_OTHER_EMAIL', `This invite is for ${found.email}. Sign in with that account.`);
  }
  if (await Team.exists({ 'members.userId': userId })) {
    throw new TeamError(409, 'ALREADY_IN_TEAM', "You're already in a team. Leave it first.");
  }
  // The invite held its seat; a lowered seat count can still leave no room.
  if (team.members.length >= team.seats) {
    throw new TeamError(403, 'SEATS_FULL', 'Every seat in this team is taken.');
  }
  team.invites = team.invites.filter((i) => i.tokenHash !== tokenHash);
  team.members.push({ userId, joinedAt: now });
  try {
    await team.save();
  } catch (err) {
    if (err.code === 11000) throw new TeamError(409, 'ALREADY_IN_TEAM', "You're already in a team. Leave it first.");
    throw err;
  }
  return team;
}

/** AC8: the owner removes a member. */
async function removeMember(userId, memberId) {
  const team = await teamOf(userId);
  requireOwner(team, userId);
  if (sameId(memberId, team.ownerId)) {
    throw new TeamError(400, 'OWNER_STAYS', "The owner can't be removed. Delete the team instead.");
  }
  const before = team.members.length;
  team.members = team.members.filter((m) => !sameId(m.userId, memberId));
  if (team.members.length === before) throw new TeamError(404, 'NO_MEMBER', "That person isn't in the team.");
  await team.save();
  return team;
}

/** AC8: a member leaves. */
async function leave(userId) {
  const team = await teamOf(userId);
  if (!team) throw new TeamError(404, 'NO_TEAM', "You aren't in a team.");
  if (sameId(team.ownerId, userId)) {
    throw new TeamError(400, 'OWNER_STAYS', "The owner can't leave. Delete the team instead.");
  }
  team.members = team.members.filter((m) => !sameId(m.userId, userId));
  await team.save();
}

/** AC9: validates a new seat count. The caller updates Paddle first. */
async function checkSeats(userId, seats, now = new Date()) {
  const team = await teamOf(userId);
  requireOwner(team, userId);
  if (!validSeats(seats)) {
    throw new TeamError(400, 'INVALID_SEATS', `Choose ${MIN_SEATS} to ${MAX_SEATS} seats.`);
  }
  if (seats < seatsUsed(team, now)) {
    throw new TeamError(409, 'SEATS_IN_USE', 'Remove members or cancel invites before lowering the seats.');
  }
  return team;
}

/** AC10: the owner shares one of their own Jenkins servers. */
async function share(userId, credentialId) {
  const team = await teamOf(userId);
  requireOwner(team, userId);
  if (!mongoose.Types.ObjectId.isValid(credentialId)
      || !(await JenkinsCredential.exists({ _id: credentialId, userId }))) {
    throw new TeamError(404, 'NO_SERVER', 'Choose one of your own Jenkins servers.');
  }
  if (!team.sharedServers.some((s) => sameId(s.credentialId, credentialId))) {
    team.sharedServers.push({ tool: 'jenkins', credentialId });
    await team.save();
  }
  return team;
}

async function unshare(userId, credentialId) {
  const team = await teamOf(userId);
  requireOwner(team, userId);
  team.sharedServers = team.sharedServers.filter((s) => !sameId(s.credentialId, credentialId));
  await team.save();
  return team;
}

/**
 * AC10: the shared Jenkins credentials a member may use now: the team must
 * be active, and only servers the owner still owns count.
 */
async function sharedCredentialsFor(userId, now = new Date()) {
  const team = await activeTeamFor(userId, now);
  if (!team) return { team: null, credentials: [] };
  const ids = team.sharedServers.filter((s) => s.tool === 'jenkins').map((s) => s.credentialId);
  const credentials = ids.length === 0
    ? []
    : await JenkinsCredential.find({ _id: mongoose.trusted({ $in: ids }), userId: team.ownerId });
  return { team, credentials };
}

/** AC11. */
async function deleteTeam(userId, now = new Date()) {
  const team = await teamOf(userId);
  requireOwner(team, userId);
  if (teamIsPro(team, now) && team.billing.willRenew) {
    throw new TeamError(409, 'TEAM_SUBSCRIPTION_ACTIVE',
      "Cancel the team's subscription in the billing portal first, so nobody is charged after the team is gone.");
  }
  await Team.deleteOne({ _id: team._id });
}

/** AC11: what account deletion has to do with teams. */
async function onAccountDeletion(userId) {
  if (await Team.exists({ ownerId: userId })) {
    throw new TeamError(403, 'TEAM_OWNER', 'Delete your team before deleting your account.');
  }
  await Team.updateMany({ 'members.userId': userId }, { $pull: { members: { userId } } });
}

module.exports = {
  TeamError,
  MIN_SEATS,
  MAX_SEATS,
  INVITE_DAYS,
  PRICES,
  hashToken,
  teamIsPro,
  seatsUsed,
  teamOf,
  activeTeamFor,
  createTeam,
  invite,
  cancelInvite,
  accept,
  removeMember,
  leave,
  checkSeats,
  share,
  unshare,
  sharedCredentialsFor,
  deleteTeam,
  onAccountDeletion,
  validSeats,
};
