/**
 * Phase 21 emails: the one-time code to the student (SP-20) and the
 * notice to the owner for every application (SP-22). Plain text first;
 * the HTML has no images or tracking. The owner's email never carries the
 * document, only a link to the admin page.
 */
const { escapeHtml } = require('./passwordReset');

function studentCodeEmail({ code, minutes }) {
  const subject = 'Your JobTrigger student verification code';
  const text = [
    `Your JobTrigger verification code is ${code}.`,
    '',
    `It works for ${minutes} minutes. Enter it in the app or on the website to confirm this university email.`,
    '',
    "If you didn't ask for this, ignore this email.",
  ].join('\n');
  const html = [
    '<!doctype html><html><body style="font-family:sans-serif;line-height:1.5">',
    `<p>Your JobTrigger verification code is <strong style="font-size:1.4em;letter-spacing:.1em">${escapeHtml(code)}</strong>.</p>`,
    `<p>It works for ${minutes} minutes. Enter it in the app or on the website to confirm this university email.</p>`,
    "<p>If you didn't ask for this, ignore this email.</p>",
    '</body></html>',
  ].join('\n');
  return { subject, text, html };
}

/** The owner's notice. [fields] are plain values; none is a document. */
function studentApplicationEmail({ accountEmail, universityEmail, method, submittedAt, status, link }) {
  const methodLabel = method === 'email' ? 'University email code' : 'Student ID / enrolment letter';
  const subject = method === 'email'
    ? 'Student plan: verified by university email'
    : 'Student plan: new document to review';
  const lines = [
    ['Account', accountEmail],
    ['University email', universityEmail || '(not given)'],
    ['Method', methodLabel],
    ['Status', status],
    ['Submitted', new Date(submittedAt).toISOString()],
  ];
  const text = [
    ...lines.map(([k, v]) => `${k}: ${v}`),
    '',
    `Open in the admin page: ${link}`,
    '',
    'The document is not attached. View it on the admin page.',
  ].join('\n');
  const html = [
    '<!doctype html><html><body style="font-family:sans-serif;line-height:1.5">',
    '<ul>',
    ...lines.map(([k, v]) => `<li><strong>${escapeHtml(k)}:</strong> ${escapeHtml(v)}</li>`),
    '</ul>',
    `<p><a href="${escapeHtml(link)}">Open in the admin page</a></p>`,
    '<p>The document is not attached. View it on the admin page.</p>',
    '</body></html>',
  ].join('\n');
  return { subject, text, html };
}

module.exports = { studentCodeEmail, studentApplicationEmail };
