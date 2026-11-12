/**
 * The password reset email (US-AUTH-08). Plain text first; the HTML part
 * has no images, tracking pixels or remote content.
 */
const escapeHtml = (value) =>
  String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');

/**
 * [webUrl] (may be null when the website isn't configured) and [appUrl]
 * already carry the token. [minutes] is how long they stay valid.
 */
function passwordResetEmail({ webUrl, appUrl, minutes }) {
  const subject = 'Reset your JobTrigger password';
  const lines = [
    'Someone asked to reset the password for your JobTrigger account.',
    '',
    ...(webUrl ? ['Reset it in your browser:', webUrl, ''] : []),
    'Or open this link on the phone where JobTrigger is installed:',
    appUrl,
    '',
    `The link works once and expires in ${minutes} minutes.`,
    'Resetting signs you out on every device.',
    '',
    "If you didn't ask for this, ignore this email. Your password stays the same.",
  ];
  const text = lines.join('\n');

  const link = (url, label) =>
    `<p><a href="${escapeHtml(url)}">${escapeHtml(label)}</a></p>`;
  const html = [
    '<!doctype html><html><body style="font-family:sans-serif;line-height:1.5">',
    '<p>Someone asked to reset the password for your JobTrigger account.</p>',
    ...(webUrl ? [link(webUrl, 'Reset your password')] : []),
    `<p>On the phone where JobTrigger is installed:</p>${link(appUrl, 'Open in the JobTrigger app')}`,
    `<p>The link works once and expires in ${minutes} minutes. Resetting signs you out on every device.</p>`,
    "<p>If you didn't ask for this, ignore this email. Your password stays the same.</p>",
    '</body></html>',
  ].join('\n');

  return { subject, text, html };
}

module.exports = { passwordResetEmail, escapeHtml };
