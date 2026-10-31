require('dotenv').config();
const mongoose = require('mongoose');

const targetEmail = (process.argv[2] || 'rishikjariwala54@gmail.com').toLowerCase().trim();

async function deleteUserByEmail() {
  const uri = process.env.MONGODB_URI;
  if (!uri) {
    console.error('❌ Error: MONGODB_URI not found in backend/.env');
    process.exit(1);
  }

  console.log(`Connecting to MongoDB...`);
  try {
    await mongoose.connect(uri, { serverSelectionTimeoutMS: 8000 });
    console.log(`Connected successfully to database: ${mongoose.connection.name}`);
  } catch (err) {
    console.error('❌ Connection failed:', err.message);
    process.exit(1);
  }

  const db = mongoose.connection.db;
  const collections = await db.listCollections().toArray();
  console.log(`Scanning ${collections.length} collections for: "${targetEmail}"...\n`);

  // 1. Locate primary user record
  const usersColl = db.collection('users');
  const userDocs = await usersColl.find({
    $or: [
      { email: { $regex: new RegExp(`^${targetEmail}$`, 'i') } },
      { username: { $regex: new RegExp(`^${targetEmail}$`, 'i') } }
    ]
  }).toArray();

  const userIds = userDocs.map(u => u._id);
  const userPhoneNumbers = userDocs.map(u => u.phoneNumber).filter(Boolean);

  console.log(`Found ${userDocs.length} matching user(s) in 'users' collection.`);
  if (userIds.length > 0) console.log('Associated User ID(s):', userIds);
  if (userPhoneNumbers.length > 0) console.log('Associated Phone Number(s):', userPhoneNumbers);

  const report = {};

  for (const colInfo of collections) {
    const colName = colInfo.name;
    const col = db.collection(colName);

    const conditions = [
      { email: { $regex: new RegExp(`^${targetEmail}$`, 'i') } },
      { contactEmail: { $regex: new RegExp(`^${targetEmail}$`, 'i') } },
      { 'contact.email': { $regex: new RegExp(`^${targetEmail}$`, 'i') } }
    ];

    if (userIds.length > 0) {
      conditions.push({ userId: { $in: userIds } });
      conditions.push({ authorId: { $in: userIds } });
      conditions.push({ requesterId: { $in: userIds } });
      conditions.push({ targetId: { $in: userIds } });
      conditions.push({ senderId: { $in: userIds } });
      conditions.push({ receiverId: { $in: userIds } });
      conditions.push({ _id: { $in: userIds } });
    }

    if (userPhoneNumbers.length > 0) {
      conditions.push({ phoneNumber: { $in: userPhoneNumbers } });
      conditions.push({ mobileNumber: { $in: userPhoneNumbers } });
      conditions.push({ phone: { $in: userPhoneNumbers } });
    }

    try {
      const matchCount = await col.countDocuments({ $or: conditions });
      if (matchCount > 0) {
        const delRes = await col.deleteMany({ $or: conditions });
        report[colName] = delRes.deletedCount;
      }
    } catch (e) {
      // Ignore collection-specific query mismatches
    }
  }

  console.log('\n=======================================');
  console.log('       DELETION REPORT SUMMARY         ');
  console.log('=======================================');
  if (Object.keys(report).length === 0) {
    console.log(`No records found for "${targetEmail}" across any collections.`);
  } else {
    for (const [coll, count] of Object.entries(report)) {
      console.log(`✓ Deleted ${count} document(s) from collection: "${coll}"`);
    }
  }
  console.log('=======================================\n');

  await mongoose.disconnect();
  console.log('Disconnected from MongoDB.');
}

deleteUserByEmail().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});

