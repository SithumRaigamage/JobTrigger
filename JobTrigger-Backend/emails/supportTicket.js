/**
 * Phase 25 (P25-04): the notification the owner receives for a new support
 * ticket. Plain text first; the HTML part has no images, tracking pixels or
 * remote content. The reply address is the user's, so replying in a mail
 * client reaches them without exposing anything else.
 */
const { escapeHtml } = require('./passwordReset');

const CATEGORY_LABELS = {
  bug: 'Bug',
  feature: 'Feature request',
  question: 'Question',
  tool_request: 'Tool request',
};

function supportTicketEmail({ ticket, replyEmail }) {
  const category = CATEGORY_LABELS[ticket.category] ?? ticket.category;
  const subject = `[${category}] ${ticket.subject}`;
  const diagnostics = [
    ticket.appVersion && `App ${ticket.appVersion}${ticket.buildNumber ? ` (${ticket.buildNumber})` : ''}`,
    ticket.tool && `Tool ${ticket.tool}`,
    ticket.platform && `Platform ${ticket.platform}`,
    ticket.serverHost && `Server ${ticket.serverHost}`,
  ].filter(Boolean);

  const text = [
    `A new JobTrigger ${category.toLowerCase()} ticket was filed.`,
    '',
    `Ticket: ${ticket.id}`,
    `From: ${replyEmail}`,
    `Subject: ${ticket.subject}`,
    '',
    ticket.message,
    '',
    diagnostics.length ? `Diagnostics: ${diagnostics.join(' · ')}` : 'No diagnostics attached.',
  ].join('\n');

  const html = [
    '<!doctype html><html><body style="font-family:sans-serif;line-height:1.5">',
    `<p>A new JobTrigger ${escapeHtml(category.toLowerCase())} ticket was filed.</p>`,
    `<p><strong>From:</strong> ${escapeHtml(replyEmail)}<br>`,
    `<strong>Ticket:</strong> ${escapeHtml(ticket.id)}<br>`,
    `<strong>Subject:</strong> ${escapeHtml(ticket.subject)}</p>`,
    `<pre style="white-space:pre-wrap;font-family:inherit">${escapeHtml(ticket.message)}</pre>`,
    `<p>${escapeHtml(
      diagnostics.length ? `Diagnostics: ${diagnostics.join(' · ')}` : 'No diagnostics attached.'
    )}</p>`,
    '</body></html>',
  ].join('\n');

  return { subject, text, html, replyTo: replyEmail };
}

module.exports = { supportTicketEmail, CATEGORY_LABELS };