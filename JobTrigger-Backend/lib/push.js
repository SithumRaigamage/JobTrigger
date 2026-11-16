/**
 * NR-06 (BACKLOG-02): server push — the backend half.
 *
 * - Off unless FCM_SERVICE_ACCOUNT holds a Firebase service account, so
 *   tests and local development never send anything: sendToUser() is a no-op.
 * - Firebase Cloud Messaging over its HTTP v1 API, with a self-signed RS256
 *   JWT exchanged for an access token. No SDK and no new dependency; both
 *   stores deliver through FCM (APNs through Firebase's APNs key).
 * - Never throws to a caller: a push failure is logged, never an API error.
 *   A token FCM reports as unregistered is deleted, so it stops being tried.
 * - No personal data in a payload: a job's name may already be in the title
 *   the caller passes; never add a URL, token or email here.
 */
const crypto = require('node:crypto');

const DeviceToken = require('../models/DeviceToken');
const { pushConfig } = require('../config/env');
const { logger } = require('./logger');

const FCM_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';
const TOKEN_URL = 'https://oauth2.googleapis.com/token';
const SEND_URL = 'https://fcm.googleapis.com/v1/projects';
const TIMEOUT_MS = 5000;

let testSender = null;
let cachedToken = null;

/** Tests: `async (token, message) => void`, or null to restore the real path. */
function setSenderForTests(fake) {
  testSender = fake;
  cachedToken = null;
}

/** Whether a push could actually be delivered right now. */
function pushesEnabled() {
  return testSender !== null || pushConfig() !== null;
}

const base64url = (value) => Buffer.from(value).toString('base64url');

/** The OAuth2 assertion FCM's token endpoint accepts. */
function signedAssertion(config, now = Math.floor(Date.now() / 1000)) {
  const header = base64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const claims = base64url(JSON.stringify({
    iss: config.clientEmail,
    scope: FCM_SCOPE,
    aud: TOKEN_URL,
    iat: now,
    exp: now + 3600
  }));
  const signer = crypto.createSign('RSA-SHA256');
  signer.update(`${header}.${claims}`);
  return `${header}.${claims}.${signer.sign(config.privateKey, 'base64url')}`;
}

/** An access token, reused until it is close to expiry. */
async function accessToken(config) {
  if (cachedToken && cachedToken.expiresAt > Date.now() + 60000) return cachedToken.value;

  const response = await fetch(TOKEN_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: signedAssertion(config)
    }),
    signal: AbortSignal.timeout(TIMEOUT_MS)
  });
  if (!response.ok) throw new Error(`token HTTP ${response.status}`);

  const body = await response.json();
  cachedToken = {
    value: body.access_token,
    expiresAt: Date.now() + (Number(body.expires_in) || 3600) * 1000
  };
  return cachedToken.value;
}

/** One notification to one device. Marks a gone token so the caller deletes it. */
async function sendToDevice(config, accessTokenValue, device, message) {
  const response = await fetch(`${SEND_URL}/${config.projectId}/messages:send`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessTokenValue}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      message: {
        token: device.token,
        notification: { title: message.title, body: message.body ?? '' },
        data: Object.fromEntries(
          Object.entries(message.data ?? {}).map(([key, value]) => [key, String(value)])
        )
      }
    }),
    signal: AbortSignal.timeout(TIMEOUT_MS)
  });
  if (response.ok) return;

  const text = await response.text().catch(() => '');
  const error = new Error(`FCM HTTP ${response.status}`);
  error.unregistered = response.status === 404 || text.includes('UNREGISTERED');
  throw error;
}

/**
 * Sends [message] (`{ title, body, data }`) to every device [userId] has
 * registered. Resolves to `{ sent, failed, removed }`; never throws.
 */
async function sendToUser(userId, message) {
  const result = { sent: 0, failed: 0, removed: 0 };
  if (!userId || !message || !message.title) return result;

  const config = pushConfig();
  if (!config && !testSender) return result;

  const devices = await DeviceToken.find({ userId }).lean();
  if (devices.length === 0) return result;

  let token = null;
  if (!testSender) {
    try {
      token = await accessToken(config);
    } catch (error) {
      logger.warn('push.no_access_token', { error: error.message });
      result.failed = devices.length;
      return result;
    }
  }

  for (const device of devices) {
    try {
      if (testSender) await testSender(device.token, message);
      else await sendToDevice(config, token, device, message);
      result.sent += 1;
    } catch (error) {
      if (error.unregistered) {
        await DeviceToken.deleteOne({ _id: device._id });
        result.removed += 1;
      } else {
        logger.warn('push.failed', { platform: device.platform, error: error.message });
        result.failed += 1;
      }
    }
  }
  return result;
}

module.exports = { sendToUser, pushesEnabled, setSenderForTests, signedAssertion };
