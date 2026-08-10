const mongoose = require('mongoose');

let mongodInstance = null;

const connectDB = async () => {
  try {
    let mongoUri = process.env.MONGODB_URI;

    if (!mongoUri) {
      try {
        mongoUri = 'mongodb://127.0.0.1:27017/kutumbsetu';
        await mongoose.connect(mongoUri, { serverSelectionTimeoutMS: 1500 });
        console.log(`MongoDB Connected (Local 27017): ${mongoose.connection.host}`);
        return;
      } catch (err) {
        console.log('Local MongoDB not active on 27017. Starting MongoMemoryServer on port 27017...');
        const { MongoMemoryServer } = require('mongodb-memory-server');
        mongodInstance = await MongoMemoryServer.create({
          instance: { port: 27017, dbName: 'kutumbsetu' },
          binary: { version: '6.0.6' },
        });
        mongoUri = mongodInstance.getUri();
        process.env.MONGODB_URI = mongoUri;
      }
    }

    const conn = await mongoose.connect(mongoUri);
    console.log(`MongoDB Connected: ${conn.connection.host}`);
  } catch (error) {
    console.error(`Database connection error: ${error.message}`);
    process.exit(1);
  }
};

module.exports = connectDB;
