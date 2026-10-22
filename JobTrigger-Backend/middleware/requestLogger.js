const { logger } = require('../lib/logger');

/**
 * §19: one line per finished request.
 *
 * The path is the route path without the query string (a query string
 * can carry a token), and never a header, a body or the request body:
 * the line is meant to be safe to keep.
 */
function requestLogger(req, res, next) {
  const startedAt = Date.now();
  // Captured now: inside a mounted router `req.url` is relative to the
  // mount point, and by the time the response finishes the router has
  // put it back.
  req.logPath = req.path;

  res.on('finish', () => {
    logger.info('http.request', {
      ...(req.requestId ? { requestId: req.requestId } : {}),
      method: req.method,
      path: req.logPath,
      status: res.statusCode,
      durationMs: Date.now() - startedAt,
      // Only when the request was authenticated; the id is ours, not a
      // secret.
      ...(req.user?.id ? { userId: req.user.id } : {}),
    });
  });
  next();
}

module.exports = requestLogger;
