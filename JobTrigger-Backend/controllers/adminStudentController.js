/**
 * Phase 21 (SP-31): the owner's review of student applications. Since the
 * owner decision of 2026-11-22 (US-STU-01) that is every application: a
 * verified university email waits here like a document, and only an
 * approval grants the year. Used by the website and the app (US-STU-02). Super admin
 * only (middleware/requireSuperAdmin.js), rate limited, and every action is
 * logged with the admin's and the application's ids (no names or emails).
 *
 * The document is only ever returned by `document`, to the website's server
 * with the admin's session, with `Cache-Control: no-store`. No URL for it
 * exists anywhere else, and lists never include it.
 */
const mongoose = require('mongoose');
const StudentVerification = require('../models/StudentVerification');
const User = require('../models/User');
const { decrypt } = require('../security/secretCipher');
const { claim, emailHash, grantStudentYear } = require('../lib/student');
const StudentClaim = require('../models/StudentClaim');
const { DAY_MS, DOCUMENT_KEEP_DAYS } = require('../lib/studentJobs');
const { logger } = require('../lib/logger');
const { studentRenewalEnabled } = require('../config/env');
const { DOCUMENT_FIELD } = require('./studentController');

const STATUSES = ['pending', 'approved', 'rejected', 'expired'];
const MAX_REASON_LENGTH = 500;
const PAGE = 50;

const escapeRegex = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

function view(v, user, reviewer) {
  return {
    id: String(v._id),
    userId: String(v.userId),
    accountEmail: user?.email ?? null,
    method: v.method,
    status: v.status,
    fullName: v.fullName ?? null,
    universityEmail: v.universityEmail ?? null,
    submittedAt: v.createdAt,
    emailVerifiedAt: v.emailVerifiedAt ?? null,
    reviewedAt: v.reviewedAt ?? null,
    reviewedBy: v.reviewedBy ? String(v.reviewedBy) : null,
    reviewedByEmail: reviewer?.email ?? null,
    approvedAt: v.approvedAt ?? null,
    expiresAt: v.expiresAt ?? null,
    rejectionReason: v.rejectionReason ?? null,
    documentMime: v.documentMime ?? null,
    documentSize: v.documentSize ?? null,
    hasDocument: Boolean(v.documentMime) && !v.documentDeletedAt,
    documentDeleted: Boolean(v.documentDeletedAt),
    documentDeleteAt: v.documentDeleteAt ?? null,
  };
}

const validId = (id) => mongoose.Types.ObjectId.isValid(id);

/** Adds the account and reviewer emails (US-STU-03) in one query. */
async function withUsers(records) {
  const ids = records.flatMap((r) => (r.reviewedBy ? [r.userId, r.reviewedBy] : [r.userId]));
  const users = await User.find({ _id: mongoose.trusted({ $in: ids }) }).select('email').lean();
  const byId = new Map(users.map((u) => [String(u._id), u]));
  return records.map((r) => view(r, byId.get(String(r.userId)), r.reviewedBy ? byId.get(String(r.reviewedBy)) : null));
}

/**
 * Filter for applications that a person can decide or has decided: a
 * pending email row is one only once its code was confirmed (US-STU-01).
 */
const isApplication = {
  $or: [
    { method: 'document' },
    { method: 'email', status: mongoose.trusted({ $ne: 'pending' }) },
    { method: 'email', emailVerifiedAt: mongoose.trusted({ $ne: null }) },
  ],
};

/** US-STU-02: lets the app know to show the review screen (the chain already 404s everyone else). */
exports.access = (req, res) => {
  res.set('Cache-Control', 'no-store');
  res.json({ role: 'superAdmin' });
};

/**
 * `?status=pending` (default) | approved | rejected | expired | all; `?q=`
 * account email, name or university email. Both methods, newest first
 * (US-STU-02, US-STU-03).
 */
exports.list = async (req, res, next) => {
  try {
    res.set('Cache-Control', 'no-store');
    const status = typeof req.query.status === 'string' ? req.query.status : 'pending';
    if (status !== 'all' && !STATUSES.includes(status)) {
      return res.status(400).json({ message: 'Unknown status' });
    }
    const q = typeof req.query.q === 'string' ? req.query.q.trim().slice(0, 100) : '';
    const and = [isApplication];
    if (status !== 'all') and.push({ status });
    if (q) {
      const pattern = new RegExp(escapeRegex(q), 'i');
      const matchedUsers = await User.find({ email: mongoose.trusted({ $regex: pattern }) }).select('_id').limit(200).lean();
      and.push({
        $or: [
          { userId: mongoose.trusted({ $in: matchedUsers.map((u) => u._id) }) },
          { fullName: mongoose.trusted({ $regex: pattern }) },
          { universityEmail: mongoose.trusted({ $regex: pattern }) },
        ],
      });
    }
    const records = await StudentVerification.find(mongoose.trusted({ $and: and }))
      .sort({ createdAt: -1, _id: -1 }).limit(PAGE).lean();
    res.json({ items: await withUsers(records) });
  } catch (err) {
    next(err);
  }
};

exports.get = async (req, res, next) => {
  try {
    res.set('Cache-Control', 'no-store');
    if (!validId(req.params.id)) return res.status(404).json({ message: 'Not found' });
    const record = await StudentVerification.findById(req.params.id).lean();
    if (!record) return res.status(404).json({ message: 'Not found' });
    const [item] = await withUsers([record]);
    res.json(item);
  } catch (err) {
    next(err);
  }
};

