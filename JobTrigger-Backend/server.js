const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
require('dotenv').config();

const { corsOrigins, invalidConfig, missingConfig } = require('./config/env');
const { errorHandler, notFound } = require('./middleware/errorHandler');

// AUD-04: defence in depth. Query filters built from request data treat
// `$`-operators as literal values, so `{"$gt": ""}` can't match every row
// even if a handler forgets a type check.
mongoose.set('sanitizeFilter', true);

const app = express();

// AUD-05: behind a load balancer or reverse proxy, the rate limiter must
// see the client's IP, not the proxy's. TRUST_PROXY is the number of
// proxy hops (e.g. 1). Unset means direct connections.
if (process.env.TRUST_PROXY) {
  app.set('trust proxy', Number(process.env.TRUST_PROXY) || process.env.TRUST_PROXY);
}

// Middleware
// AUD-25: security headers, and CORS only for origins listed in
// CORS_ORIGINS (none by default; the mobile app doesn't need CORS).
app.use(helmet());
const origins = corsOrigins();
app.use(cors({ origin: origins.length > 0 ? origins : false }));
app.use(express.json());

// Routes
app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/credentials', require('./routes/credentialRoutes'));
app.use('/api/github-credentials', require('./routes/githubCredentialRoutes'));
app.use('/api/sonarqube-credentials', require('./routes/sonarqubeCredentialRoutes'));
app.use('/api/appinfo', require('./routes/appInfoRoutes'));

app.get('/', (req, res) => {
  res.json({ message: 'JobTrigger Backend API is running' });
});

// AUD-17: the container HEALTHCHECK. Unhealthy while MongoDB isn't
// connected, so an orchestrator can restart or hold traffic.
app.get('/healthz', (req, res) => {
  const up = mongoose.connection.readyState === 1;
  res.status(up ? 200 : 503).json({ status: up ? 'ok' : 'unavailable' });
});

// AUD-06: after every route. JSON 404s, and errors logged server-side
// with a generic body to the client.
app.use(notFound);
app.use(errorHandler);

// Database Connection (start server after DB connection)
async function startServer() {
  // AUD-25: refuse to start half-configured rather than fail per request.
  const missing = missingConfig();
  if (missing.length > 0) {
    console.error(`Missing required configuration: ${missing.join(', ')}`);
    process.exit(1);
  }
  const invalid = invalidConfig();
  if (invalid) {
    console.error(`Invalid configuration: ${invalid}`);
    process.exit(1);
  }
  try {
    await mongoose.connect(process.env.MONGODB_URI, { dbName: 'jobtrigger' });
    console.log('Connected to MongoDB');
    const PORT = process.env.PORT || 5001;
    const server = app.listen(PORT, () => {
      console.log(`Server is running on port ${PORT}`);
    });
    return server;
  } catch (err) {
    console.error('Could not connect to MongoDB', err);
    process.exit(1);
  }
}

// Only start server when this file is run directly. This allows tests to
// require the module, set environment variables (in-memory mongo) and then
// call `startServer()` explicitly.
if (require.main === module) {
  startServer();
}

module.exports = { app, startServer };
