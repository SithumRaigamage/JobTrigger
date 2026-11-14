/**
 * E3 / PE-20: the offline fallback. A transport wrapper: when the
 * reporting host can't be reached, the (already scrubbed) event is
 * appended as one JSON line to `<dir>/YYYY-MM-DD.jsonl`, and retried on
 * startup and every few minutes. Lines are removed once accepted.
 *
 * Limits: files are mode 600, the outbox is capped at 10 MB and 7 days.
 * Only event envelopes are kept; the DSN is never written to disk.
 */

'use strict';

const fs = require('fs');
const path = require('path');
const { logger } = require('../logger');

const DEFAULTS = {
  maxBytes: 10 * 1024 * 1024,
  maxAgeDays: 7,
  retryEveryMs: 5 * 60 * 1000,
};

const DAY_FILE = /^(\d{4}-\d{2}-\d{2})\.jsonl$/;

const accepted = (status) => status >= 200 && status < 300;
// A rejection that retrying can't fix (but not rate limiting or a timeout).
const rejectedForGood = (status) =>
  status >= 400 && status < 500 && status !== 408 && status !== 429;

function createOutbox({ dir, dsn, now = () => new Date(), ...limits } = {}) {
  const { maxBytes, maxAgeDays } = { ...DEFAULTS, ...limits };

  const files = () => {
    try {
      return fs
        .readdirSync(dir)
        .filter((name) => DAY_FILE.test(name))
        .sort();
    } catch {
      return [];
    }
  };

  const sizeOf = (name) => {
    try {
      return fs.statSync(path.join(dir, name)).size;
    } catch {
      return 0;
    }
  };

  function prune() {
    const cutoff = now().getTime() - maxAgeDays * 24 * 60 * 60 * 1000;
    for (const name of files()) {
      const day = Date.parse(`${name.match(DAY_FILE)[1]}T23:59:59Z`);
      if (day < cutoff) fs.rmSync(path.join(dir, name), { force: true });
    }
  }

  /** Keep [envelope] for later. Returns false when it wasn't stored. */
  function add(envelope) {
    try {
      if (!Array.isArray(envelope) || !envelope[1]?.some((item) => item[0]?.type === 'event')) {
        return false;
      }
      fs.mkdirSync(dir, { recursive: true, mode: 0o700 });
      prune();
      const { dsn: _dsn, ...headers } = envelope[0] ?? {};
      const line = `${JSON.stringify([headers, envelope[1]])}\n`;
      const total = files().reduce((sum, name) => sum + sizeOf(name), 0);
      if (total + Buffer.byteLength(line) > maxBytes) return false;
      const file = path.join(dir, `${now().toISOString().slice(0, 10)}.jsonl`);
      fs.appendFileSync(file, line, { mode: 0o600 });
      fs.chmodSync(file, 0o600);
      return true;
    } catch (err) {
      logger.warn('error_reporting.outbox_write_failed', { error: err.name });
      return false;
    }
  }

  /** Send every stored line through [send]; keep the ones that fail. */
  async function drain(send) {
    prune();
    for (const name of files()) {
      const file = path.join(dir, name);
      let lines;
      try {
        lines = fs.readFileSync(file, 'utf8').split('\n').filter(Boolean);
      } catch {
        continue;
      }
      const keep = [];
      for (const line of lines) {
        let envelope;
        try {
          envelope = JSON.parse(line);
        } catch {
          continue; // a damaged line can't be sent; drop it
        }
        if (dsn) envelope[0] = { ...envelope[0], dsn };
        let status;
        try {
          status = (await send(envelope))?.statusCode;
        } catch {
          status = undefined;
        }
        if (accepted(status) || rejectedForGood(status)) continue;
        keep.push(line);
      }
      if (keep.length === 0) fs.rmSync(file, { force: true });
      else fs.writeFileSync(file, `${keep.join('\n')}\n`, { mode: 0o600 });
    }
  }

  return { add, drain, dir };
}

/**
 * Wrap a Sentry transport [inner] with the outbox. A send that fails (no
 * response, 5xx, 429) is stored; the stored events are retried on `start`
 * and every `retryEveryMs`.
 */
function withOutbox(inner, outbox, { retryEveryMs = DEFAULTS.retryEveryMs } = {}) {
  let timer;
  let draining = false;

  const drain = async () => {
    if (draining) return;
    draining = true;
    try {
      await outbox.drain((envelope) => inner.send(envelope));
    } finally {
      draining = false;
    }
  };

  timer = setInterval(drain, retryEveryMs);
  timer.unref?.();
  drain().catch(() => {});

  return {
    async send(envelope) {
      let response;
      try {
        response = await inner.send(envelope);
      } catch {
        response = undefined;
      }
      const status = response?.statusCode;
      if (!accepted(status) && !rejectedForGood(status)) outbox.add(envelope);
      return response ?? {};
    },
    flush: (timeout) => inner.flush(timeout),
    drain,
    stop: () => clearInterval(timer),
  };
}

module.exports = { createOutbox, withOutbox };
