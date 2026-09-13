const mongoose = require('mongoose');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

// Models
const User = require('../models/User');
const JenkinsCredential = require('../models/JenkinsCredential');
const AppInfo = require('../models/AppInfo');

// Colors
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

async function runMigrations() {
  try {
    log.header('🚀 JobTrigger Database Setup - Full Migration');

    // Step 1: Connect to MongoDB
    log.step('Connecting to MongoDB');
    log.info(`URI: ${process.env.MONGODB_URI.replace(/:[^@]*@/, ':***@')}`);

    await mongoose.connect(process.env.MONGODB_URI, { dbName: 'jobtrigger' });
    log.success('Connected to MongoDB');

    // Get database instance
    const db = mongoose.connection.db;

    // Step 2: Clean up "test" collection
    log.step('Cleaning up test collection');
    try {
      const collections = await db.listCollections().toArray();
      const testCollection = collections.find(c => c.name.toLowerCase() === 'tests' || c.name.toLowerCase() === 'test');

      if (testCollection) {
        await db.collection(testCollection.name).deleteMany({});
        log.success(`Cleaned collection: "${testCollection.name}"`);
      } else {
        log.info('No "test" collection found (already clean)');
      }
    } catch (err) {
      log.warning(`Could not clean test collection: ${err.message}`);
    }

    // Step 3: Seed AppInfo
    log.step('Seeding AppInfo collection');

    const existingAppInfo = await AppInfo.findOne({});
    if (existingAppInfo) {
      log.info('AppInfo already seeded, updating...');
      await AppInfo.deleteMany({});
    }

    const appInfo = new AppInfo({
      appVersion: '1.0.0',
      buildNumber: '1',
      privacyPolicyUrl: 'https://example.com/privacy',
      termsOfServiceUrl: 'https://example.com/terms',
      supportEmail: 'support@jobtrigger.dev',
      openSourceLicensesUrl: 'https://example.com/licenses'
    });
    await appInfo.save();
    log.success('AppInfo seeded successfully');

    // Step 4: Create development user
    log.step('Creating development user account');

    let devUser = await User.findOne({ email: 'developer@jobtrigger.app' });
    if (devUser) {
      log.info('Development user already exists, skipping');
    } else {
      devUser = new User({
        email: 'developer@jobtrigger.app',
        password: 'SecurePassword123!'
      });
      await devUser.save();
      log.success('Development user created: developer@jobtrigger.app');
    }

    // Step 5: Create production Jenkins credentials
    log.step('Creating Jenkins server credentials');

    const jenkinsServers = [
      {
        serverName: 'Production CI',
        jenkinsURL: 'https://jenkins-prod.company.com',
        username: 'ci-user',
        password: 'prod-token-xxxxx',
        isDefault: true
      },
      {
        serverName: 'Staging Pipeline',
        jenkinsURL: 'https://jenkins-staging.company.com',
        username: 'ci-user',
        password: 'staging-token-xxxxx',
        isDefault: false
      },
      {
        serverName: 'Development Build',
        jenkinsURL: 'http://localhost:8080',
        username: 'admin',
        password: 'dev-token-xxxxx',
        isDefault: false
      }
    ];

    let credsCreated = 0;
    for (const server of jenkinsServers) {
      const existingCred = await JenkinsCredential.findOne({
        userId: devUser._id,
        serverName: server.serverName
      });

      if (!existingCred) {
        const credential = new JenkinsCredential({
          userId: devUser._id,
          serverName: server.serverName,
          jenkinsURL: server.jenkinsURL,
          username: server.username,
          password: server.password,
          isDefault: server.isDefault
        });
        await credential.save();
        credsCreated++;
      }
    }
    log.success(`Created ${credsCreated} Jenkins server credential(s)`);

    // Step 6: Verify all collections
    log.step('Verifying collections and data');

    const allCollections = await db.listCollections().toArray();
    console.log(`\n${colors.blue}Collections in database:${colors.reset}`);

    for (const col of allCollections) {
      const count = await db.collection(col.name).countDocuments();
      console.log(`  ${colors.green}✓${colors.reset} ${col.name}: ${count} document(s)`);
    }

    // Detailed verification
    log.step('Detailed verification');

    const userCount = await User.countDocuments();
    console.log(`${colors.blue}Users:${colors.reset} ${userCount}`);
    const users = await User.find({}, { email: 1, _id: 1 });
    users.forEach(u => console.log(`  - ${u.email} (ID: ${u._id})`));

    const credCount = await JenkinsCredential.countDocuments();
    console.log(`\n${colors.blue}Jenkins Credentials:${colors.reset} ${credCount}`);
    const creds = await JenkinsCredential.find({}, { serverName: 1, jenkinsURL: 1, userId: 1 });
    creds.forEach(c => console.log(`  - ${c.serverName} (${c.jenkinsURL})`));

    const appInfoCount = await AppInfo.countDocuments();
    console.log(`\n${colors.blue}AppInfo:${colors.reset} ${appInfoCount}`);
    const appData = await AppInfo.findOne({});
    if (appData) {
      console.log(`  - Version: ${appData.appVersion}`);
      console.log(`  - Build: ${appData.buildNumber}`);
    }

    // Final summary
    log.header('✨ Migration Complete!');
    log.success('All migrations completed successfully');

    console.log(`\n${colors.cyan}📊 Summary:${colors.reset}`);
    console.log(`  ${colors.green}✓${colors.reset} Test collection cleaned`);
    console.log(`  ${colors.green}✓${colors.reset} AppInfo seeded (${appInfoCount})`);
    console.log(`  ${colors.green}✓${colors.reset} Users created (${userCount})`);
    console.log(`  ${colors.green}✓${colors.reset} Credentials created (${credCount})`);

    console.log(`\n${colors.cyan}🔑 Login Credentials:${colors.reset}`);
    console.log(`  Email: developer@jobtrigger.app`);
    console.log(`  Password: SecurePassword123!`);

    console.log(`\n${colors.cyan}📱 Next Steps:${colors.reset}`);
    console.log(`  1. Start backend: ${colors.yellow}npm run dev${colors.reset}`);
    console.log(`  2. Run Flutter app: ${colors.yellow}flutter run -d "iPhone Air"${colors.reset}`);
    console.log(`  3. Login with test credentials above`);
    console.log(`  4. Enable "Remember me" ✨\n`);

    await mongoose.disconnect();
    process.exit(0);

  } catch (err) {
    log.error(`Migration failed: ${err.message}`);
    console.error(err);
    process.exit(1);
  }
}

// Run migrations
runMigrations();
