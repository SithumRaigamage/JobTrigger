/**
 * P20-72: outgoing email over SMTP (nodemailer). The provider is only
 * configuration: Mailpit in development (the DevOps lab's `mailpit/`,
 * localhost:1025), a real provider once the backend is deployed.
 *
 * - Unconfigured (no SMTP_HOST) means mail is off: sendMail logs
 *   `mail.disabled` and returns `{ sent: false }`, it never throws for it.
 * - A send that fails is logged and rethrown; callers decide whether the
 *   request fails (password reset doesn't — see passwordResetController).
 * - Never log a recipient, a subject's personal parts, or a body: they
 *   can carry reset links. The message id is enough to trace a send.
 */
const nodemailer = require('nodemailer');
const { mailConfig } = require('../config/env');
const { logger } = require('./logger');

let transport = null;
let testTransport = null;

/** Tests: an object with `sendMail(message)`, or null to restore. */
function setTransportForTests(fake) {
  testTransport = fake;
}

function currentTransport(config) {
  if (testTransport) return testTransport;
  if (!config) return null;
  if (!transport) {
    transport = nodemailer.createTransport({
      host: config.host,
      port: config.port,
      secure: config.secure,
      ...(config.user ? { auth: { user: config.user, pass: config.pass } } : {}),
    });
  }
  return transport;
}

/** Sends one email. `kind` names the email in logs (e.g. `password_reset`). */
async function sendMail({ to, subject, text, html, kind }) {
  const config = mailConfig();
  const active = currentTransport(config);
  if (!active) {
    logger.info('mail.disabled', { kind });
    return { sent: false };
  }
  try {
    const info = await active.sendMail({
      from: config?.from ?? 'JobTrigger <no-reply@jobtrigger.local>',
      to,
      subject,
      text,
      html,
    });
    logger.info('mail.sent', { kind, messageId: info?.messageId });
    return { sent: true };
  } catch (err) {
    logger.error('mail.failed', { kind, error: err.message });
    throw err;
  }
}

module.exports = { sendMail, setTransportForTests };
