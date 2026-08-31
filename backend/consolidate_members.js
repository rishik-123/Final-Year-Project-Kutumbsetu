require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./models/User');
const Profile = require('./models/Profile');
const Member = require('./models/Member');
const Counter = require('./models/Counter');

async function consolidateAllMembers() {
  const uri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/kutumbsetu';
  await mongoose.connect(uri);
  console.log('Connected to MongoDB for Deep Audit & Consolidation');

  // 1. Audit all Members
  const allMembers = await Member.find({});
  console.log(`Starting with ${allMembers.length} member records.`);

  // 2. Identify and consolidate Rishik Jariwala
  // Rishik should be MEM001 (or single canonical ID)
  // Let's find all Member records for Rishik
  const rishikMemberRecords = await Member.find({
    $or: [
      { fullName: { $regex: /rishik/i } },
      { email: { $regex: /rishikjariwala/i } },
      { memberId: { $in: ['MEM001', 'MEM002', 'MEM035'] } }
    ],
    fullName: { $not: /rishi ketan soni/i } // Exclude Rishi Ketan Soni
  });

  console.log('\nFound Rishik Member Records to consolidate:');
  rishikMemberRecords.forEach(m => console.log(` - ID: ${m.memberId}, Name: "${m.fullName}", Phone: "${m.phoneNumber}", Email: "${m.email}", UserId: ${m.userId}`));

  // Canonical Rishik ID is MEM001
  const canonicalRishikId = 'MEM001';
  let canonicalRishik = await Member.findOne({ memberId: canonicalRishikId });
  if (!canonicalRishik && rishikMemberRecords.length > 0) {
    canonicalRishik = rishikMemberRecords[0];
  }

  // Update canonical Rishik with full details
  canonicalRishik.memberId = canonicalRishikId;
  canonicalRishik.fullName = 'Rishik Jariwala';
  canonicalRishik.firstName = 'Rishik';
  canonicalRishik.middleName = 'Alak';
  canonicalRishik.lastName = 'Jariwala';
  canonicalRishik.gender = 'Male';
  canonicalRishik.email = 'rishikjariwala54@gmail.com';
  canonicalRishik.phoneNumber = '+919136091620';
  canonicalRishik.city = 'Surat';
  canonicalRishik.village = 'Surat';
  canonicalRishik.fatherId = 'MEM050';
  canonicalRishik.fatherName = 'Alak Jariwala';
  canonicalRishik.motherId = 'MEM051';
  canonicalRishik.motherName = 'Payal Jariwala';
  canonicalRishik.paternalGrandfatherId = 'MEM046';
  canonicalRishik.grandfather = 'Dinesh Jariwala';
  canonicalRishik.paternalGrandmotherId = 'MEM047';
  canonicalRishik.grandmother = 'Urmi Jariwala';
  canonicalRishik.maternalGrandfatherId = 'MEM048';
  canonicalRishik.nana = 'Dilip Gandhi';
  canonicalRishik.maternalGrandmotherId = 'MEM049';
  canonicalRishik.nani = 'Aruna Gandhi';
  canonicalRishik.familyId = 'JARIWALA-01';
  await canonicalRishik.save();

  // Find all old Rishik Member IDs
  const oldRishikIds = rishikMemberRecords
    .map(m => m.memberId)
    .filter(id => id !== canonicalRishikId);

  console.log(`Old duplicate Rishik IDs being consolidated into ${canonicalRishikId}:`, oldRishikIds);

  // Remove duplicate Rishik Member documents
  if (oldRishikIds.length > 0) {
    await Member.deleteMany({ memberId: { $in: oldRishikIds } });
  }

  // Update all Users with Rishik in email or name to point to canonical MEM001
  const rishikUserDocs = await User.find({
    $or: [
      { email: 'rishikjariwala54@gmail.com' },
      { email: 'rishikjariwala271@gmail.com' },
      { email: 'rishikjariwala689@gmail.com' },
      { phoneNumber: { $in: ['+919136091620', '+919136091621', '+919136091628', '+911234567980', '9136091620', '9136091628'] } },
      { fullName: { $in: ['Rishik', 'Rishik Jariwala', 'Rishik alak jariwala', 'Rishik Alak Jariwala'] } }
    ]
  });

  for (const u of rishikUserDocs) {
    const prof = await Profile.findOne({ userId: u._id });
    if (prof) {
      prof.memberId = canonicalRishikId;
      prof.fatherId = 'MEM050';
      prof.fatherName = 'Alak Jariwala';
      prof.motherId = 'MEM051';
      prof.motherName = 'Payal Jariwala';
      prof.paternalGrandfatherId = 'MEM046';
      prof.grandfather = 'Dinesh Jariwala';
      prof.paternalGrandmotherId = 'MEM047';
      prof.grandmother = 'Urmi Jariwala';
      prof.maternalGrandfatherId = 'MEM048';
      prof.nana = 'Dilip Gandhi';
      prof.maternalGrandmotherId = 'MEM049';
      prof.nani = 'Aruna Gandhi';
      await prof.save();
    }
  }

  // Update any member / profile referencing old Rishik IDs as father/spouse/etc.
  if (oldRishikIds.length > 0) {
    await Member.updateMany({ fatherId: { $in: oldRishikIds } }, { $set: { fatherId: canonicalRishikId, fatherName: 'Rishik Jariwala' } });
    await Member.updateMany({ motherId: { $in: oldRishikIds } }, { $set: { motherId: canonicalRishikId } });
    await Member.updateMany({ spouseId: { $in: oldRishikIds } }, { $set: { spouseId: canonicalRishikId } });
    await Profile.updateMany({ fatherId: { $in: oldRishikIds } }, { $set: { fatherId: canonicalRishikId, fatherName: 'Rishik Jariwala' } });
    await Profile.updateMany({ memberId: { $in: oldRishikIds } }, { $set: { memberId: canonicalRishikId } });
  }

  // 3. Consolidate other duplicates (Nirmay Patel, Tatva Jain, Ram)
  // Nirmay Patel
  const nirmayMembers = await Member.find({ fullName: { $regex: /nirmay/i } });
  if (nirmayMembers.length > 1) {
    console.log('\nConsolidating Nirmay Patel members:', nirmayMembers.map(m => m.memberId));
    const canonicalNirmay = nirmayMembers[0];
    const otherNirmayIds = nirmayMembers.slice(1).map(m => m.memberId);
    canonicalNirmay.fullName = 'Nirmay Pankaj Patel';
    canonicalNirmay.email = 'nirmaypatel73@gmail.com';
    canonicalNirmay.phoneNumber = '+919866986688';
    await canonicalNirmay.save();
    await Member.deleteMany({ memberId: { $in: otherNirmayIds } });
    await Profile.updateMany({ memberId: { $in: otherNirmayIds } }, { $set: { memberId: canonicalNirmay.memberId } });
  }

  // Tatva Jain
  const tatvaMembers = await Member.find({ fullName: { $regex: /tatva/i } });
  if (tatvaMembers.length > 1) {
    console.log('\nConsolidating Tatva Jain members:', tatvaMembers.map(m => m.memberId));
    const canonicalTatva = tatvaMembers[0];
    const otherTatvaIds = tatvaMembers.slice(1).map(m => m.memberId);
    canonicalTatva.fullName = 'Tatva Manish Jain';
    canonicalTatva.email = 'tatvajain110907@gmail.com';
    canonicalTatva.phoneNumber = '9585312444';
    await canonicalTatva.save();
    await Member.deleteMany({ memberId: { $in: otherTatvaIds } });
    await Profile.updateMany({ memberId: { $in: otherTatvaIds } }, { $set: { memberId: canonicalTatva.memberId } });
  }

  // 4. Verify Final State
  console.log('\n--- FINAL VERIFICATION AFTER CONSOLIDATION ---');
  const finalRishik = await Member.find({ fullName: { $regex: /rishik/i } });
  console.log('Rishik Members count:', finalRishik.length);
  finalRishik.forEach(m => console.log(`   * ID: ${m.memberId}, Name: ${m.fullName}, Phone: ${m.phoneNumber}, Email: ${m.email}`));

  const allFinalMembers = await Member.find({}).sort({ memberId: 1 });
  console.log(`Total active Member records in DB: ${allFinalMembers.length}`);

  await mongoose.connection.close();
}

consolidateAllMembers().catch(console.error);
