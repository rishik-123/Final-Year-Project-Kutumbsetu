require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./models/User');

const run = async () => {
  const uri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/kutumbsetu';
  await mongoose.connect(uri);
  const users = await User.find({});
  console.log('--- ALL USERS IN DATABASE ---');
  users.forEach(u => {
    console.log({
      id: u._id,
      name: u.fullName + ' ' + (u.surname || ''),
      phone: u.phoneNumber,
      familyId: u.familyId,
      familyName: u.familyName,
      relation: u.relationshipToHead,
      familyHeadPhone: u.familyHeadPhone,
    });
  });
  await mongoose.connection.close();
};
run();
