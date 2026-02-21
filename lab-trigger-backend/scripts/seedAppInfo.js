require('dotenv').config();
const mongoose = require('mongoose');
const AppInfo = require('../models/AppInfo');

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
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB for seeding');

    // Clear existing
    await AppInfo.deleteMany();
    
    // Insert new
    await AppInfo.create(seedData);
    console.log('AppInfo seeded successfully');
    
    mongoose.connection.close();
  } catch (error) {
    console.error('Error seeding DB:', error);
    process.exit(1);
  }
};

seedDB();
