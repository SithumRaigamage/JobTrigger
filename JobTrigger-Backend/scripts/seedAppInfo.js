require('dotenv').config();
const mongoose = require('mongoose');
const AppInfo = require('../models/AppInfo');
const { connectDatabase, connectionHint } = require('../lib/database');
const { siteUrl } = require('../config/env');

/**
 * PE-01: the AppInfo singleton the app's About JobTrigger screen shows.
 * Links point at the real website pages (SITE_URL), never a placeholder:
 * /privacy, /terms and /licenses (PE-03).
 */
function appInfoSeed(env = process.env) {
  if (env.NODE_ENV === 'production' && !env.SITE_URL?.trim()) {
    throw new Error('SITE_URL is required to seed AppInfo in production');
  }
  const site = siteUrl(env);
  return {
    appVersion: '1.0.0',
    buildNumber: '1',
    privacyPolicyUrl: `${site}/privacy`,
    termsOfServiceUrl: `${site}/terms`,
    supportEmail: 'support@jobtrigger.com',
    openSourceLicensesUrl: `${site}/licenses`,
  };
}

/**
 * Replaces the singleton, so running it again also fixes a database that
 * still holds the old `example.com` links (PE-02).
 */
const seedDB = async () => {
  try {
    const seedData = appInfoSeed();
    await connectDatabase();
    console.log('Connected to MongoDB for seeding');

    await AppInfo.deleteMany();
    await AppInfo.create(seedData);
    console.log(`AppInfo seeded with links to ${siteUrl()}`);

    mongoose.connection.close();
  } catch (error) {
    console.error('Error seeding DB:', error.message);
    const hint = connectionHint(error);
    if (hint) console.error(hint);
    process.exit(1);
  }
};

if (require.main === module) seedDB();

module.exports = { appInfoSeed };
