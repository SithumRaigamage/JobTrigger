/**
 * Phase 21: run the student plan's housekeeping by hand (the same steps as
 * the daily in-process job): deletes documents 30 days after a decision.
 * Local or dev databases only (the AUD-58 guard).
 *
 *   node scripts/run-student-jobs.js [--allow-remote]
 */
const mongoose = require('mongoose');
const { connectDatabase } = require('../lib/database');
const { requireLocalDatabase } = require('./localOnly');
const { runAll } = require('../lib/studentJobs');

async function main() {
  require('dotenv').config();
  requireLocalDatabase(process.env.MONGODB_URI);
  await connectDatabase();
  try {
    console.log(JSON.stringify(await runAll()));
  } finally {
    await mongoose.disconnect();
  }
}

if (require.main === module) main();
