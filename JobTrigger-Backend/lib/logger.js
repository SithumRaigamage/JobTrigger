/**
 * §19: the server's only output channel. One JSON object per line, so a
 * log aggregator can index the events and an engineer can match a
 * failure report to the lines behind it.
 *
 * Every line carries `level`, `time` and `msg`; a `requestId` is added
 * for anything that belongs to a request.
 *
 * The rule that makes this safe: nothing else in the server writes to
 * stdout or stderr, so there is exactly one place to check for secrets.
 * Never log a token, a password, a decrypted secret, a request body or
 * a header.
 */

// Ordered from quietest to loudest: a line is written when its level is
// at or below the threshold.
const LEVELS = { silent: 0, error: 1, warn: 2, info: 3 };

/** The level below which lines are dropped (LOG_LEVEL, default `info`). */
function threshold() {
  const name = String(process.env.LOG_LEVEL ?? 'info').toLowerCase();
  return LEVELS[name] ?? LEVELS.info;
}

const enabled = (level) => LEVELS[level] <= threshold();

/** The JSON line for [level], [msg] and [fields]. */
function format(level, msg, fields = {}) {
  return JSON.stringify({ level, time: new Date().toISOString(), msg, ...fields });
}

function emit(level, msg, fields = {}) {
  if (!enabled(level)) return;
  const line = format(level, msg, fields);
  // Errors go to stderr so a supervisor can pick them out; everything
  // else to stdout.
  if (level === 'error') console.error(line);
  else console.log(line);
}

const logger = {
  info: (msg, fields) => emit('info', msg, fields),
  warn: (msg, fields) => emit('warn', msg, fields),
  error: (msg, fields) => emit('error', msg, fields),
  /**
   * A logger that adds [fields] to every line (the request id, usually).
   */
  child: (fields) => ({
    info: (msg, extra) => emit('info', msg, { ...fields, ...extra }),
    warn: (msg, extra) => emit('warn', msg, { ...fields, ...extra }),
    error: (msg, extra) => emit('error', msg, { ...fields, ...extra }),
  }),
};

module.exports = { logger, format };
