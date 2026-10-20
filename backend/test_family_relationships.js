require('dotenv').config();
const mongoose = require('mongoose');
const Member = require('./models/Member');
const User = require('./models/User');
const Profile = require('./models/Profile');
const { buildFamilyTree } = require('./services/memberService');

async function testFamilyLogic() {
  await mongoose.connect(process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/kutumbsetu');
  console.log('--- CONNECTED TO MONGODB FOR FAMILY RELATIONSHIP VERIFICATION ---');

  const rishik = await Member.findOne({ memberId: 'MEM001' });
  const alak = await Member.findOne({ memberId: 'MEM050' });
  const payal = await Member.findOne({ $or: [{ memberId: 'MEM122' }, { memberId: 'MEM051' }, { fullName: /payal/i }] });

  console.log('Rishik:', rishik ? `${rishik.fullName} (${rishik.memberId})` : 'MISSING');
  console.log('Alak:', alak ? `${alak.fullName} (${alak.memberId})` : 'MISSING');
  console.log('Payal:', payal ? `${payal.fullName} (${payal.memberId})` : 'MISSING');

  // Ensure Payal and Alak have canonical phone and email if missing
  if (alak && !alak.phoneNumber) {
    alak.phoneNumber = '+919136091624';
    alak.email = 'alak.jariwala@example.com';
    await alak.save();
  }
  if (payal && !payal.phoneNumber) {
    payal.phoneNumber = '+919136091625';
    payal.email = 'payal.jariwala@example.com';
    payal.gender = 'Female';
    payal.fullName = 'Payal Jariwala';
    await payal.save();
  }

  // Ensure Users exist for Alak and Payal for login tests
  let alakUser = await User.findOne({ phoneNumber: alak.phoneNumber });
  if (!alakUser) {
    alakUser = new User({
      fullName: 'Alak Jariwala',
      phoneNumber: alak.phoneNumber,
      email: alak.email,
      role: 'user',
      isApproved: true,
    });
    await alakUser.save();
  }
  if (!alak.userId) {
    alak.userId = alakUser._id;
    await alak.save();
  }

  let payalUser = await User.findOne({ phoneNumber: payal.phoneNumber });
  if (!payalUser) {
    payalUser = new User({
      fullName: 'Payal Jariwala',
      phoneNumber: payal.phoneNumber,
      email: payal.email,
      role: 'user',
      isApproved: true,
    });
    await payalUser.save();
  }
  if (!payal.userId) {
    payal.userId = payalUser._id;
    await payal.save();
  }

  // 1. TEST CHILD PERSPECTIVE (Rishik)
  console.log('\n=============================================');
  console.log('TEST 1: Child (Rishik) Logs In');
  console.log('=============================================');
  // Helper to validate and print tree perspective
  function validatePerspective(perspectiveName, tree, expectedSelfId, expectedFatherRel, expectedMotherRel, expectedChildRel) {
    console.log(`\n=============================================`);
    console.log(`TEST: ${perspectiveName}`);
    console.log(`=============================================`);
    if (!tree) {
      console.error(`FAIL: Tree is null for ${perspectiveName}`);
      return false;
    }

    const allNodes = [];
    collectNodesInList(tree, allNodes);

    console.log(`Total nodes in tree: ${allNodes.length}`);
    const distinctMap = new Map();
    allNodes.forEach(n => {
      if (!distinctMap.has(n.id)) {
        distinctMap.set(n.id, n);
      }
    });

    console.log('Distinct Members in View:');
    for (const [id, n] of distinctMap.entries()) {
      console.log(`  - [${id}] ${n.name}: relation="${n.relation}", isSelf=${n.isSelf}`);
    }

    // 1. Check self
    const selfNode = allNodes.find(n => n.isSelf);
    if (!selfNode || selfNode.id !== expectedSelfId) {
      console.error(`FAIL: Expected self node ID to be ${expectedSelfId}, got ${selfNode ? selfNode.id : 'NONE'}`);
      return false;
    }
    console.log(`PASS: Self node correctly identified as ${selfNode.name} (${selfNode.relation})`);

    // 2. Check Father
    const fNode = distinctMap.get('MEM050');
    if (!fNode || fNode.relation !== expectedFatherRel) {
      console.error(`FAIL: Expected Father (MEM050) relation="${expectedFatherRel}", got "${fNode ? fNode.relation : 'MISSING'}"`);
      return false;
    }
    console.log(`PASS: Father correctly mapped as relation="${fNode.relation}"`);

    // 3. Check Mother
    const mNode = distinctMap.get('MEM122');
    if (!mNode || mNode.relation !== expectedMotherRel) {
      console.error(`FAIL: Expected Mother (MEM122) relation="${expectedMotherRel}", got "${mNode ? mNode.relation : 'MISSING'}"`);
      return false;
    }
    console.log(`PASS: Mother correctly mapped as relation="${mNode.relation}"`);

    // 4. Check Child
    const cNode = distinctMap.get('MEM001');
    if (!cNode || cNode.relation !== expectedChildRel) {
      console.error(`FAIL: Expected Child (MEM001) relation="${expectedChildRel}", got "${cNode ? cNode.relation : 'MISSING'}"`);
      return false;
    }
    console.log(`PASS: Child correctly mapped as relation="${cNode.relation}"`);

    // 5. Check Paternal Grandparents (Dinesh MEM046, Urmi MEM047)
    const patGf = distinctMap.get('MEM046');
    const patGm = distinctMap.get('MEM047');
    if (!patGf || patGf.relation !== 'Grandfather') {
      console.error(`FAIL: Paternal Grandfather missing or wrong relation`);
      return false;
    }
    if (!patGm || patGm.relation !== 'Grandmother') {
      console.error(`FAIL: Paternal Grandmother missing or wrong relation`);
      return false;
    }
    console.log(`PASS: Paternal Grandparents (Grandfather & Grandmother) correctly mapped`);

    // 6. Check Maternal Grandparents (Dilip MEM048, Aruna MEM049)
    const matGf = distinctMap.get('MEM048');
    const matGm = distinctMap.get('MEM049');
    if (!matGf || matGf.relation !== 'Nana') {
      console.error(`FAIL: Maternal Grandfather (Nana) missing or wrong relation`);
      return false;
    }
    if (!matGm || matGm.relation !== 'Nani') {
      console.error(`FAIL: Maternal Grandmother (Nani) missing or wrong relation`);
      return false;
    }
    console.log(`PASS: Maternal Grandparents (Nana & Nani) correctly mapped`);

    // 7. Verify both Father and Mother have Child in their children list
    const fatherHasChild = fNode.children && fNode.children.some(c => c.id === 'MEM001');
    const motherHasChild = mNode.children && mNode.children.some(c => c.id === 'MEM001');
    if (!fatherHasChild || !motherHasChild) {
      console.error(`FAIL: Child not linked under both parents (fatherHasChild=${fatherHasChild}, motherHasChild=${motherHasChild})`);
      return false;
    }
    console.log(`PASS: Both parents reference the exact same child record (MEM001)`);

    return true;
  }

  // 1. TEST CHILD PERSPECTIVE (Rishik)
  const rishikProf = await Profile.findOne({ memberId: rishik.memberId });
  const rishikTree = await buildFamilyTree(rishikProf, rishik.email, rishik.phoneNumber);
  const test1 = validatePerspective('Child (Rishik) Perspective', rishikTree, 'MEM001', 'Father', 'Mother', 'Self');

  // 2. TEST FATHER PERSPECTIVE (Alak)
  const alakProf = await Profile.findOne({ memberId: alak.memberId });
  const alakTree = await buildFamilyTree(alakProf, alak.email, alak.phoneNumber);
  const test2 = validatePerspective('Father (Alak) Perspective', alakTree, 'MEM050', 'Self', 'Wife', 'Son');

  // 3. TEST MOTHER PERSPECTIVE (Payal)
  const payalProf = await Profile.findOne({ memberId: payal.memberId });
  const payalTree = await buildFamilyTree(payalProf, payal.email, payal.phoneNumber);
  const test3 = validatePerspective('Mother (Payal) Perspective', payalTree, 'MEM122', 'Husband', 'Self', 'Son');

  if (test1 && test2 && test3) {
    console.log('\n=============================================');
    console.log('ALL PERSPECTIVE TEST CASES PASSED SUCCESSFULLY!');
    console.log('=============================================');
  } else {
    console.error('\nSOME TEST CASES FAILED');
  }

  await mongoose.connection.close();
}

function collectNodesInList(node, list) {
  list.push(node);
  (node.children || []).forEach(c => collectNodesInList(c, list));
}

testFamilyLogic().catch(console.error);
