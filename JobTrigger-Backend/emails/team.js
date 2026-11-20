/**
 * US-SUB-11 AC5: the invite. Plain text first; the HTML has one link, to the
 * website, and no images or tracking.
 */
const { escapeHtml } = require('./passwordReset');

function teamInviteEmail({ teamName, inviterEmail, link, days }) {
  const subject = `You're invited to ${teamName} on JobTrigger`;
  const text = [
    `${inviterEmail} invited you to the team "${teamName}" on JobTrigger.`,
    '',
    'Joining gives you JobTrigger Pro and the Jenkins servers the team shares.',
    '',
    `Accept the invite (it works for ${days} days): ${link}`,
    '',
    "If you weren't expecting this, ignore this email.",
  ].join('\n');
  const html = [
    '<!doctype html><html><body style="font-family:sans-serif;line-height:1.5">',
    `<p>${escapeHtml(inviterEmail)} invited you to the team <strong>${escapeHtml(teamName)}</strong> on JobTrigger.</p>`,
    '<p>Joining gives you JobTrigger Pro and the Jenkins servers the team shares.</p>',
    `<p><a href="${escapeHtml(link)}">Accept the invite</a> (it works for ${days} days).</p>`,
    "<p>If you weren't expecting this, ignore this email.</p>",
    '</body></html>',
  ].join('\n');
  return { subject, text, html };
}

module.exports = { teamInviteEmail };
