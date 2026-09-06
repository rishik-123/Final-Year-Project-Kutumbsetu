const { MongoClient } = require('mongodb');

const LOCAL_URI = 'mongodb://127.0.0.1:27017/kutumbsetu';
const ATLAS_URI = 'mongodb+srv://admin:adminpass123@kutumbsetu.zd2txth.mongodb.net/kutumbsetu?retryWrites=true&w=majority&appName=KutumbSetu';

async function migrateData() {
  console.log('🚀 Starting Database Migration: Local MongoDB ➔ MongoDB Cloud Atlas...\n');

  let localClient, atlasClient;

  try {
    console.log('📡 Connecting to Local MongoDB (127.0.0.1:27017)...');
    localClient = await MongoClient.connect(LOCAL_URI, { serverSelectionTimeoutMS: 5000 });
    const localDb = localClient.db('kutumbsetu');
    console.log('✅ Connected to Local MongoDB.');

    console.log('📡 Connecting to MongoDB Atlas Cloud...');
    atlasClient = await MongoClient.connect(ATLAS_URI, { serverSelectionTimeoutMS: 10000 });
    const atlasDb = atlasClient.db('kutumbsetu');
    console.log('✅ Connected to MongoDB Atlas Cloud.\n');

    const collections = await localDb.listCollections().toArray();
    console.log(`📋 Found ${collections.length} collections to transfer.\n`);

    let totalMigratedDocs = 0;

    for (const collInfo of collections) {
      const collName = collInfo.name;
      if (collName.startsWith('system.')) continue;

      const localColl = localDb.collection(collName);
      const atlasColl = atlasDb.collection(collName);

      const docs = await localColl.find({}).toArray();

      if (docs.length === 0) {
        console.log(`  ⚪ [${collName}] 0 documents (skipped)`);
        continue;
      }

      // Upsert each document by _id to avoid duplicate key errors
      const operations = docs.map(doc => ({
        replaceOne: {
          filter: { _id: doc._id },
          replacement: doc,
          upsert: true,
        },
      }));

      const result = await atlasColl.bulkWrite(operations, { ordered: false });
      const count = (result.upsertedCount || 0) + (result.modifiedCount || 0) + (result.matchedCount || 0);
      totalMigratedDocs += docs.length;

      console.log(`  ✅ [${collName}] Successfully exported ${docs.length} documents.`);
    }

    console.log('\n========================================================');
    console.log(`🎉 MIGRATION COMPLETE! Total ${totalMigratedDocs} documents transferred to Atlas.`);
    console.log('========================================================\n');

  } catch (error) {
    console.error('\n❌ Migration Failed:', error.message);
  } finally {
    if (localClient) await localClient.close();
    if (atlasClient) await atlasClient.close();
  }
}

migrateData();
