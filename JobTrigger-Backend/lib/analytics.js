/**
 * P20-78: anonymous product events to Umami (the DevOps lab's
 * `analytics/`), sent from the server so no tracker runs anywhere else.
 *
 * - Off unless UMAMI_URL and UMAMI_WEBSITE_ID are set: track() is a no-op.
 * - Fire-and-forget: never awaited by a request, never throws, a slow or
 *   down Umami can't delay or fail an API call (3 s timeout).
 * - Only catalogue names (analyticsEvents.js); `data` keeps short
 *   primitive values only. Never pass an email, id, URL or token.
 */
const EVENTS = require('./analyticsEvents');
const { analyticsConfig } = require('../config/env');
const { logger } = require('./logger');

// Umami drops requests without a browser-like User-Agent (bot filter).
const USER_AGENT = 'Mozilla/5.0 (compatible; JobTrigger-Backend)';
const TIMEOUT_MS = 3000;

let testSender = null;

/** Tests: `async (url, body) => void`, or null to restore. */
function setSenderForTests(fake) {
  testSender = fake;
}

/** Keeps up to 10 keys whose values are short strings, numbers or booleans. */
function cleanData(data) {
  if (!data || typeof data !== 'object') return undefined;
  const out = {};
  for (const [key, value] of Object.entries(data).slice(0, 10)) {
    if (!/^[a-zA-Z][a-zA-Z0-9_]{0,39}$/.test(key)) continue;
    if (typeof value === 'number' || typeof value === 'boolean') out[key] = value;
    else if (typeof value === 'string' && value.length <= 64) out[key] = value;
  }
  return Object.keys(out).length > 0 ? out : undefined;
}

async function defaultSender(url, body) {
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'User-Agent': USER_AGENT },
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(TIMEOUT_MS),
  });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
}

/** Records [name] with optional [data]. Returns a promise tests may await. */
function track(name, data) {
  if (!EVENTS.includes(name)) {
    logger.warn('analytics.unknown_event', { event: String(name).slice(0, 40) });
    return Promise.resolve(false);
  }
  const config = analyticsConfig();
  if (!config && !testSender) return Promise.resolve(false);

  const body = {
    type: 'event',
    payload: {
      website: config?.websiteId ?? 'test',
      hostname: 'backend.jobtrigger.local',
      url: '/backend',
      name,
      ...(cleanData(data) ? { data: cleanData(data) } : {}),
    },
  };
  const url = `${config?.url ?? 'http://umami.test'}/api/send`;
  return (testSender ?? defaultSender)(url, body)
    .then(() => true)
    .catch((err) => {
      logger.warn('analytics.failed', { event: name, error: err.message });
      return false;
    });
}

module.exports = { track, setSenderForTests, cleanData };
