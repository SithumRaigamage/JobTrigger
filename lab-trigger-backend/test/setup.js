const { MongoMemoryServer } = require('mongodb-memory-server');
const mongoose = require('mongoose');
const serverModule = require('../server');

let mongoServer;
let serverInstance;

before(async function() {
  this.timeout(20000);
  mongoServer = await MongoMemoryServer.create();
  process.env.MONGODB_URI = mongoServer.getUri();
  process.env.JWT_SECRET = process.env.JWT_SECRET || 'test_jwt_secret';

  // Start the server which will connect mongoose to the in-memory mongo
  serverInstance = await serverModule.startServer();
});

after(async function() {
  await mongoose.disconnect();
  if (serverInstance && serverInstance.close) {
    serverInstance.close();
  }
  if (mongoServer) await mongoServer.stop();
});
