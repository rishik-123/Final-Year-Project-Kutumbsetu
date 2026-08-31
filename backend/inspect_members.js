require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./models/User');
const Profile = require('./models/Profile');
const Member = require('./models/Member');

async function inspectDatabase() {
  const uri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/kutumbsetu';
  await mongoose.connect(uri);
  console.log('Connected to MongoDB');

  console.log('\n--- ALL USERS WITH RISHIK IN NAME OR EMAIL ---');
  const rishikUsers = await User.find({
    $or: [
      { fullName: { $regex: /rishik/i } },
      { email: { $regex: /rishik/i } }
    ]
  });
  for (const u of rishikUsers) {
    const prof = await Profile.findOne({ userId: u._id });
    console.log(`User ID: ${u._id}, FullName: "${u.fullName}", Email: "${u.email}", Phone: "${u.phoneNumber}", Role: "${u.role}", Profile MemberId: "${prof?.memberId}"`);
  }

  console.log('\n--- ALL MEMBERS WITH RISHIK IN NAME OR EMAIL ---');
  const rishikMembers = await Member.find({
    $or: [
      { fullName: { $regex: /rishik/i } },
      { email: { $regex: /rishik/i } }
    ]
  });
  for (const m of rishikMembers) {
    console.log(`Member ID: ${m.memberId}, FullName: "${m.fullName}", Email: "${m.email}", Phone: "${m.phoneNumber}", UserId: "${m.userId}", FatherId: "${m.fatherId}", MotherId: "${m.motherId}"`);
  }

  console.log('\n--- CHECK FOR DUPLICATE MEMBERS ACROSS WHOLE DB ---');
  const allMembers = await Member.find({});
  const byName = {};
  for (const m of allMembers) {
    const norm = m.fullName.trim().toLowerCase();
    if (!byName[norm]) byName[norm] = [];
    byName[norm].push(m);
  }

  for (const [name, list] of Object.entries(byName)) {
    if (list.length > 1) {
      console.log(`Duplicate name detected: "${name}" (${list.length} records):`);
      list.forEach(m => console.log(`   - ID: ${m.memberId}, Phone: ${m.phoneNumber}, Email: ${m.email}, UserId: ${m.userId}`));
    }
  }

  await mongoose.connection.close();
}

inspectDatabase().catch(console.error);
