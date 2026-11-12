/**
 * P20-19: give an account Pro by hand — the owner and early testers
 * (rollout step 3 in docs/subscription/03-technical-design.md §8).
 * Local or dev databases only (AUD-58 guard, as for setup-migrations.js).
 *
 *   node scripts/grant-plan.js <email>              Pro with no end date
 *   node scripts/grant-plan.js <email> --days 90    Pro for 90 days
 *   node scripts/grant-plan.js <email> --revoke     back to Free
 *   add --allow-remote for the Atlas dev cluster (never production)
 */
const mongoose = require('mongoose');
const { connectDatabase } = require('../lib/database');
const { requireLocalDatabase } = require('./localOnly');
const User = require('../models/User');
const { writeSource } = require('../billing/combine');

function parseArgs(argv) {
  const [email] = argv.filter((a) => !a.startsWith('--'));
  const daysAt = argv.indexOf('--days');
  const days = daysAt >= 0 ? Number(argv[daysAt + 1]) : null;
  return { email, days, revoke: argv.includes('--revoke') };
}

async function main() {
  require('dotenv').config();
  const { email, days, revoke } = parseArgs(process.argv.slice(2));
  if (!email || (days !== null && !(days > 0))) {
    console.error('Usage: node scripts/grant-plan.js <email> [--days N] [--revoke] [--allow-remote]');
    process.exit(2);
  }
  requireLocalDatabase(process.env.MONGODB_URI);
  await connectDatabase();
  try {
    const user = await User.findOne({ email: email.trim().toLowerCase() });
    if (!user) {
      console.error('No account with that email.');
      process.exitCode = 1;
      return;
    }
    const fields = revoke
      ? { plan: 'free', status: 'expired', source: 'admin', periodEnd: new Date(), willRenew: false }
      : {
          plan: 'pro',
          status: 'active',
          source: 'admin',
          productId: null,
          periodEnd: days ? new Date(Date.now() + days * 24 * 60 * 60 * 1000) : null,
          willRenew: false,
        };
    await writeSource(user._id, 'grant', fields);
    console.log(revoke ? 'Back to Free.' : `Pro granted${days ? ` for ${days} days` : ''}.`);
  } finally {
    await mongoose.disconnect();
  }
}

if (require.main === module) main();

module.exports = { parseArgs };
