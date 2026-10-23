const crypto = require('crypto');

/**
 * §19: every request gets an id, so a failure report from a user can be
 * matched to the server-side log lines of that request.
 *
 * An inbound `x-request-id` is honoured only when it looks like an id:
 * the value ends up in log lines, so an untrusted one must not be able
 * to inject newlines or arbitrary text. Anything else is replaced with a
 * fresh id.
 */
const INBOUND_ID = /^[A-Za-z0-9._-]{1,64}$/;

function requestId(req, res, next) {
  const inbound = req.get('x-request-id');
  const id =
    typeof inbound === 'string' && INBOUND_ID.test(inbound)
      ? inbound
      : crypto.randomUUID();
  req.requestId = id;
  res.set('x-request-id', id);
  next();
}

module.exports = requestId;
module.exports.INBOUND_ID = INBOUND_ID;
