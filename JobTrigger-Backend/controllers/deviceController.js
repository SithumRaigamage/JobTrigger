const DeviceToken = require('../models/DeviceToken');

/** Long enough for a real push token, short enough to reject junk. */
const MIN_TOKEN_LENGTH = 10;
const MAX_TOKEN_LENGTH = 4096;

/**
 * NR-06 (BACKLOG-02): registers the caller's device for server push.
 * Idempotent — the app may call it on every launch; one row per token, and a
 * token that moves to another account moves with it (`upsert` on `token`).
 */
async function registerDevice(req, res) {
  const { token, platform } = req.body ?? {};
  if (typeof token !== 'string' || token.trim().length < MIN_TOKEN_LENGTH || token.length > MAX_TOKEN_LENGTH) {
    return res.status(400).json({ message: 'A push token is required.' });
  }
  if (platform !== 'ios' && platform !== 'android') {
    return res.status(400).json({ message: 'Platform must be ios or android.' });
  }

  await DeviceToken.findOneAndUpdate(
    { token: token.trim() },
    { userId: req.user.id, platform, lastSeenAt: new Date() },
    { upsert: true, setDefaultsOnInsert: true }
  );
  res.status(204).end();
}

/**
 * NR-06: stops pushing to one token. Scoped to the caller, so one account
 * can't unregister another's device; an unknown token is still a 204, since
 * "this device shouldn't get pushes" is true either way.
 */
async function unregisterDevice(req, res) {
  await DeviceToken.deleteOne({ userId: req.user.id, token: req.params.token });
  res.status(204).end();
}

module.exports = { registerDevice, unregisterDevice };
