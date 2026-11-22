/**
 * Phase 21 (SP-31): the owner's review of student documents. Super admin
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
const { claim, grantStudentYear } = require('../lib/student');
const StudentClaim = require('../models/StudentClaim');
const { DAY_MS, DOCUMENT_KEEP_DAYS } = require('../lib/studentJobs');
const { logger } = require('../lib/logger');
const { studentRenewalEnabled } = require('../config/env');
const { DOCUMENT_FIELD } = require('./studentController');

const STATUSES = ['pending', 'approved', 'rejected', 'expired'];
const MAX_REASON_LENGTH = 500;
const PAGE = 50;

function view(v, user) {
  return {
    id: String(v._id),
    userId: String(v.userId),
    accountEmail: user?.email ?? null,
    method: v.method,
    status: v.status,
    fullName: v.fullName ?? null,
    universityEmail: v.universityEmail ?? null,
    submittedAt: v.createdAt,
    reviewedAt: v.reviewedAt ?? null,
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

async function withUsers(records) {
  const users = await User.find({ _id: mongoose.trusted({ $in: records.map((r) => r.userId) }) }).select('email').lean();
  const byId = new Map(users.map((u) => [String(u._id), u]));
  return records.map((r) => view(r, byId.get(String(r.userId))));
}

/**
 * `?status=pending` (default) | approved | rejected | expired | all; `?q=`
 * an exact account email (NFR-SEC-08: names and emails are
 * encrypted, so there is no partial or name search).
 */
exports.list = async (req, res, next) => {
  try {
    res.set('Cache-Control', 'no-store');
    const status = typeof req.query.status === 'string' ? req.query.status : 'pending';
    if (status !== 'all' && !STATUSES.includes(status)) {
      return res.status(400).json({ message: 'Unknown status' });
    }
    const q = typeof req.query.q === 'string' ? req.query.q.trim().slice(0, 100) : '';
    const filter = { method: 'document' };
    if (status !== 'all') filter.status = status;
    if (q) {
      // The review list holds document claims, which have no university
      // email, so the account email is the one to match.
      const matchedUsers = await User.find({ email: q }).select('_id').limit(200).lean();
      filter.userId = mongoose.trusted({ $in: matchedUsers.map((u) => u._id) });
    }
    const records = await StudentVerification.find(mongoose.trusted(filter)).sort({ createdAt: 1 }).limit(PAGE).lean();
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
    if (!record || record.method !== 'document') return res.status(404).json({ message: 'Not found' });
    if (record.status !== 'pending') {
      return res.status(409).json({ message: `This application is already ${record.status}.` });
    }
    // The document can only ever back one grant. If someone else holds it,
    // leave this one pending so the reviewer can reject it with a reason.
    const claimed = await claim('document', record.documentHash);
    if (!claimed && !(await ownsClaim(record))) {
      return res.status(409).json({ code: 'document_used', message: 'That document has already been used for a student plan.' });
    }
    const now = new Date();
    const expiresAt = new Date(now.getTime() + 365 * DAY_MS);
    const done = await StudentVerification.findOneAndUpdate(
      { _id: record._id, status: 'pending' },
      {
        $set: {
          status: 'approved', approvedAt: now, expiresAt, reviewedAt: now, reviewedBy: req.user.id,
          documentDeleteAt: new Date(now.getTime() + DOCUMENT_KEEP_DAYS * DAY_MS),
        },
      },
      { returnDocument: 'after' },
    );
    if (!done) {
      if (claimed) await StudentClaim.deleteOne({ kind: 'document', hash: record.documentHash });
      return res.status(409).json({ message: 'This application was just decided by someone else.' });
    }
    await grantStudentYear(record.userId, now);
    logger.info('admin.student_approved', { requestId: req.requestId, adminId: req.user.id, id: String(record._id) });
    const [item] = await withUsers([done.toObject()]);
    res.json(item);
  } catch (err) {
    next(err);
  }
};

/** With renewal on, the same person may re-use their own earlier document. */
async function ownsClaim(record) {
  return Boolean(await StudentVerification.exists({
    userId: record.userId, documentHash: record.documentHash, status: mongoose.trusted({ $in: ['approved', 'expired'] }), _id: mongoose.trusted({ $ne: record._id }),
  })) && studentRenewalEnabled();
}

exports.reject = async (req, res, next) => {
  try {
    if (!validId(req.params.id)) return res.status(404).json({ message: 'Not found' });
    const reason = typeof req.body?.reason === 'string' ? req.body.reason.trim() : '';
    if (!reason || reason.length > MAX_REASON_LENGTH) {
      return res.status(400).json({ message: `Give a reason (up to ${MAX_REASON_LENGTH} characters)` });
    }
    const now = new Date();
    const done = await StudentVerification.findOneAndUpdate(
      { _id: req.params.id, method: 'document', status: 'pending' },
      {
        $set: {
          status: 'rejected', rejectionReason: reason, reviewedAt: now, reviewedBy: req.user.id,
          documentDeleteAt: new Date(now.getTime() + DOCUMENT_KEEP_DAYS * DAY_MS),
        },
      },
      { returnDocument: 'after' },
    );
    if (!done) {
      const exists = await StudentVerification.exists({ _id: req.params.id, method: 'document' });
      return exists
        ? res.status(409).json({ message: 'This application is already decided.' })
        : res.status(404).json({ message: 'Not found' });
    }
    logger.info('admin.student_rejected', { requestId: req.requestId, adminId: req.user.id, id: String(done._id) });
    const [item] = await withUsers([done.toObject()]);
    res.json(item);
  } catch (err) {
    next(err);
  }
};

