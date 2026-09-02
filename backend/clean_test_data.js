require('dotenv').config();
const mongoose = require('mongoose');

async function fixDatabase() {
  const uri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/kutumbsetu';
  await mongoose.connect(uri);

  const User = mongoose.model('User', new mongoose.Schema({}, { strict: false }));
  const DirectoryRequest = mongoose.model('DirectoryRequest', new mongoose.Schema({}, { strict: false }));

  // 1. Remove or update "Campaign Test User"
  const deletedTestUsers = await User.deleteMany({
    $or: [
      { fullName: 'Campaign Test User' },
      { phoneNumber: '+919888877777' }
    ]
  });
  console.log(`Deleted test users:`, deletedTestUsers);

  // 2. Clear out existing bogus directory requests
  const deletedReqs = await DirectoryRequest.deleteMany({
    $or: [
      { senderName: 'Campaign Test User' },
      { senderId: '6a79989a1f27081fecd3d9f0' },
      { senderId: '6a7962b212a58c4a0e118cab' }
    ]
  });
  console.log(`Deleted bogus directory requests:`, deletedReqs);

  // 3. Check Arya Ambokar and Nirmay Patel in User collection
  const arya = await User.findOne({ email: 'aryaambokar@gmail.com' });
  console.log('Arya Ambokar User:', arya ? { id: arya._id, name: arya.fullName, email: arya.email } : 'Not found');

  const nirmay = await User.findOne({ email: 'nirmaypatel73@gmail.com' });
  console.log('Nirmay Patel User:', nirmay ? { id: nirmay._id, name: nirmay.fullName, email: nirmay.email } : 'Not found');

  await mongoose.connection.close();
}

fixDatabase().catch(console.error);
