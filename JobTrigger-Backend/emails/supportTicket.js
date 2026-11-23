/**
 * Phase 25 (P25-04): the notification the owner receives for a new support
 * ticket. Plain text first; the HTML part has no images, tracking pixels or
 * remote content. The reply address is the user's, so replying in a mail
 * client reaches them without exposing anything else.
 *
 * Phase 31 adds the triage options and a screenshot count with a link to the
 * super-admin page. Image bytes are never attached to the email.
 */
const { escapeHtml } = require('./passwordReset');

const CATEGORY_LABELS = {
  bug: 'Bug',
  feature: 'Feature request',
  question: 'Question',
  tool_request: 'Tool request',
  account: 'Account & sign-in',
  billing: 'Billing & subscription',
  other: 'Something else',
};

const AREA_LABELS = {
  jenkins: 'Jenkins',
  github: 'GitHub Actions',
  sonarqube: 'SonarQube',
  website: 'Website',
  phone: 'Phone/app',
  account: 'Account',
};

function adminLink(ticket) {
  const path = `/admin/support/${ticket.id}`;
  const base = process.env.WEBSITE_BASE_URL?.trim().replace(/\/$/, '');
  return base ? `${base}${path}` : path;
}

function supportTicketEmail({ ticket, replyEmail }) {
  const category = CATEGORY_LABELS[ticket.category] ?? ticket.category;
  const subject = `[${category}] ${ticket.subject}`;
  const areas = (ticket.areas ?? []).map((area) => AREA_LABELS[area] ?? area);
  const options = [
    areas.length ? `Areas: ${areas.join(', ')}` : null,
    ticket.impact ? `Impact: ${ticket.impact}` : null,
  ].filter(Boolean);
  const diagnostics = [
    ticket.appVersion && `App ${ticket.appVersion}${ticket.buildNumber ? ` (${ticket.buildNumber})` : ''}`,
    ticket.tool && `Tool ${ticket.tool}`,
    ticket.platform && `Platform ${ticket.platform}`,
    ticket.serverHost && `Server ${ticket.serverHost}`,
  ].filter(Boolean);
  const shots = ticket.screenshotCount ?? 0;
  const screenshots = shots
    ? `${shots} screenshot${shots === 1 ? '' : 's'} attached — review at ${adminLink(ticket)}`
    : 'No screenshots attached.';

  const text = [
    `A new JobTrigger ${category.toLowerCase()} ticket was filed.`,
    '',
    `Ticket: ${ticket.id}`,
    `From: ${replyEmail}`,
    `Subject: ${ticket.subject}`,
    '',
    ticket.message,
    '',
    options.length ? `Options: ${options.join(' · ')}` : 'No extra options selected.',
    diagnostics.length ? `Diagnostics: ${diagnostics.join(' · ')}` : 'No diagnostics attached.',
    screenshots,
  ].join('\n');

  const html = [
    '<!doctype html><html><body style="font-family:sans-serif;line-height:1.5">',
    `<p>A new JobTrigger ${escapeHtml(category.toLowerCase())} ticket was filed.</p>`,
    `<p><strong>From:</strong> ${escapeHtml(replyEmail)}<br>`,
    `<strong>Ticket:</strong> ${escapeHtml(String(ticket.id))}<br>`,
    `<strong>Subject:</strong> ${escapeHtml(ticket.subject)}</p>`,
    `<pre style="white-space:pre-wrap;font-family:inherit">${escapeHtml(ticket.message)}</pre>`,
    `<p>${escapeHtml(
      options.length ? `Options: ${options.join(' · ')}` : 'No extra options selected.'
    )}</p>`,
    `<p>${escapeHtml(
      diagnostics.length ? `Diagnostics: ${diagnostics.join(' · ')}` : 'No diagnostics attached.'
    )}</p>`,
    `<p>${escapeHtml(screenshots)}</p>`,
    '</body></html>',
  ].join('\n');

  return { subject, text, html, replyTo: replyEmail };
}

module.exports = { supportTicketEmail, CATEGORY_LABELS, AREA_LABELS };
