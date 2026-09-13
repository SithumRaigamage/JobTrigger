const mongoose = require('mongoose');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  cyan: '\x1b[36m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
  blue: '\x1b[34m'
};

const log = {
  header: (msg) => console.log(`\n${colors.cyan}${colors.bright}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${colors.reset}\n${colors.blue}${msg}${colors.reset}\n${colors.cyan}${colors.bright}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${colors.reset}\n`),
  step: (msg) => console.log(`\n${colors.blue}▶ ${msg}${colors.reset}`),
  success: (msg) => console.log(`${colors.green}✅ ${msg}${colors.reset}`),
  info: (msg) => console.log(`${colors.blue}ℹ️  ${msg}${colors.reset}`),
  warning: (msg) => console.log(`${colors.yellow}⚠️  ${msg}${colors.reset}`),
  error: (msg) => console.log(`${colors.red}❌ ${msg}${colors.reset}`),
};

async function cleanupTestDatabase() {
  try {
    log.header('🗑️ Cleanup "test" Database');

    log.step('Connecting to MongoDB');
    log.info(`URI: ${process.env.MONGODB_URI.replace(/:[^@]*@/, ':***@')}`);

    await mongoose.connect(process.env.MONGODB_URI);
    log.success('Connected to MongoDB');

    const admin = mongoose.connection.getClient().db('admin');

    log.step('Checking for "test" database');

    // Get list of all databases
    const adminDb = mongoose.connection.getClient().db('admin');
    const databases = await adminDb.admin().listDatabases();
    const testDbExists = databases.databases.some(db => db.name === 'test');

    if (testDbExists) {
      log.warning('Found "test" database - deleting...');

      // Switch to test database and drop it
      const testDb = mongoose.connection.getClient().db('test');
      await testDb.dropDatabase();

      log.success('"test" database deleted successfully');
    } else {
      log.info('"test" database not found (already cleaned)');
    }

    // Verify
    log.step('Verifying cleanup');
    const databasesAfter = await adminDb.admin().listDatabases();
    const remaining = databasesAfter.databases.map(db => db.name);

    console.log(`${colors.blue}Remaining databases:${colors.reset}`);
    remaining.forEach(db => {
      if (db !== 'admin' && db !== 'local') {
        console.log(`  ${colors.green}✓${colors.reset} ${db}`);
      }
    });

    if (!remaining.includes('test')) {
      log.success('"test" database successfully removed');
    }

    log.header('✨ Cleanup Complete!');
    log.info('Your MongoDB now only contains production databases');

    await mongoose.disconnect();
    process.exit(0);

  } catch (err) {
    log.error(`Cleanup failed: ${err.message}`);
    console.error(err);
    process.exit(1);
  }
}

cleanupTestDatabase();
