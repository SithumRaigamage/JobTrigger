/**
 * Phase 21: the student plan's daily housekeeping, run in-process on a
 * timer (the pattern of lib/errorReporting/outbox.js) and by hand with
 * scripts/run-student-jobs.js. No scheduler dependency.
 *
 * Every step is safe to repeat and safe to miss: nothing here decides who
 * has Pro (that is computed from the date on every read), so a missed day
 * only delays housekeeping.
 */
const mongoose = require('mongoose');
const StudentVerification = require('../models/StudentVerification');
const { logger } = require('./logger');

const DAY_MS = 24 * 60 * 60 * 1000;
const DOCUMENT_KEEP_DAYS = 30;

let timer = null;

/**
 * SP-32: deletes the document bytes and the name from decisions older than
 * 30 days. The hash stays (in `documentHash` and in StudentClaim).
 * Returns how many applications were cleaned.
 */
async function purgeDecidedDocuments(now = new Date()) {
  // The operators are ours, not a client's (sanitizeFilter, AUD-04): trusted.
  const due = await StudentVerification.find({
    documentDeleteAt: mongoose.trusted({ $lte: now }),
    documentDeletedAt: null,
  }).select('_id').lean();
  if (due.length === 0) return 0;
  const result = await StudentVerification.updateMany(
    { _id: mongoose.trusted({ $in: due.map((d) => d._id) }) },
    { $set: { documentData: null, fullName: null, documentDeletedAt: now, documentDeleteAt: null } },
  );
  return result.modifiedCount;
}

/** Runs every step once. Never throws. */
async function runAll(now = new Date()) {
  const summary = {};
  try {
    summary.documentsDeleted = await purgeDecidedDocuments(now);
  } catch (err) {
    logger.error('student.job_failed', { step: 'purge_documents', error: err.message });
  }
  logger.info('student.jobs_run', summary);
  return summary;
}

/** Starts the daily timer (and one run now). A no-op when disabled or running. */
function start() {
  if (timer || process.env.STUDENT_JOBS_ENABLED === 'false') return;
  runAll();
  timer = setInterval(runAll, DAY_MS);
  timer.unref();
}

function stop() {
  if (timer) clearInterval(timer);
  timer = null;
}

module.exports = { DOCUMENT_KEEP_DAYS, DAY_MS, purgeDecidedDocuments, runAll, start, stop };
