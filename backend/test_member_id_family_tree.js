require('dotenv').config();
const mongoose = require('mongoose');
const Counter = require('./models/Counter');
const Member = require('./models/Member');
const User = require('./models/User');
const Profile = require('./models/Profile');
const {
  getNextMemberId,
  resolveOrCreateMember,
  searchMembers,
  syncMembersAndBackfill,
  buildFamilyTree,
} = require('./services/memberService');

async function runComprehensiveTests() {
  const uri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/kutumbsetu';
  await mongoose.connect(uri);
  console.log('--- CONNECTED TO MONGODB ---');

  // TEST 1: Sync and Backfill
  console.log('\n--- TEST 1: Testing syncMembersAndBackfill() ---');
  await syncMembersAndBackfill();

  // TEST 2: Verify Single Permanent Member ID for Every Person
  console.log('\n--- TEST 2: Verifying Exactly ONE Permanent Member ID per Individual ---');
  const rishikMembers = await Member.find({
    $or: [
      { fullName: /^rishik(\s+alak)?\s+jariwala$/i },
      { email: 'rishikjariwala54@gmail.com' },
      { email: 'rishikjariwala271@gmail.com' }
    ]
  });
  console.log(`Rishik Member records count: ${rishikMembers.length}`);
  if (rishikMembers.length !== 1) {
    throw new Error(`FAILED: Expected exactly 1 Member record for Rishik Jariwala, found ${rishikMembers.length}`);
  }
  const rishik = rishikMembers[0];
  console.log(`Canonical Rishik: ${rishik.fullName} -> Permanent ID: ${rishik.memberId}`);

  const alakMembers = await Member.find({ fullName: /^alak\s+jariwala$/i });
  console.log(`Alak Member records count: ${alakMembers.length}`);
  if (alakMembers.length !== 1) {
    throw new Error(`FAILED: Expected exactly 1 Member record for Alak Jariwala, found ${alakMembers.length}`);
  }
  const alak = alakMembers[0];
  console.log(`Canonical Alak: ${alak.fullName} -> Permanent ID: ${alak.memberId}`);

  const payalMembers = await Member.find({ fullName: /^payal\s+jariwala$/i });
  console.log(`Payal Member records count: ${payalMembers.length}`);
  if (payalMembers.length !== 1) {
    throw new Error(`FAILED: Expected exactly 1 Member record for Payal Jariwala, found ${payalMembers.length}`);
  }
  const payal = payalMembers[0];
  console.log(`Canonical Payal: ${payal.fullName} -> Permanent ID: ${payal.memberId} (Maiden: ${payal.maidenName})`);

  const dineshMembers = await Member.find({ fullName: /^dinesh\s+jariwala$/i });
  const urmiMembers = await Member.find({ fullName: /^urmi\s+jariwala$/i });
  const dilipMembers = await Member.find({ fullName: /^dilip\s+gandhi$/i });
  const arunaMembers = await Member.find({ fullName: /^aruna\s+gandhi$/i });

  if (dineshMembers.length !== 1) throw new Error(`Expected 1 Dinesh, found ${dineshMembers.length}`);
  if (urmiMembers.length !== 1) throw new Error(`Expected 1 Urmi, found ${urmiMembers.length}`);
  if (dilipMembers.length !== 1) throw new Error(`Expected 1 Dilip, found ${dilipMembers.length}`);
  if (arunaMembers.length !== 1) throw new Error(`Expected 1 Aruna, found ${arunaMembers.length}`);

  const dinesh = dineshMembers[0];
  const urmi = urmiMembers[0];
  const dilip = dilipMembers[0];
  const aruna = arunaMembers[0];

  console.log(`Dinesh: ${dinesh.memberId}, Urmi: ${urmi.memberId}, Dilip: ${dilip.memberId}, Aruna: ${aruna.memberId}`);

  // TEST 3: Verify Canonical ID-Based Relationships
  console.log('\n--- TEST 3: Verifying ID-Based Relationships ---');
  if (rishik.fatherId !== alak.memberId) throw new Error(`Rishik fatherId (${rishik.fatherId}) != Alak ID (${alak.memberId})`);
  if (rishik.motherId !== payal.memberId) throw new Error(`Rishik motherId (${rishik.motherId}) != Payal ID (${payal.memberId})`);
  if (alak.fatherId !== dinesh.memberId) throw new Error(`Alak fatherId (${alak.fatherId}) != Dinesh ID (${dinesh.memberId})`);
  if (alak.motherId !== urmi.memberId) throw new Error(`Alak motherId (${alak.motherId}) != Urmi ID (${urmi.memberId})`);
  if (payal.fatherId !== dilip.memberId) throw new Error(`Payal fatherId (${payal.fatherId}) != Dilip ID (${dilip.memberId})`);
  if (payal.motherId !== aruna.memberId) throw new Error(`Payal motherId (${payal.motherId}) != Aruna ID (${aruna.memberId})`);
  console.log('SUCCESS: All family relationships point to canonical Member IDs!');

  // TEST 4: Primary Name-Based Search & Maiden Surname Matching
  console.log('\n--- TEST 4: Testing searchMembers() ---');
  const searchAlak = await searchMembers({ query: 'Alak' });
  console.log(`Search "Alak" found ${searchAlak.length} member(s):`, searchAlak.map(m => `${m.fullName} (${m.memberId})`));
  if (!searchAlak.some(m => m.memberId === alak.memberId)) throw new Error('Search "Alak" failed to find Alak Jariwala');

  const searchPayalMarried = await searchMembers({ query: 'Payal Jariwala' });
  console.log(`Search "Payal Jariwala" found ${searchPayalMarried.length} member(s):`, searchPayalMarried.map(m => `${m.fullName} (${m.memberId})`));
  if (searchPayalMarried.length !== 1 || searchPayalMarried[0].memberId !== payal.memberId) {
    throw new Error('Search "Payal Jariwala" returned unexpected results');
  }

  const searchPayalMaiden = await searchMembers({ query: 'Payal Gandhi' });
  console.log(`Search "Payal Gandhi" (Maiden Surname) found ${searchPayalMaiden.length} member(s):`, searchPayalMaiden.map(m => `${m.fullName} (${m.memberId}, Maiden: ${m.maidenName})`));
  if (!searchPayalMaiden.some(m => m.memberId === payal.memberId)) throw new Error('Search "Payal Gandhi" failed to match Payal via maidenName');

  const searchGandhi = await searchMembers({ query: 'Gandhi' });
  console.log(`Search "Gandhi" found ${searchGandhi.length} member(s):`, searchGandhi.map(m => `${m.fullName} (${m.memberId})`));
  if (!searchGandhi.some(m => m.memberId === dilip.memberId)) throw new Error('Search "Gandhi" failed to find Dilip Gandhi');
  console.log('SUCCESS: Name-based search and maiden surname matching passed!');

  // TEST 5: Duplicate Prevention
  console.log('\n--- TEST 5: Testing Duplicate Prevention on Member Creation ---');
  const countBefore = await Member.countDocuments();
  const resolvedAlak = await resolveOrCreateMember({ name: 'Alak Jariwala', gender: 'Male' });
  const countAfter = await Member.countDocuments();
  console.log(`Resolved Alak ID: ${resolvedAlak.memberId}. Member count before: ${countBefore}, after: ${countAfter}`);
  if (countBefore !== countAfter) throw new Error('FAILED: Duplicate member was created for existing Alak Jariwala');
  if (resolvedAlak.memberId !== alak.memberId) throw new Error('FAILED: Resolved Alak ID does not match original Alak ID');
  console.log('SUCCESS: Duplicate prevention verified!');

  // TEST 6: Family Tree Construction for Rishik
  console.log('\n--- TEST 6: Testing buildFamilyTree() for Rishik ---');
  const rishikProfile = await Profile.findOne({ memberId: rishik.memberId });
  const rishikTree = await buildFamilyTree(rishikProfile, 'rishikjariwala54@gmail.com');
  console.log('Rishik Tree Root:', rishikTree ? `${rishikTree.name} (${rishikTree.relation})` : 'NULL');
  console.log('Ancestors children count:', rishikTree ? rishikTree.children.length : 0);
  if (rishikTree && rishikTree.children.length > 0) {
    rishikTree.children.forEach(c => {
      console.log(`  - Grandparent branch: ${c.name} (${c.relation}) with ${c.children.length} descendant(s)`);
      c.children.forEach(gc => {
        console.log(`    * Parent branch: ${gc.name} (${gc.relation}) with ${gc.children.length} child(ren)`);
        gc.children.forEach(ggc => {
          console.log(`      > Self/Child node: ${ggc.name} (${ggc.relation}, ID: ${ggc.id})`);
        });
      });
    });
  }

  // TEST 7: Family Tree Construction for Alak (Father)
  console.log('\n--- TEST 7: Testing buildFamilyTree() for Alak ---');
  const alakTree = await buildFamilyTree(null, null, alak.phoneNumber || 'alak-phone');
  console.log('Alak Tree constructed:', alakTree ? `${alakTree.name} (${alakTree.relation})` : 'NULL');

  console.log('\n========================================');
  console.log('ALL TESTS PASSED WITH 100% SUCCESS!');
  console.log('========================================');

  await mongoose.connection.close();
}

runComprehensiveTests().catch(err => {
  console.error('Test error:', err);
  process.exit(1);
});
