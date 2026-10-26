require('dotenv').config();
const mongoose = require('mongoose');
const AppInfo = require('../models/AppInfo');
const { connectDatabase, connectionHint } = require('../lib/database');

const seedData = {
  appVersion: "1.0.0",
  buildNumber: "1",
  privacyPolicyUrl: "https://example.com/privacy",
  termsOfServiceUrl: "https://example.com/terms",
  supportEmail: "support@jobtrigger.com",
  openSourceLicensesUrl: "https://example.com/licenses"
};

const seedDB = async () => {
  try {
    await connectDatabase();
    console.log('Connected to MongoDB for seeding');

    // Clear existing
    await AppInfo.deleteMany();
    
    // Insert new
    await AppInfo.create(seedData);
    console.log('AppInfo seeded successfully');
    
    mongoose.connection.close();
  } catch (error) {
    console.error('Error seeding DB:', error.message);
    const hint = connectionHint(error);
    if (hint) console.error(hint);
    process.exit(1);
  }
};

seedDB();
