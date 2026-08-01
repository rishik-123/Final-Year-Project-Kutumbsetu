require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./models/User');
const Profile = require('./models/Profile');

const run = async () => {
  const uri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/kutumbsetu';
  await mongoose.connect(uri);

  console.log('Connected to DB. Finding your account...');
  
  const myEmail = 'rishikjariwala54@gmail.com';
  const me = await User.findOne({ email: myEmail });
  
  if (!me) {
    console.error(`ERROR: User with email ${myEmail} not found. Please log in/register in the app first.`);
    await mongoose.connection.close();
    return;
  }

  let myProfile = await Profile.findOne({ userId: me._id });
  let familyId = myProfile ? myProfile.familyId : '';

  if (!familyId) {
    // Generate a new unique family ID
    const fCode = me.fullName.substring(0, 2).toUpperCase().padEnd(2, 'X');
    const sCode = 'JA'; // Default fallback for Jariwala
    const yearDigits = '00';
    const randomStr = 'F5';
    familyId = `${fCode}${sCode}${yearDigits}${randomStr}`;
  }

  if (!myProfile) {
    myProfile = new Profile({
      userId: me._id,
      gender: 'Male',
      dateOfBirth: '2000-08-15',
      phoneNumber: '+919136091621',
      profilePhoto: 'avatar_male_1',
      city: 'Surat',
      state: 'Gujarat',
      familyId: familyId,
      relationshipToHead: 'Self',
    });
    await myProfile.save();
    console.log('Created profile for yourself.');
  } else {
    myProfile.familyId = familyId;
    myProfile.relationshipToHead = 'Self';
    await myProfile.save();
    console.log('Updated your profile with Family ID:', familyId);
  }

  // Clear existing family members sharing this family ID to prevent duplicates (except yourself)
  await Profile.deleteMany({ familyId, userId: { $ne: me._id } });

  console.log('Seeding family members for Family ID:', familyId);

  // Helper to add a family member
  const addMember = async (fullName, relation, gender, dob, photo) => {
    const email = `${relation.toLowerCase()}_demo_${Date.now()}@example.com`;
    const user = new User({
      fullName,
      email,
    });
    const savedUser = await user.save();

    const profile = new Profile({
      userId: savedUser._id,
      gender,
      dateOfBirth: dob,
      phoneNumber: `+919900${Math.floor(100000 + Math.random() * 900000)}`,
      profilePhoto: photo,
      city: 'Surat',
      state: 'Gujarat',
      familyId,
      relationshipToHead: relation,
    });
    await profile.save();
    console.log(`- Added ${relation}: ${fullName}`);
  };

  // Add spouse, son, father, mother, grandfather
  await addMember('Priyaben Jariwala', 'Wife', 'Female', '2002-05-10', 'avatar_female_1');
  await addMember('Amit Jariwala', 'Son', 'Male', '2024-04-12', 'avatar_male_2');
  await addMember('Manilal Jariwala', 'Father', 'Male', '1970-11-20', 'avatar_male_1');
  await addMember('Savitaben Jariwala', 'Mother', 'Female', '1974-03-15', 'avatar_female_2');
  await addMember('Chhotalal Jariwala', 'Grandfather', 'Male', '1945-09-08', 'avatar_male_1');

  console.log('\nSUCCESS: Demo family tree seeded successfully.');
  console.log(`You can now go to the Family Tree tab in the app under ${myEmail} to view it!`);

  await mongoose.connection.close();
};

run();
