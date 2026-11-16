/**
 * SP-15: give an account the website's super-admin role (the student
 * review pages), or take it away. The only way a role is ever set: no API
 * reads one from a request or writes one. Local or dev databases only
 * (the same AUD-58 guard as grant-plan.js).
 *
 *   node scripts/grant-role.js <email> superAdmin
 *   node scripts/grant-role.js <email> user          back to a normal account
 *   add --allow-remote for the Atlas dev cluster (never production)
 */
const mongoose = require('mongoose');
const { connectDatabase } = require('../lib/database');
const { requireLocalDatabase } = require('./localOnly');
const User = require('../models/User');

const ROLES = ['user', 'superAdmin'];

function parseArgs(argv) {
  const [email, role] = argv.filter((a) => !a.startsWith('--'));
  return { email, role };
}

async function main() {
  require('dotenv').config();
  const { email, role } = parseArgs(process.argv.slice(2));
  if (!email || !ROLES.includes(role)) {
    console.error(`Usage: node scripts/grant-role.js <email> <${ROLES.join('|')}> [--allow-remote]`);
    process.exit(2);
  }
  requireLocalDatabase(process.env.MONGODB_URI);
  await connectDatabase();
  try {
    const result = await User.updateOne({ email: email.trim().toLowerCase() }, { $set: { role } });
    if (result.matchedCount === 0) {
      console.error('No account with that email.');
      process.exitCode = 1;
      return;
    }
    console.log(`Role set to ${role}.`);
  } finally {
    await mongoose.disconnect();
  }
}

if (require.main === module) main();

module.exports = { parseArgs, ROLES };
