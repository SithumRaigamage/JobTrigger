/**
 * Phase 25 (P25-01/P25-02): support and issue tickets.
 *
 * - Every route needs a session; a ticket always belongs to the caller, so
 *   one account can never read another's report.
 * - Subject and message are validated, control characters stripped, then run
 *   through the crash-reporting scrubber, so a pasted Jenkins token or a URL
 *   with a query string never reaches the database.
 * - `serverHost` is rebuilt from the URL and keeps only scheme+host+port: no
 *   path, no query, no credentials.
 * - The notification email is best effort: a mail failure is logged and the
 *   ticket is still created (201).
 * - Phase 31 adds triage options and up to three screenshots. Image bytes are
 *   checked by magic number (never the file name), encrypted at rest and
 *   decrypted only by the super-admin screenshot route.
 */
const crypto = require('crypto');
const SupportTicket = require('../models/SupportTicket');
const AppInfo = require('../models/AppInfo');
const User = require('../models/User');
const { CATEGORIES, AREAS, IMPACTS, STATUSES } = require('../models/SupportTicket');
const { scrubString } = require('../lib/errorReporting/scrub');
const { inspectDocument } = require('../lib/studentDocument');
const { encrypt, decrypt } = require('../security/secretCipher');
const { sendMail } = require('../lib/mailer');
const { supportTicketEmail } = require('../emails/supportTicket');
const { logger } = require('../lib/logger');

const MAX_SUBJECT = 120;
const MAX_MESSAGE = 4000;
const MAX_SHORT = 40;
const MAX_EMAIL = 254;
const LIST_LIMIT = 20;
const ADMIN_LIMIT = 100;
const MAX_SCREENSHOTS = 3;
const SCREENSHOT_KEEP_DAYS = 30;
const SCREENSHOT_FIELD = 'supportScreenshot';

