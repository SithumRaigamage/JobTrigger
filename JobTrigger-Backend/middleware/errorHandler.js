/**
 * AUD-06: the one place an unexpected error becomes a response. Details go
 * to the server log; the client gets a generic body, never Mongo or
 * mongoose internals. Express 5 forwards rejected async handlers here.
 */

// Unknown routes: JSON like every other response, not Express's HTML page.
function notFound(req, res) {
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

  console.error(`${req.method} ${req.originalUrl} failed:`, err);
  res.status(500).json({ message: 'Server error' });
}

module.exports = { notFound, errorHandler };
