const mongoose = require('mongoose');
require('dotenv').config();
const User = require('./models/User');
const MatrimonialProfile = require('./models/MatrimonialProfile');

async function testQueryDirectly() {
  await mongoose.connect(process.env.MONGODB_URI);

  const search = '23rishikjariwala7b@gmail.com';
  const cleanSearch = search.trim();
  const searchRegex = new RegExp(cleanSearch.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&'), 'i');

  const matchingUsers = await User.find({
    $or: [
      { email: searchRegex },
      { fullName: searchRegex },
      { phoneNumber: searchRegex }
    ]
  }).select('_id');
  const userIds = matchingUsers.map(u => u._id);

  const orConditions = [
    { name: searchRegex },
    { village: searchRegex },
    { city: searchRegex },
    { education: searchRegex },
    { occupation: searchRegex },
    { company: searchRegex },
  ];
  if (userIds.length > 0) {
    orConditions.push({ userId: { $in: userIds } });
  }

  const query = { profileStatus: 'Approved', $or: orConditions };

  const profiles = await MatrimonialProfile.find(query).populate('userId');
  console.log('Profiles found directly with new logic:', profiles.map(p => ({
    id: p._id,
    name: p.name,
    userId: p.userId ? p.userId._id : null,
    userEmail: p.userId ? p.userId.email : null,
    gender: p.gender,
    education: p.education,
    occupation: p.occupation,
    city: p.city
  })));

  await mongoose.disconnect();
}
testQueryDirectly();