/** Trimmed, scrubbed text with control characters replaced by spaces. */
function cleanText(value, max) {
  if (typeof value !== 'string') return '';
  return scrubString(value)
    // eslint-disable-next-line no-control-regex
    .replace(/[\u0000-\u001f\u007f]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
    .slice(0, max);
}

/** The message keeps its line breaks; only the control characters go. */
function cleanMessage(value, max) {
  if (typeof value !== 'string') return '';
  return scrubString(value)
    // eslint-disable-next-line no-control-regex
    .replace(/[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f]/g, '')
    .trim()
    .slice(0, max);
}

function short(value) {
  const text = cleanText(value, MAX_SHORT);
  return text || undefined;
}

/** scheme://host[:port] from any URL, or null. Never a path or credentials. */
function hostOnly(value) {
  if (typeof value !== 'string' || !value.trim()) return null;
  try {
    const url = new URL(value.trim());
    if (url.protocol !== 'http:' && url.protocol !== 'https:') return null;
    return `${url.protocol}//${url.host}`.slice(0, 200);
  } catch {
    return null;
  }
}

/** Optional multi-select areas; `null` means the caller sent something invalid. */
function parseAreas(value) {
  if (value === undefined || value === null) return [];
  if (!Array.isArray(value) || value.length > AREAS.length) return null;
  const unique = [...new Set(value)];
  if (unique.some((area) => !AREAS.includes(area))) return null;
  return unique;
}

/** Screenshots arrive as base64 in JSON, like student documents (SP-30). */
function parseScreenshots(value) {
  if (value === undefined || value === null) return { files: [], error: null };
  if (!Array.isArray(value)) {
    return { files: [], error: { status: 400, message: 'Screenshots must be a list.' } };
  }
  if (value.length > MAX_SCREENSHOTS) {
    return { files: [], error: { status: 400, message: `Attach at most ${MAX_SCREENSHOTS} screenshots.` } };
  }
  const files = [];
  for (let index = 0; index < value.length; index += 1) {
    const item = value[index];
    const checked = inspectDocument(item?.data);
    if (checked.error) {
      const message = checked.error.status === 415
        ? 'Screenshots must be JPG or PNG images.'
        : checked.error.message;
      return { files: [], error: { status: checked.error.status, message } };
    }
    if (checked.mime === 'application/pdf') {
      return { files: [], error: { status: 415, message: 'Screenshots must be JPG or PNG images.' } };
    }
    files.push({
      data: encrypt(checked.bytes.toString('base64'), SCREENSHOT_FIELD),
      mime: checked.mime,
      size: checked.bytes.length,
      hash: crypto.createHash('sha256').update(checked.bytes).digest('hex'),
      deleteAt: new Date(Date.now() + SCREENSHOT_KEEP_DAYS * 24 * 60 * 60 * 1000),
    });
  }
  return { files, error: null };
}

function screenshotCount(ticket) {
  if (Array.isArray(ticket.screenshots)) return ticket.screenshots.length;
  return 0;
}

function publicTicket(ticket) {
  return {
    id: String(ticket._id ?? ticket.id),
    category: ticket.category,
    subject: ticket.subject,
    message: ticket.message,
    areas: ticket.areas ?? [],
    impact: ticket.impact ?? 'minor',
    screenshotCount: screenshotCount(ticket),
    status: ticket.status,
    createdAt: ticket.createdAt,
    updatedAt: ticket.updatedAt,
  };
}

function adminTicket(ticket, detail = false) {
  const base = {
    ...publicTicket(ticket),
    replyEmail: ticket.replyEmail,
    userEmail: ticket.userId?.email ?? null,
    appVersion: ticket.appVersion ?? null,
    buildNumber: ticket.buildNumber ?? null,
    tool: ticket.tool ?? null,
    platform: ticket.platform ?? null,
    serverHost: ticket.serverHost ?? null,
  };
  if (!detail) return base;
  return {
    ...base,
    screenshots: (ticket.screenshots ?? []).map((shot, index) => ({
      index,
      mime: shot.mime,
      size: shot.size,
      hash: shot.hash,
      createdAt: shot.createdAt ?? null,
      deletedAt: shot.deletedAt ?? null,
    })),
  };
}

async function notifyOwner(ticket, replyEmail, requestId) {
  try {
    const info = await AppInfo.findOne().select('supportEmail').lean();
    if (!info?.supportEmail) return;
    const message = supportTicketEmail({
      ticket: {
        ...publicTicket(ticket),
        appVersion: ticket.appVersion,
        buildNumber: ticket.buildNumber,
        tool: ticket.tool,
        platform: ticket.platform,
        serverHost: ticket.serverHost,
      },
      replyEmail,
    });
    await sendMail({ to: info.supportEmail, ...message, kind: 'support_ticket' });
  } catch (err) {
    // The ticket is stored; the email is the secondary path.
    logger.error('support.notify_failed', { requestId, error: err.message });
  }
}

// @desc    File a support ticket
// @route   POST /api/support/tickets
// @access  Private
exports.createTicket = async (req, res, next) => {
  try {
    const body = req.body ?? {};
    const category = body.category;
    if (!CATEGORIES.includes(category)) {
      return res.status(400).json({ message: 'Choose what kind of report this is.' });
    }
    if (typeof body.subject !== 'string' || !body.subject.trim()) {
      return res.status(400).json({ message: 'A subject is required.' });
    }
    if (body.subject.trim().length > MAX_SUBJECT) {
      return res.status(400).json({ message: `Keep the subject under ${MAX_SUBJECT} characters.` });
    }
    if (typeof body.message !== 'string' || !body.message.trim()) {
      return res.status(400).json({ message: 'Describe the issue or request.' });
    }
    if (body.message.trim().length > MAX_MESSAGE) {
      return res.status(400).json({ message: `Keep the message under ${MAX_MESSAGE} characters.` });
    }

    const areas = parseAreas(body.areas);
    if (areas === null) {
      return res.status(400).json({ message: 'Choose only known affected areas.' });
    }
    const impact = body.impact ?? 'minor';
    if (!IMPACTS.includes(impact)) {
      return res.status(400).json({ message: 'Choose a known impact.' });
    }
    const screenshots = parseScreenshots(body.screenshots);
    if (screenshots.error) {
      return res.status(screenshots.error.status).json({ message: screenshots.error.message });
    }

    const account = await User.findById(req.user.id).select('email').lean();
    const replyEmail = cleanText(body.replyEmail, MAX_EMAIL).toLowerCase() || account?.email;
    if (!replyEmail || !replyEmail.includes('@')) {
      return res.status(400).json({ message: 'A reply email is required.' });
    }

    const ticket = await SupportTicket.create({
      userId: req.user.id,
      category,
      subject: cleanText(body.subject, MAX_SUBJECT),
      message: cleanMessage(body.message, MAX_MESSAGE),
      replyEmail,
      appVersion: short(body.appVersion),
      buildNumber: short(body.buildNumber),
      tool: short(body.tool),
      platform: short(body.platform),
      serverHost: hostOnly(body.serverHost) ?? undefined,
      areas,
      impact,
      screenshots: screenshots.files,
    });

    logger.info('support.ticket_created', {
      requestId: req.requestId,
      ticketId: String(ticket.id),
      screenshots: screenshots.files.length,
    });
    await notifyOwner(ticket, replyEmail, req.requestId);

    return res.status(201).json({ ticket: publicTicket(ticket) });
  } catch (err) {
    return next(err);
  }
};

// @desc    The caller's own tickets, newest first
// @route   GET /api/support/tickets
// @access  Private
exports.listMyTickets = async (req, res, next) => {
  try {
    const tickets = await SupportTicket.find({ userId: req.user.id })
      .sort({ createdAt: -1 })
      .limit(LIST_LIMIT)
      .lean();
    return res.json({ tickets: tickets.map(publicTicket) });
  } catch (err) {
    return next(err);
  }
};

// @desc    Every ticket, newest first (super admin only)
// @route   GET /api/admin/support/tickets
// @access  Private (superAdmin)
exports.listAllTickets = async (req, res, next) => {
  try {
    const filter = {};
    if (STATUSES.includes(req.query.status)) filter.status = req.query.status;
    const tickets = await SupportTicket.find(filter)
      .sort({ createdAt: -1 })
      .limit(ADMIN_LIMIT)
      .populate('userId', 'email')
      .lean();
    return res.json({ tickets: tickets.map((ticket) => adminTicket(ticket)) });
  } catch (err) {
    return next(err);
  }
};

// @desc    One ticket with screenshot metadata (super admin only)
// @route   GET /api/admin/support/tickets/:id
// @access  Private (superAdmin)
exports.getTicket = async (req, res, next) => {
  try {
    const ticket = await SupportTicket.findById(req.params.id)
      .populate('userId', 'email')
      .lean();
    if (!ticket) return res.status(404).json({ message: 'Not found' });
    return res.json({ ticket: adminTicket(ticket, true) });
  } catch (err) {
    if (err.name === 'CastError') return res.status(404).json({ message: 'Not found' });
    return next(err);
  }
};

// @desc    One screenshot's raw bytes, decrypted on demand (super admin only)
// @route   GET /api/admin/support/tickets/:id/screenshots/:index
// @access  Private (superAdmin)
exports.getScreenshot = async (req, res, next) => {
  try {
    const index = Number(req.params.index);
    if (!Number.isInteger(index) || index < 0) {
      return res.status(404).json({ message: 'Not found' });
    }
    const ticket = await SupportTicket.findById(req.params.id).select('+screenshots.data');
    const shot = ticket?.screenshots?.[index];
    if (!shot?.data || shot.deletedAt) return res.status(404).json({ message: 'Not found' });
    const bytes = Buffer.from(decrypt(shot.data, SCREENSHOT_FIELD), 'base64');
    return res
      .set('Content-Type', shot.mime)
      .set('Cache-Control', 'no-store')
      .send(bytes);
  } catch (err) {
    if (err.name === 'CastError') return res.status(404).json({ message: 'Not found' });
    return next(err);
  }
};

// @desc    Move a ticket to triaged or closed (super admin only)
// @route   PATCH /api/admin/support/tickets/:id
// @access  Private (superAdmin)
exports.updateTicketStatus = async (req, res, next) => {
  try {
    const { status } = req.body ?? {};
    if (!STATUSES.includes(status)) {
      return res.status(400).json({ message: 'Unknown status.' });
    }
    const ticket = await SupportTicket.findByIdAndUpdate(
      req.params.id,
      { status },
      { returnDocument: 'after' }
    ).lean();
    if (!ticket) return res.status(404).json({ message: 'Not found' });
    logger.info('support.ticket_status', { requestId: req.requestId, ticketId: String(ticket._id), status });
    return res.json({ ticket: publicTicket(ticket) });
  } catch (err) {
    // A malformed id is a 404, not a 500.
    if (err.name === 'CastError') return res.status(404).json({ message: 'Not found' });
    return next(err);
  }
};