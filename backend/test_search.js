require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./models/User');
const MatrimonialProfile = require('./models/MatrimonialProfile');

function escapeRegex(text) {
  if (!text) return '';
  return text.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&');
}

async function testQuery(search) {
  await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/kutumbsetu');
  const cleanSearch = search.trim();
  const searchRegex = new RegExp(escapeRegex(cleanSearch), 'i');
  
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

  const query = {
    status: 'Approved',
    $or: orConditions
  };

  const profiles = await MatrimonialProfile.find(query).populate('userId');
  console.log('Query for:', search, '=> Found:', profiles.length);
  profiles.forEach(p => console.log(' -> Name:', p.name, 'Gender:', p.gender, 'Email:', p.userId?.email, 'Status:', p.status));
}

async function run() {
  await testQuery('23rishikjariwala7b@gmail.com');
  await testQuery('Mr A');
  await mongoose.disconnect();
}

run();
