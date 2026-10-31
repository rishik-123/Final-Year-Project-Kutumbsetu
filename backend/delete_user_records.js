const mongoose = require('mongoose');
require('dotenv').config({ path: __dirname + '/.env' });

const emailsToDelete = [
  'rishikjariwala271@gmail.com',
  'rishikjariwala689@gmail.com',
  '23rishikjariwala7b@gmail.com',
  'rishikjariwala54@gmail.com'
];

async function main() {
  const mongoUri = process.env.MONGODB_URI;
  if (!mongoUri) {
    console.error('MONGODB_URI not found in backend/.env');
    process.exit(1);
  }

  await mongoose.connect(mongoUri);
  console.log('Connected to MongoDB Atlas');

  const db = mongoose.connection.db;
  const collections = await db.listCollections().toArray();

  for (const email of emailsToDelete) {
    console.log(`\n==================================================`);
    console.log(`Searching and deleting records for: ${email}`);
    console.log(`==================================================`);

    // Find User IDs associated with this email
    const users = await db.collection('users').find({
      email: { $regex: new RegExp(`^${email}$`, 'i') }
    }).toArray();

    const userIds = users.map(u => u._id);
    const userIdStrings = userIds.map(id => id.toString());

    console.log(`Found ${users.length} user record(s):`, userIdStrings);

    // Also check profiles or members for memberIds
    const members = await db.collection('members').find({
      $or: [
        { email: { $regex: new RegExp(`^${email}$`, 'i') } },
        { userId: { $in: [...userIds, ...userIdStrings] } }
      ]
    }).toArray();
    const memberIds = members.map(m => m._id);

    // Search across all collections in the database
    for (const collInfo of collections) {
      const collName = collInfo.name;
      const coll = db.collection(collName);

      // Build or query to check for email or userId references
      const queryOr = [
        { email: { $regex: new RegExp(`^${email}$`, 'i') } },
        { userEmail: { $regex: new RegExp(`^${email}$`, 'i') } },
        { 'contactEmail': { $regex: new RegExp(`^${email}$`, 'i') } }
      ];

      if (userIds.length > 0) {
        queryOr.push({ userId: { $in: [...userIds, ...userIdStrings] } });
        queryOr.push({ user: { $in: [...userIds, ...userIdStrings] } });
        queryOr.push({ authorId: { $in: [...userIds, ...userIdStrings] } });
        queryOr.push({ senderId: { $in: [...userIds, ...userIdStrings] } });
        queryOr.push({ receiverId: { $in: [...userIds, ...userIdStrings] } });
        queryOr.push({ createdBy: { $in: [...userIds, ...userIdStrings] } });
      }

      if (memberIds.length > 0) {
        queryOr.push({ memberId: { $in: memberIds } });
      }

      // Also if collection is 'users', match _id directly
      if (collName === 'users' && userIds.length > 0) {
        queryOr.push({ _id: { $in: userIds } });
      }

      try {
        const count = await coll.countDocuments({ $or: queryOr });
        if (count > 0) {
          const deleteResult = await coll.deleteMany({ $or: queryOr });
          console.log(`[${collName}] Deleted ${deleteResult.deletedCount} record(s).`);
        }
      } catch (err) {
        // Some collections might have schema constraints or indexed fields not matching $or
        // Check by field if needed
      }
    }
  }

  console.log('\nFinished cleanup successfully.');
  await mongoose.disconnect();
}

main().catch(err => {
  console.error('Error during deletion:', err);
  process.exit(1);
});

