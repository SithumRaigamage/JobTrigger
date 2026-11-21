const mongoose = require('mongoose');

/**
 * US-SUB-11: a team that buys Pro per seat on the website. The owner is a
 * member too. Invite tokens are stored only as a SHA-256 hash.
 * Design: docs/design/US-SUB-11-team-plan.md.
 */
const memberSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  joinedAt: { type: Date, default: Date.now },
}, { _id: false });

const inviteSchema = new mongoose.Schema({
  email: { type: String, required: true, lowercase: true, trim: true },
  tokenHash: { type: String, required: true },
  expiresAt: { type: Date, required: true },
  invitedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  createdAt: { type: Date, default: Date.now },
});

const sharedServerSchema = new mongoose.Schema({
  tool: { type: String, enum: ['jenkins'], required: true },
  credentialId: { type: mongoose.Schema.Types.ObjectId, required: true },
  sharedAt: { type: Date, default: Date.now },
}, { _id: false });

const billingSchema = new mongoose.Schema({
  plan: { type: String, enum: ['free', 'pro'], default: 'free' },
  status: {
    type: String,
    enum: ['none', 'trialing', 'active', 'grace', 'billing_issue', 'cancelled', 'expired'],
    default: 'none',
  },
  period: { type: String, enum: ['monthly', 'yearly', null], default: null },
  periodEnd: { type: Date, default: null },
  willRenew: { type: Boolean, default: false },
  paddleSubscriptionId: { type: String, default: null },
  paddleCustomerId: { type: String, default: null },
  eventAt: { type: Date, default: null },
}, { _id: false });

const teamSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true, minlength: 1, maxlength: 60 },
  ownerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
  seats: { type: Number, required: true, min: 2, max: 100, default: 2 },
  members: { type: [memberSchema], default: [] },
  invites: { type: [inviteSchema], default: [] },
  sharedServers: { type: [sharedServerSchema], default: [] },
  billing: { type: billingSchema, default: () => ({}) },
}, { timestamps: true });

// A user is in at most one team (AC2), enforced by the database as well.
teamSchema.index({ 'members.userId': 1 }, { unique: true, sparse: true });
teamSchema.index({ 'invites.tokenHash': 1 });
teamSchema.index({ 'billing.paddleSubscriptionId': 1 });

module.exports = mongoose.model('Team', teamSchema);
