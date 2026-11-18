/**
 * Release 1.0.0: the shared free tester account, and the cleanup of the
 * temporary one it replaces. Safe to run more than once.
 *
 *   node scripts/ensure-test-accounts.js
 *   node scripts/ensure-test-accounts.js --allow-remote   # the Atlas dev cluster
 *
 * Creates (or resets) `tester@jobtrigger.app` / `TesterPass123!` with no
 * subscription, so it starts on Free. Removes `journey1@example.com` and its
 * plan. Never grants Pro: buying, cancelling and resubscribing is the point
 * of the tester.
 */
const mongoose = require('mongoose');
const { connectDatabase } = require('../lib/database');
const { requireLocalDatabase } = require('./localOnly');
const User = require('../models/User');
const Subscription = require('../models/Subscription');

const TESTER = Object.freeze({
  email: 'tester@jobtrigger.app',
  password: 'TesterPass123!',
});
const OLD_EMAIL = 'journey1@example.com';

async function ensureTestAccounts() {
  const removed = await User.findOne({ email: OLD_EMAIL });
  if (removed) {
    await Subscription.deleteMany({ userId: removed._id });
    await User.deleteOne({ _id: removed._id });
  }

  let tester = await User.findOne({ email: TESTER.email });
  if (tester) {
    tester.password = TESTER.password; // Re-hashed by the pre-save hook.
    await tester.save();
  } else {
    tester = new User({ email: TESTER.email, password: TESTER.password });
    await tester.save();
  }

  // Created now, so any leftover plan from an earlier account is gone.
  await Subscription.deleteMany({ userId: tester._id });
  return { removed: Boolean(removed), created: Boolean(tester) };
}

async function main() {
  require('dotenv').config();
  requireLocalDatabase(process.env.MONGODB_URI);
  await connectDatabase();
  try {
    const result = await ensureTestAccounts();
    if (result.removed) console.log(`Removed ${OLD_EMAIL}.`);
    console.log(`Tester ready: ${TESTER.email} / ${TESTER.password} (Free).`);
  } finally {
    await mongoose.disconnect();
  }
}

if (require.main === module) main();

module.exports = { TESTER, OLD_EMAIL, ensureTestAccounts };
