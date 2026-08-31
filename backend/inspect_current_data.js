require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./models/User');
const Profile = require('./models/Profile');

async function inspect() {
  const uri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/kutumbsetu';
  await mongoose.connect(uri);

  console.log('--- ALL USERS ---');
  const users = await User.find({});
  users.forEach(u => console.log(`User: ${u.fullName} | Email: ${u.email} | Phone: ${u.phoneNumber} | Role: ${u.role} | ID: ${u._id}`));

  console.log('\n--- ALL PROFILES ---');
  const profiles = await Profile.find({}).populate('userId');
  profiles.forEach(p => {
    console.log(`Profile for: ${p.userId ? p.userId.fullName : 'No user'} | ID: ${p._id} | MemberId: ${p.memberId || 'None'} | FamilyId: ${p.familyId} | Father: "${p.fatherName}" (ID: ${p.fatherId}) | Mother: "${p.motherName}" (ID: ${p.motherId}) | GF: "${p.grandfather}" | GM: "${p.grandmother}" | Nana: "${p.nana}" | Nani: "${p.nani}" | Added: ${p.addedMembers ? p.addedMembers.length : 0}`);
  });

  console.log('\n--- DIRECTORY ENTRIES ---');
  const directory = await mongoose.connection.db.collection('directory').find({}).toArray();
  console.log(`Directory count: ${directory.length}`);
  directory.slice(0, 10).forEach(d => console.log(`Dir: ${d.fullName} | Phone: ${d.phoneNumber} | Rel: ${d.relationshipToHead} | FamId: ${d.familyId}`));

  await mongoose.connection.close();
}

inspect().catch(console.error);
