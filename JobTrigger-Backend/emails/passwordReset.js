/**
 * The password reset email (US-AUTH-08). One link, to the website: a
 * password is reset on the web only, never in the app. Plain text first;
 * the HTML part has no images, tracking pixels or remote content.
 */
const escapeHtml = (value) =>
  String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');

/** [resetUrl] already carries the token; [minutes] is how long it works. */
function passwordResetEmail({ resetUrl, minutes }) {
  const subject = 'Reset your JobTrigger password';
  const text = [
    'Someone asked to reset the password for your JobTrigger account.',
    '',
    'Choose a new password on the JobTrigger website:',
    resetUrl,
    '',
    `The link works once and expires in ${minutes} minutes.`,
    'Resetting signs you out on every device, including the app.',
    '',
    "If you didn't ask for this, ignore this email. Your password stays the same.",
  ].join('\n');

  const html = [
    '<!doctype html><html><body style="font-family:sans-serif;line-height:1.5">',
    '<p>Someone asked to reset the password for your JobTrigger account.</p>',
    `<p><a href="${escapeHtml(resetUrl)}">Choose a new password</a></p>`,
    `<p>The link works once and expires in ${minutes} minutes. Resetting signs you out on every device, including the app.</p>`,
    "<p>If you didn't ask for this, ignore this email. Your password stays the same.</p>",
    '</body></html>',
  ].join('\n');

  return { subject, text, html };
}

module.exports = { passwordResetEmail, escapeHtml };
