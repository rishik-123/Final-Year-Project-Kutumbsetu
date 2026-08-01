require('dotenv').config();
const mongoose = require('mongoose');

const run = async () => {
  const uri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/kutumbsetu';
  await mongoose.connect(uri);

  const db = mongoose.connection.db;

  console.log('--- RAW USERS IN DB ---');
  const users = await db.collection('users').find({}).toArray();
  console.log(`Found ${users.length} users:`);
  users.forEach(u => {
    console.log(u);
  });

  console.log('\n--- RAW DIRECTORY IN DB ---');
  const directory = await db.collection('directory').find({}).toArray();
  console.log(`Found ${directory.length} directory entries:`);
  directory.forEach(d => {
    console.log(d);
  });

  console.log('\n--- RAW PROFILES IN DB ---');
  const profiles = await db.collection('profiles').find({}).toArray();
  console.log(`Found ${profiles.length} profiles:`);
  profiles.forEach(p => {
    console.log(p);
  });

  await mongoose.connection.close();
};

run();
