require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./models/User');
const Profile = require('./models/Profile');

const run = async () => {
  const uri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/kutumbsetu';
  await mongoose.connect(uri);

  const email = 'rishikjariwala54@gmail.com';
  console.log(`=== Querying for email: ${email} ===`);
  const user = await User.findOne({ email });
  if (!user) {
    console.log(`User not found for email: ${email}`);
  } else {
    console.log('User Document:', user);
    const profile = await Profile.findOne({ userId: user._id });
    if (!profile) {
      console.log('Profile not found for user ID:', user._id);
    } else {
      console.log('Profile Document:', profile);
      console.log(`\n=== Querying profiles with familyId: "${profile.familyId}" ===`);
      const familyProfiles = await Profile.find({ familyId: profile.familyId }).populate('userId');
      console.log(`Found ${familyProfiles.length} profiles:`);
      familyProfiles.forEach((p, i) => {
        console.log(`\nProfile ${i+1}:`);
        console.log({
          id: p._id,
          userId: p.userId ? p.userId._id : null,
          fullName: p.userId ? p.userId.fullName : 'No User linked',
          email: p.userId ? p.userId.email : 'No email',
          phoneNumber: p.phoneNumber,
          relationshipToHead: p.relationshipToHead,
          familyId: p.familyId,
          fatherName: p.fatherName,
          motherName: p.motherName,
          grandfather: p.grandfather,
          grandmother: p.grandmother,
          nana: p.nana,
          nani: p.nani,
        });
      });
    }
  }

  await mongoose.connection.close();
};

run();
