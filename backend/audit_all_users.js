require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./models/User');
const Profile = require('./models/Profile');
const Member = require('./models/Member');

async function auditAllUsers() {
  const uri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/kutumbsetu';
  await mongoose.connect(uri);

  console.log('--- ALL USERS IN DB ---');
  const allUsers = await User.find({});
  for (const u of allUsers) {
    const prof = await Profile.findOne({ userId: u._id });
    console.log(`User: ${u._id} | Name: "${u.fullName}" | Email: "${u.email}" | Phone: "${u.phoneNumber}" | Role: "${u.role}" | MemberId: "${prof?.memberId}"`);
  }

  console.log('\n--- ALL PROFILES IN DB ---');
  const allProfiles = await Profile.find({});
  for (const p of allProfiles) {
    console.log(`Profile: ${p._id} | UserId: ${p.userId} | MemberId: ${p.memberId} | FatherId: ${p.fatherId} | FatherName: ${p.fatherName} | FamilyId: ${p.familyId}`);
  }

  await mongoose.connection.close();
}

auditAllUsers().catch(console.error);
