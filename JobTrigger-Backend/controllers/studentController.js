/**
 * Phase 21 (SP-2): the student plan's email path. A signed-in user gives a
 * university email on the allowed list, gets a 6-digit code there, and the
 * right code grants a year of Pro at once (no review).
 *
 * - The code lives 10 minutes, is stored only as a salted hash, and allows
 *   5 wrong tries; a new code starts a fresh count (the start route is
 *   rate limited, so the total guesses per hour stay small).
 * - One grant per person, ever (decision): approved or expired applications
 *   block a new one unless STUDENT_RENEWAL_ENABLED, and the university
 *   email is claimed for good (models/StudentClaim.js).
 * - Never logs an email address or a code.
 */
const crypto = require('crypto');
const mongoose = require('mongoose');
const StudentVerification = require('../models/StudentVerification');
const User = require('../models/User');
const { sendMail } = require('../lib/mailer');
const { logger } = require('../lib/logger');
const { siteUrl, studentAdminEmail, studentRenewalEnabled } = require('../config/env');
const { studentCodeEmail, studentApplicationEmail } = require('../emails/student');
const {
  DAY_MS,
  GRANT_DAYS,
  claim,
  emailHash,
  grantStudentYear,
  isClaimed,
  isListedUniversityEmail,
  sha256,
} = require('../lib/student');

const CODE_MINUTES = 10;
const MAX_ATTEMPTS = 5;
const MAX_EMAIL_LENGTH = 254;
const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

const hashCode = (salt, code) => sha256(`${salt}:${code}`);

/** Whether [a] and [b] are equal hex digests, in constant time. */
function sameDigest(a, b) {
  const x = Buffer.from(a, 'hex');
  const y = Buffer.from(b, 'hex');
  return x.length === y.length && crypto.timingSafeEqual(x, y);
}

/** Why [userId] can't start a new application, or null. */
async function applicationBlock(userId) {
  const records = await StudentVerification.find({ userId }).lean();
  if (records.some((r) => r.status === 'pending' && r.method === 'document')) {
    return { status: 409, code: 'under_review', message: 'Your student document is already waiting for review.' };
  }
  const granted = records.find((r) => r.status === 'approved' || r.status === 'expired');
  if (granted) {
    const active = records.some((r) => r.status === 'approved');
    if (active || !studentRenewalEnabled()) {
      return {
        status: 409,
        code: 'already_used',
        message: active
          ? 'You already have a student year.'
          : 'The student plan is one year per person and yours has been used.',
      };
    }
  }
  return null;
}

/** Tells the owner about [verification] (SP-22). Never throws. */
async function notifyOwner(verification, user) {
  const to = studentAdminEmail();
  if (!to) {
    logger.info('student.owner_notice_skipped', { reason: 'STUDENT_ADMIN_EMAIL unset' });
    return;
  }
  try {
    const message = studentApplicationEmail({
      accountEmail: user.email,
      universityEmail: verification.universityEmail,
      method: verification.method,
      submittedAt: verification.createdAt ?? new Date(),
      status: verification.status,
      link: `${siteUrl()}/admin/students/${verification._id}`,
    });
    await sendMail({ to, ...message, kind: 'student_application' });
  } catch (err) {
    logger.warn('student.owner_notice_failed', { error: err.message });
  }
}

const publicView = (v) => ({
  id: String(v._id),
  method: v.method,
  status: v.status,
  universityEmail: v.universityEmail ?? null,
  rejectionReason: v.rejectionReason ?? null,
  submittedAt: v.createdAt,
  approvedAt: v.approvedAt ?? null,
  expiresAt: v.expiresAt ?? null,
});

/** The signed-in user's latest application, or `{ status: 'none' }`. */
exports.status = async (req, res, next) => {
  try {
    res.set('Cache-Control', 'no-store');
    const latest = await StudentVerification.findOne({ userId: req.user.id }).sort({ createdAt: -1 }).lean();
    res.json(latest ? publicView(latest) : { status: 'none' });
  } catch (err) {
    next(err);
  }
};

exports.emailStart = async (req, res, next) => {
  try {
    const raw = req.body?.universityEmail;
    if (typeof raw !== 'string' || !raw.trim()) {
      return res.status(400).json({ message: 'Enter your university email' });
    }
    const universityEmail = raw.trim().toLowerCase();
    if (universityEmail.length > MAX_EMAIL_LENGTH || !EMAIL_PATTERN.test(universityEmail)) {
      return res.status(400).json({ message: 'Enter a valid email address' });
    }
    const block = await applicationBlock(req.user.id);
    if (block) return res.status(block.status).json({ code: block.code, message: block.message });

    if (!isListedUniversityEmail(universityEmail)) {
      return res.status(400).json({
        code: 'domain_not_listed',
        message: "We can't verify that email domain automatically. Upload a student ID or enrolment letter instead.",
      });
    }
    if (await emailTakenByAnother(req.user.id, universityEmail)) {
      return res.status(409).json({
        code: 'email_used',
        message: 'That university email has already been used for a student plan.',
      });
    }

    const code = String(crypto.randomInt(0, 1000000)).padStart(6, '0');
    const salt = crypto.randomBytes(16).toString('hex');
    const fields = {
      universityEmail,
      codeSalt: salt,
      codeHash: hashCode(salt, code),
      codeExpiresAt: new Date(Date.now() + CODE_MINUTES * 60 * 1000),
      codeAttempts: 0,
    };
    const existing = await StudentVerification.findOne({
      userId: req.user.id, method: 'email', status: 'pending',
    });
    if (existing) {
      existing.set(fields);
      await existing.save();
    } else {
      await StudentVerification.create({ userId: req.user.id, method: 'email', status: 'pending', ...fields });
    }

    let sent;
    try {
      ({ sent } = await sendMail({ to: universityEmail, ...studentCodeEmail({ code, minutes: CODE_MINUTES }), kind: 'student_code' }));
    } catch {
      sent = false;
    }
    if (!sent) {
      return res.status(503).json({ message: "We couldn't send the code right now. Try again in a few minutes." });
    }
    logger.info('student.code_sent', { requestId: req.requestId, userId: req.user.id });
    res.status(202).json({
      message: `We sent a code to ${universityEmail}. It works for ${CODE_MINUTES} minutes.`,
      expiresInMinutes: CODE_MINUTES,
    });
  } catch (err) {
    next(err);
  }
};