/** The document itself, for the website's server to pass on. */
exports.document = async (req, res, next) => {
  try {
    if (!validId(req.params.id)) return res.status(404).json({ message: 'Not found' });
    const record = await StudentVerification.findById(req.params.id).select('+documentData');
    if (!record || record.method !== 'document') return res.status(404).json({ message: 'Not found' });
    if (!record.documentData) {
      return res.status(410).json({ message: 'This document was deleted 30 days after the decision.' });
    }
    const bytes = Buffer.from(decrypt(record.documentData, DOCUMENT_FIELD), 'base64');
    logger.info('admin.student_document_viewed', { requestId: req.requestId, adminId: req.user.id, id: req.params.id });
    res.set({
      'Content-Type': record.documentMime,
      'Content-Length': String(bytes.length),
      'Cache-Control': 'no-store',
      'Content-Disposition': 'inline; filename="student-document"',
      'X-Content-Type-Options': 'nosniff',
      'Content-Security-Policy': "default-src 'none'; sandbox",
    });
    res.end(bytes);
  } catch (err) {
    next(err);
  }
};

exports.approve = async (req, res, next) => {
  try {
    if (!validId(req.params.id)) return res.status(404).json({ message: 'Not found' });
    const record = await StudentVerification.findById(req.params.id);
    if (!record) return res.status(404).json({ message: 'Not found' });
    if (record.status !== 'pending') {
      return res.status(409).json({ message: `This application is already ${record.status}.` });
    }
    if (record.method === 'email' && !record.emailVerifiedAt) {
      return res.status(409).json({ code: 'not_verified', message: 'This university email has not been verified yet.' });
    }
    // The email or document can only ever back one grant. If someone else
    // holds it, leave this one pending so the reviewer can reject it with
    // a reason.
    const { kind, hash, usedCode, usedMessage } = record.method === 'email'
      ? { kind: 'email', hash: emailHash(record.universityEmail), usedCode: 'email_used', usedMessage: 'That university email has already been used for a student plan.' }
      : { kind: 'document', hash: record.documentHash, usedCode: 'document_used', usedMessage: 'That document has already been used for a student plan.' };
    const claimed = await claim(kind, hash);
    if (!claimed && !(await ownsClaim(record))) {
      return res.status(409).json({ code: usedCode, message: usedMessage });
    }
    const now = new Date();
    const expiresAt = new Date(now.getTime() + 365 * DAY_MS);
    const done = await StudentVerification.findOneAndUpdate(
      { _id: record._id, status: 'pending' },
      {
        $set: {
          status: 'approved', approvedAt: now, expiresAt, reviewedAt: now, reviewedBy: req.user.id,
          ...(record.method === 'document'
            ? { documentDeleteAt: new Date(now.getTime() + DOCUMENT_KEEP_DAYS * DAY_MS) }
            : {}),
        },
      },
      { returnDocument: 'after' },
    );
    if (!done) {
      if (claimed) await StudentClaim.deleteOne({ kind, hash });
      return res.status(409).json({ message: 'This application was just decided by someone else.' });
    }
    await grantStudentYear(record.userId, now);
    logger.info('admin.student_approved', { requestId: req.requestId, adminId: req.user.id, id: String(record._id), method: record.method });
    const [item] = await withUsers([done.toObject()]);
    res.json(item);
  } catch (err) {
    next(err);
  }
};

/** With renewal on, the same person may re-use their own earlier email or document. */
async function ownsClaim(record) {
  if (!studentRenewalEnabled()) return false;
  const same = record.method === 'email'
    ? { universityEmail: record.universityEmail }
    : { documentHash: record.documentHash };
  return Boolean(await StudentVerification.exists({
    userId: record.userId, ...same, status: mongoose.trusted({ $in: ['approved', 'expired'] }), _id: mongoose.trusted({ $ne: record._id }),
  }));
}

exports.reject = async (req, res, next) => {
  try {
    if (!validId(req.params.id)) return res.status(404).json({ message: 'Not found' });
    const reason = typeof req.body?.reason === 'string' ? req.body.reason.trim() : '';
    if (!reason || reason.length > MAX_REASON_LENGTH) {
      return res.status(400).json({ message: `Give a reason (up to ${MAX_REASON_LENGTH} characters)` });
    }
    const record = await StudentVerification.findById(req.params.id).lean();
    if (!record) return res.status(404).json({ message: 'Not found' });
    if (record.method === 'email' && record.status === 'pending' && !record.emailVerifiedAt) {
      return res.status(409).json({ code: 'not_verified', message: 'This university email has not been verified yet.' });
    }
    const now = new Date();
    const done = await StudentVerification.findOneAndUpdate(
      { _id: record._id, status: 'pending' },
      {
        $set: {
          status: 'rejected', rejectionReason: reason, reviewedAt: now, reviewedBy: req.user.id,
          ...(record.method === 'document'
            ? { documentDeleteAt: new Date(now.getTime() + DOCUMENT_KEEP_DAYS * DAY_MS) }
            : {}),
        },
      },
      { returnDocument: 'after' },
    );
    if (!done) return res.status(409).json({ message: 'This application is already decided.' });
    logger.info('admin.student_rejected', { requestId: req.requestId, adminId: req.user.id, id: String(done._id) });
    const [item] = await withUsers([done.toObject()]);
    res.json(item);
  } catch (err) {
    next(err);
  }
};

