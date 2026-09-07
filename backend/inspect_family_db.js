const mongoose = require('mongoose');
require('dotenv').config();
const User = require('./models/User');
const Profile = require('./models/Profile');
const Member = require('./models/Member');

async function inspect() {
  await mongoose.connect(process.env.MONGODB_URI);

  const users = await User.find({ email: { $in: ['rishikjariwala54@gmail.com', '23rishikjariwala7b@gmail.com'] } });
  console.log('--- USERS ---');
  console.log(users.map(u => ({ id: u._id, email: u.email, fullName: u.fullName })));

  const profiles = await Profile.find({ userId: { $in: users.map(u => u._id) } });
  console.log('--- PROFILES ---');
  console.log(profiles.map(p => ({
    userId: p.userId,
    memberId: p.memberId,
    fatherName: p.fatherName,
    fatherId: p.fatherId,
    motherName: p.motherName,
    motherId: p.motherId,
    grandfather: p.grandfather,
    paternalGrandfatherId: p.paternalGrandfatherId,
    grandmother: p.grandmother,
    paternalGrandmotherId: p.paternalGrandmotherId,
    nana: p.nana,
    maternalGrandfatherId: p.maternalGrandfatherId,
    nani: p.nani,
    maternalGrandmotherId: p.maternalGrandmotherId,
    spouseName: p.spouseName,
    spouseId: p.spouseId,
    addedMembers: p.addedMembers
  })));

  const members = await Member.find({ memberId: { $in: ['MEM001', 'MEM046', 'MEM047', 'MEM048', 'MEM049', 'MEM050', 'MEM051', 'MEM052'] } });
  console.log('--- MEMBERS ---');
  console.log(members.map(m => ({
    memberId: m.memberId,
    fullName: m.fullName,
    gender: m.gender,
    fatherId: m.fatherId,
    motherId: m.motherId,
    spouseId: m.spouseId,
    paternalGrandfatherId: m.paternalGrandfatherId,
    paternalGrandmotherId: m.paternalGrandmotherId,
    maternalGrandfatherId: m.maternalGrandfatherId,
    maternalGrandmotherId: m.maternalGrandmotherId
  })));

  await mongoose.disconnect();
}
inspect();
