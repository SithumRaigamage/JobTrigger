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
const SupportTicket = require('../models/SupportTicket');
const User = require('../models/User');
const { writeSource } = require('../billing/combine');
const { sendMail } = require('./mailer');
const { studentReminderEmail } = require('../emails/student');
const { studentRenewalEnabled } = require('../config/env');
const { logger } = require('./logger');

const DAY_MS = 24 * 60 * 60 * 1000;
const DOCUMENT_KEEP_DAYS = 30;
/** SP-60: how long before the end the reminder goes out. */
const REMINDER_DAYS = 7;

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

/**
 * P31-03: clears support screenshot bytes 30 days after the ticket was
 * created. Metadata (mime, size, hash, deletion date) stays, so the owner can
 * still tell a screenshot existed. Safe to repeat.
 */
async function purgeSupportScreenshots(now = new Date()) {
  const due = await SupportTicket.find({
    'screenshots.deleteAt': mongoose.trusted({ $lte: now }),
    'screenshots.deletedAt': null,
  }).select('screenshots').lean();
  let cleared = 0;
  for (const ticket of due) {
    const set = {};
    (ticket.screenshots ?? []).forEach((shot, index) => {
      if (shot.deleteAt && shot.deleteAt <= now && !shot.deletedAt) {
        set[`screenshots.${index}.data`] = null;
        set[`screenshots.${index}.deletedAt`] = now;
        set[`screenshots.${index}.deleteAt`] = null;
        cleared += 1;
      }
    });
    if (Object.keys(set).length > 0) {
      await SupportTicket.updateOne({ _id: ticket._id }, { $set: set });
    }
  }
  return cleared;
}

/**
 * SP-60: emails the account address once, in the last 7 days of the year.
 * The in-app banner needs no job: the app reads the end date itself.
 * `reminderSentAt` is claimed before sending so two runs can't both send;
 * a send that fails (or mail being off) gives the claim back, so the next
 * daily run tries again while the year still has days left.
 */
async function sendExpiryReminders(now = new Date()) {
  const windowEnd = new Date(now.getTime() + REMINDER_DAYS * DAY_MS);
  const due = await StudentVerification.find({
    status: 'approved',
    reminderSentAt: null,
    expiresAt: mongoose.trusted({ $gt: now, $lte: windowEnd }),
  }).select('_id userId expiresAt').lean();

  let sent = 0;
  for (const item of due) {
    const claimed = await StudentVerification.findOneAndUpdate(
      { _id: item._id, status: 'approved', reminderSentAt: null },
      { $set: { reminderSentAt: now } },
    );
    if (!claimed) continue;
    const release = () => StudentVerification.updateOne({ _id: item._id }, { $set: { reminderSentAt: null } });
    try {
      const user = await User.findById(item.userId).select('email').lean();
      if (!user) continue;
      const message = studentReminderEmail({ expiresAt: item.expiresAt, canRenew: studentRenewalEnabled() });
      const result = await sendMail({ to: user.email, ...message, kind: 'student_reminder' });
      if (result.sent) sent += 1;
      else await release();
    } catch (err) {
      await release();
      logger.warn('student.reminder_failed', { id: String(item._id), error: err.message });
    }
  }
  return sent;
}

/**
 * SP-61: marks years that have ended as `expired` and writes the plan back
 * to Free. Who has Pro is decided by the date on every read
 * (billing/combine.js), so this only makes the record say so; a missed run
 * can't leave anyone on Pro past the date. The locked-server guard follows
 * from the plan (billing/limits.js), as for a lapsed paid plan: nothing is
 * deleted, one server stays usable and the rest show as locked.
 */
async function expireEndedYears(now = new Date()) {
  const ended = await StudentVerification.find({
    status: 'approved',
    expiresAt: mongoose.trusted({ $lte: now }),
  }).select('_id userId expiresAt').lean();

  let expired = 0;
  for (const item of ended) {
    const changed = await StudentVerification.updateOne(
      { _id: item._id, status: 'approved' },
      { $set: { status: 'expired' } },
    );
    if (changed.modifiedCount === 0) continue;
    await writeSource(item.userId, 'student', {
      plan: 'free',
      status: 'expired',
      source: 'student',
      periodEnd: item.expiresAt,
      willRenew: false,
    }, { now });
    expired += 1;
  }
  return expired;
}

/** Runs every step once. Never throws. */
async function runAll(now = new Date()) {
  const summary = {};
  const steps = [
    ['documentsDeleted', 'purge_documents', purgeDecidedDocuments],
    ['supportScreenshotsDeleted', 'purge_support_screenshots', purgeSupportScreenshots],
    ['remindersSent', 'send_reminders', sendExpiryReminders],
    ['yearsExpired', 'expire_years', expireEndedYears],
  ];
  for (const [key, step, run] of steps) {
    try {
      summary[key] = await run(now);
    } catch (err) {
      logger.error('student.job_failed', { step, error: err.message });
    }
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

module.exports = {
  DOCUMENT_KEEP_DAYS,
  DAY_MS,
  REMINDER_DAYS,
  expireEndedYears,
  purgeDecidedDocuments,
  purgeSupportScreenshots,
  runAll,
  sendExpiryReminders,
  start,
  stop,
};