/**
 * True when [universityEmail] was used for a grant by someone else. With
 * renewal on, the same person may use their own earlier email again.
 */
async function emailTakenByAnother(userId, universityEmail) {
  if (!(await isClaimed('email', emailHash(universityEmail)))) return false;
  if (!studentRenewalEnabled()) return true;
  const own = await StudentVerification.exists({ userId, universityEmail, status: mongoose.trusted({ $in: ['approved', 'expired'] }) });
  return !own;
}

exports.emailConfirm = async (req, res, next) => {
  try {
    const code = req.body?.code;
    if (typeof code !== 'string' || !/^\d{6}$/.test(code.trim())) {
      return res.status(400).json({ message: 'Enter the 6-digit code' });
    }
    const record = await StudentVerification.findOne({
      userId: req.user.id, method: 'email', status: 'pending',
    }).select('+codeSalt +codeHash');
    if (!record?.codeHash) {
      return res.status(400).json({ code: 'no_code', message: 'Ask for a new code first.' });
    }
    if (!record.codeExpiresAt || record.codeExpiresAt <= new Date()) {
      return res.status(400).json({ code: 'code_expired', message: 'That code has expired. Ask for a new one.' });
    }
    // $lt is ours, not the client's (sanitizeFilter, AUD-04), so it is trusted.
    // Count the try first, atomically, so parallel guesses can't beat the limit.
    const counted = await StudentVerification.findOneAndUpdate(
      { _id: record._id, status: 'pending', codeAttempts: mongoose.trusted({ $lt: MAX_ATTEMPTS }) },
      { $inc: { codeAttempts: 1 } },
      { returnDocument: 'after' },
    );
    if (!counted) {
      return res.status(429).json({
        code: 'too_many_attempts',
        message: 'Too many wrong codes. Ask for a new code.',
      });
    }
    if (!sameDigest(hashCode(record.codeSalt, code.trim()), record.codeHash)) {
      const left = MAX_ATTEMPTS - counted.codeAttempts;
      return res.status(400).json({
        code: 'wrong_code',
        message: left > 0 ? `That code is not right. ${left} ${left === 1 ? 'try' : 'tries'} left.` : 'That code is not right. Ask for a new code.',
      });
    }

    const now = new Date();
    const expiresAt = new Date(now.getTime() + GRANT_DAYS * DAY_MS);
    // Atomic: two confirms with the right code can't both approve.
    const approved = await StudentVerification.findOneAndUpdate(
      { _id: record._id, status: 'pending' },
      {
        $set: { status: 'approved', approvedAt: now, expiresAt, reviewedAt: now, codeExpiresAt: null },
        $unset: { codeHash: '', codeSalt: '' },
      },
      { returnDocument: 'after' },
    );
    if (!approved) return res.status(400).json({ code: 'no_code', message: 'Ask for a new code first.' });

    const hash = emailHash(approved.universityEmail);
    const ownPrior = await StudentVerification.exists({
      userId: req.user.id, universityEmail: approved.universityEmail, status: mongoose.trusted({ $in: ['approved', 'expired'] }), _id: mongoose.trusted({ $ne: approved._id }),
    });
    if (!(await claim('email', hash)) && !(studentRenewalEnabled() && ownPrior)) {
      await StudentVerification.updateOne(
        { _id: approved._id },
        { $set: { status: 'rejected', rejectionReason: 'This university email was already used.' }, $unset: { approvedAt: '', expiresAt: '' } },
      );
      return res.status(409).json({
        code: 'email_used',
        message: 'That university email has already been used for a student plan.',
      });
    }

    await grantStudentYear(req.user.id, now);
    const user = await User.findById(req.user.id).lean();
    await notifyOwner(approved, user);
    logger.info('student.approved', { requestId: req.requestId, userId: req.user.id, method: 'email' });
    res.json(publicView(approved));
  } catch (err) {
    next(err);
  }
};

exports.applicationBlock = applicationBlock;
exports.notifyOwner = notifyOwner;
exports.publicView = publicView;
exports.CODE_MINUTES = CODE_MINUTES;
exports.MAX_ATTEMPTS = MAX_ATTEMPTS;
