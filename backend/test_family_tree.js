require('dotenv').config();
const mongoose = require('mongoose');
const http = require('http');
const User = require('./models/User');

const PORT = 5000;
const BASE_URL = `http://localhost:${PORT}`;

const requestGet = (path, phone) => {
  return new Promise((resolve, reject) => {
    const url = `${BASE_URL}${path}`;

    const options = {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        'x-user-phone': phone,
      },
    };

    const req = http.request(url, options, (res) => {
      let responseBody = '';
      res.on('data', (chunk) => {
        responseBody += chunk;
      });

      res.on('end', () => {
        resolve({
          statusCode: res.statusCode,
          headers: res.headers,
          body: responseBody ? JSON.parse(responseBody) : null,
        });
      });
    });

    req.on('error', (err) => {
      reject(err);
    });

    req.end();
  });
};

const seedTestData = async () => {
  console.log('Connecting to database to seed test family tree data...');
  const uri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/kutumbsetu';
  await mongoose.connect(uri);

  const testFamilyId = 'TEST-CHAUHAN-999';

  // Clean up existing test data
  console.log('Cleaning up existing test data...');
  await User.deleteMany({ familyId: testFamilyId });
  await User.DirectoryUser.deleteMany({ familyId: testFamilyId });

  // 1. Create Self
  const selfUser = new User({
    fullName: 'Rajeshbhai',
    surname: 'Chauhan',
    phoneNumber: '+919990001111',
    gender: 'Male',
    dateOfBirth: '1985-05-12',
    city: 'Vadodara',
    familyId: testFamilyId,
    familyName: 'Chauhan',
    relationshipToHead: 'Self',
    familyHeadPhone: '+919990001111',
    profilePhoto: 'avatar_male_1'
  });
  await selfUser.save();

  // 2. Create Spouse
  const wifeUser = new User({
    fullName: 'Priyaben',
    surname: 'Chauhan',
    phoneNumber: '+919990002222',
    gender: 'Female',
    dateOfBirth: '1988-08-20',
    city: 'Vadodara',
    familyId: testFamilyId,
    familyName: 'Chauhan',
    relationshipToHead: 'Wife',
    familyHeadPhone: '+919990001111',
    profilePhoto: 'avatar_female_1'
  });
  await wifeUser.save();

  // 3. Create Son
  const sonUser = new User({
    fullName: 'Amit',
    surname: 'Chauhan',
    phoneNumber: '+919990003333',
    gender: 'Male',
    dateOfBirth: '2012-04-15',
    city: 'Vadodara',
    familyId: testFamilyId,
    familyName: 'Chauhan',
    relationshipToHead: 'Son',
    familyHeadPhone: '+919990001111',
    profilePhoto: 'avatar_male_2'
  });
  await sonUser.save();

  console.log('Test family tree data seeded successfully.\n');
  await mongoose.connection.close();
};

const runTests = async () => {
  console.log('--- STARTING FAMILY TREE API INTEGRATION TESTS ---');
  
  // Seed DB first
  await seedTestData();

  const userPhone = '+919990001111';

  try {
    console.log('Calling GET /api/family/my-tree...');
    const res = await requestGet('/api/family/my-tree', userPhone);
    
    console.log('Status Code:', res.statusCode);
    console.log('Response Body:', JSON.stringify(res.body, null, 2));

    if (res.statusCode !== 200) {
      console.error(`FAIL: API returned status ${res.statusCode}`);
      process.exit(1);
    }

    if (!res.body.success) {
      console.error('FAIL: API response success field is false');
      process.exit(1);
    }

    const tree = res.body.tree;
    if (!tree) {
      console.error('FAIL: No tree returned in API response');
      process.exit(1);
    }

    // Verify self node
    if (tree.name !== 'Rajeshbhai Chauhan' || tree.relation !== 'Self') {
      console.error(`FAIL: Expected root to be Self (Rajeshbhai Chauhan), got name: "${tree.name}", relation: "${tree.relation}"`);
      process.exit(1);
    }

    // Verify children count
    if (tree.children.length !== 2) {
      console.error(`FAIL: Expected 2 children (Wife & Son) under Self, got: ${tree.children.length}`);
      process.exit(1);
    }

    const spouseChild = tree.children.find(c => c.relation === 'Wife');
    const sonChild = tree.children.find(c => c.relation === 'Son');

    if (!spouseChild || spouseChild.name !== 'Priyaben Chauhan') {
      console.error('FAIL: Wife child (Priyaben Chauhan) missing or incorrect in tree');
      process.exit(1);
    }

    if (!sonChild || sonChild.name !== 'Amit Chauhan') {
      console.error('FAIL: Son child (Amit Chauhan) missing or incorrect in tree');
      process.exit(1);
    }

    console.log('\nPASS: My Family Tree hierarchy built and validated successfully!');
    
    // Clean up test data
    console.log('Connecting to database for test data cleanup...');
    const uri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/kutumbsetu';
    await mongoose.connect(uri);
    const testFamilyId = 'TEST-CHAUHAN-999';
    await User.deleteMany({ familyId: testFamilyId });
    await User.DirectoryUser.deleteMany({ familyId: testFamilyId });
    await mongoose.connection.close();
    console.log('Test data cleaned up successfully.');

    console.log('--- ALL FAMILY TREE TESTS PASSED SUCCESSFULLY ---');
    process.exit(0);
  } catch (error) {
    console.error('FAIL: Error running integration tests:', error);
    process.exit(1);
  }
};

// Wait 1.5 seconds before running to ensure server is ready
setTimeout(runTests, 1500);
