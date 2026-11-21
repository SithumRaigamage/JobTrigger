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
/**
 * Where "Contact support" goes: SUPPORT_EMAIL, else support@ the website's
 * own domain, so it always matches SITE_URL (pre-release audit 2026-11-20:
 * it was hard-coded to a jobtrigger.com address while every other config
 * uses jobtrigger.app). The local website falls back to the 1.0 domain.
 */
function supportEmail(env, site) {
  if (env.SUPPORT_EMAIL?.trim()) return env.SUPPORT_EMAIL.trim();
  const host = new URL(site).hostname.replace(/^www\./, '');
  return host === 'localhost' || !host.includes('.') ? 'support@jobtrigger.app' : `support@${host}`;
}

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
    supportEmail: supportEmail(env, site),
    openSourceLicensesUrl: `${site}/licenses`,
    releaseNotesUrl: `${site}/changelog`,
    // US-PROF-03: set MIN_SUPPORTED_APP_VERSION and re-seed to make every
    // older app ask for an update; unset blocks nobody.
    minSupportedVersion: env.MIN_SUPPORTED_APP_VERSION?.trim() || null,
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
