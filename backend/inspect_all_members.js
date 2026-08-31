require('dotenv').config();
const mongoose = require('mongoose');
const Member = require('./models/Member');
const User = require('./models/User');

async function inspectMembers() {
  const uri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/kutumbsetu';
  await mongoose.connect(uri);

  const members = await Member.find({}).sort({ memberId: 1 });
  console.log(`Total Members in DB: ${members.length}`);
  for (const m of members) {
    console.log(`[${m.memberId}] "${m.fullName}" | Phone: "${m.phoneNumber}" | Email: "${m.email}" | UserId: ${m.userId} | Father: ${m.fatherId} | Mother: ${m.motherId}`);
  }

  await mongoose.connection.close();
}

inspectMembers().catch(console.error);
