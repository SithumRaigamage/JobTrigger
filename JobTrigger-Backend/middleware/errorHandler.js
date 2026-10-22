const { logger } = require('../lib/logger');

/**
 * AUD-06: the one place an unexpected error becomes a response. Details go
 * to the server log; the client gets a generic body, never Mongo or
 * mongoose internals. Express 5 forwards rejected async handlers here.
 */

// Unknown routes: JSON like every other response, not Express's HTML page.
function notFound(req, res) {
  logger.info('http.not_found', {
    ...(req.requestId ? { requestId: req.requestId } : {}),
    method: req.method,
    path: req.logPath ?? req.path,
  });
  res.status(404).json({ message: 'Not found' });
}

// Express recognises an error handler by its four parameters.
function errorHandler(err, req, res, next) {
  if (res.headersSent) return next(err);

  // Malformed or oversized request bodies (express.json / body-parser).
  if (err.type === 'entity.parse.failed') {
    return res.status(400).json({ message: 'Malformed JSON body' });
  }
  if (err.status >= 400 && err.status < 500) {
    return res.status(err.status).json({ message: 'Bad request' });
  }
  if (err.name === 'ValidationError') {
    return res.status(400).json({
      message: 'Invalid data',
      fields: Object.keys(err.errors ?? {}),
    });
  }
  if (err.name === 'CastError') {
    return res.status(400).json({ message: 'Invalid value' });
  }

  // §19: the id ties this line to the request that caused it, and the
  // client gets it back so a user can quote it in a bug report. The
  // path is the route path, never the query string.
  logger.error('http.error', {
    ...(req.requestId ? { requestId: req.requestId } : {}),
    method: req.method,
    path: req.logPath ?? req.path,
    error: err.name,
    message: err.message,
    stack: err.stack,
  });
  res.status(500).json({
    message: 'Server error',
    ...(req.requestId ? { requestId: req.requestId } : {}),
  });
}

module.exports = { notFound, errorHandler };
