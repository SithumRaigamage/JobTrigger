const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/credentials', require('./routes/credentialRoutes'));
app.use('/api/appinfo', require('./routes/appInfoRoutes'));

app.get('/', (req, res) => {
  res.json({ message: 'JobTrigger Backend API is running' });
});

// Database Connection (start server after DB connection)
async function startServer() {
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
