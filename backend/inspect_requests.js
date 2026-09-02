require('dotenv').config();
const mongoose = require('mongoose');

async function inspect() {
  const uri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/kutumbsetu';
  await mongoose.connect(uri);

  const User = mongoose.model('User', new mongoose.Schema({}, { strict: false }));
  const DirectoryRequest = mongoose.model('DirectoryRequest', new mongoose.Schema({}, { strict: false }));

  console.log('--- ALL USERS ---');
  const users = await User.find({});
  for (const u of users) {
    console.log(`User: ${u._id} | Name: "${u.fullName}" | Email: "${u.email}" | Phone: "${u.phoneNumber}"`);
  }

  console.log('\n--- ALL DIRECTORY REQUESTS ---');
  const reqs = await DirectoryRequest.find({});
  for (const r of reqs) {
    console.log(`Req: ${r._id} | senderId: "${r.senderId}" | senderName: "${r.senderName}" | senderEmail: "${r.senderEmail}" | receiverId: "${r.receiverId}" | receiverName: "${r.receiverName}" | receiverEmail: "${r.receiverEmail}" | status: "${r.status}"`);
  }

  await mongoose.connection.close();
}

inspect().catch(console.error);
