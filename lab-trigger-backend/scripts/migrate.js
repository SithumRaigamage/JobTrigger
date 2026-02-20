const mongoose = require('mongoose');
const fs = require('fs');
const path = require('path');
const User = require('../models/User');
const JenkinsCredential = require('../models/JenkinsCredential');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

const FRONTEND_RESOURCES_PATH = '/Users/sithumraigamage/projects/JobTrigger/Lab-Trigger-frontend/Lab-Trigger-frontend/Resources';

async function migrate() {
  try {
    console.log('🚀 Starting Migration...');

    // 1. Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // 2. Load JSON Data
    const usersJson = JSON.parse(fs.readFileSync(path.join(FRONTEND_RESOURCES_PATH, 'users.json'), 'utf8'));
    const credentialsJson = JSON.parse(fs.readFileSync(path.join(FRONTEND_RESOURCES_PATH, 'jenkins_credentials.json'), 'utf8'));

    console.log(`📂 Loaded ${usersJson.length} users and ${credentialsJson.length} credentials from JSON`);

    // 3. Migrate Users
    const migratedUsers = [];
    for (const userData of usersJson) {
      let user = await User.findOne({ email: userData.email });
      if (!user) {
        user = new User({
          email: userData.email,
          password: userData.password // Will be hashed by pre-save hook
        });
        await user.save();
        console.log(`👤 Migrated user: ${userData.email}`);
      } else {
        console.log(`⏩ User already exists: ${userData.email}`);
      }
      migratedUsers.push(user);
    }

    // 4. Migrate Credentials
    // For this migration, we'll link all credentials to the first user if not already linked
    const defaultUser = migratedUsers[0];
    if (!defaultUser) {
      throw new Error('No users found to link credentials to');
    }

    for (const credData of credentialsJson) {
      const existingCred = await JenkinsCredential.findOne({ 
        jenkinsURL: credData.jenkinsURL, 
        userId: defaultUser._id 
      });

      if (!existingCred) {
        const credential = new JenkinsCredential({
          userId: defaultUser._id,
          serverName: credData.serverName,
          jenkinsURL: credData.jenkinsURL,
          username: credData.username,
          password: credData.password,
          paramToken: credData.paramToken || '',
          isDefault: credData.isDefault || false,
          createdAt: new Date(credData.createdAt),
          updatedAt: new Date(credData.updatedAt)
        });
        await credential.save();
        console.log(`🔧 Migrated credential: ${credData.serverName}`);
      } else {
        console.log(`⏩ Credential already exists: ${credData.serverName}`);
      }
    }

    console.log('🏁 Migration completed successfully!');
    process.exit(0);
  } catch (err) {
    console.error('❌ Migration failed:', err);
    process.exit(1);
  }
}

migrate();
