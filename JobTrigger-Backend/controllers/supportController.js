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
 */
const SupportTicket = require('../models/SupportTicket');
const AppInfo = require('../models/AppInfo');
const User = require('../models/User');
const { CATEGORIES, STATUSES } = require('../models/SupportTicket');
const { scrubString } = require('../lib/errorReporting/scrub');
const { sendMail } = require('../lib/mailer');
const { supportTicketEmail } = require('../emails/supportTicket');
const { logger } = require('../lib/logger');

const MAX_SUBJECT = 120;
const MAX_MESSAGE = 4000;
const MAX_SHORT = 40;
const MAX_EMAIL = 254;
const LIST_LIMIT = 20;
const ADMIN_LIMIT = 100;

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

function publicTicket(ticket) {
  return {
    id: String(ticket._id ?? ticket.id),
    category: ticket.category,
    subject: ticket.subject,
    message: ticket.message,
    status: ticket.status,
    createdAt: ticket.createdAt,
    updatedAt: ticket.updatedAt,
  };
}

async function notifyOwner(ticket, replyEmail, requestId) {
  try {
    const info = await AppInfo.findOne().select('supportEmail').lean();
    if (!info?.supportEmail) return;
    const message = supportTicketEmail({ ticket, replyEmail });
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
    });

    logger.info('support.ticket_created', { requestId: req.requestId, ticketId: String(ticket.id) });
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
    return res.json({
      tickets: tickets.map((ticket) => ({
        ...publicTicket(ticket),
        replyEmail: ticket.replyEmail,
        userEmail: ticket.userId?.email ?? null,
        appVersion: ticket.appVersion ?? null,
        buildNumber: ticket.buildNumber ?? null,
        tool: ticket.tool ?? null,
        platform: ticket.platform ?? null,
        serverHost: ticket.serverHost ?? null,
      })),
    });
  } catch (err) {
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