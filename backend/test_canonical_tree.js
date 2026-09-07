const mongoose = require('mongoose');
require('dotenv').config();
const { buildFamilyTree } = require('./services/memberService');
const User = require('./models/User');
const Profile = require('./models/Profile');

async function test() {
  await mongoose.connect(process.env.MONGODB_URI);
  console.log('Connected to MongoDB');

  console.log('\n--- 1. Testing Family Tree for Rishik (rishikjariwala54@gmail.com) ---');
  const rishikUser = await User.findOne({ email: 'rishikjariwala54@gmail.com' });
  const rishikProf = await Profile.findOne({ userId: rishikUser._id }).populate('userId');
  const rishikTree = await buildFamilyTree(rishikProf, rishikUser.email);
  console.log(JSON.stringify(rishikTree, null, 2));

  console.log('\n--- 2. Testing Family Tree for Mother Payal (23rishikjariwala7b@gmail.com) ---');
  const payalUser = await User.findOne({ email: '23rishikjariwala7b@gmail.com' });
  const payalProf = await Profile.findOne({ userId: payalUser._id }).populate('userId');
  const payalTree = await buildFamilyTree(payalProf, payalUser.email);
  console.log(JSON.stringify(payalTree, null, 2));

  await mongoose.disconnect();
}
test();
