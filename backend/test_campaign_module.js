require('dotenv').config();
const mongoose = require('mongoose');
const http = require('http');

const PORT = 5000;
const BASE_URL = `http://localhost:${PORT}`;

const request = (urlPath, method, body, headers = {}) => {
  return new Promise((resolve, reject) => {
    const url = `${BASE_URL}${urlPath}`;
    const data = body ? JSON.stringify(body) : null;

    const reqHeaders = {
      'Content-Type': 'application/json',
      ...headers,
    };

    if (data) {
      reqHeaders['Content-Length'] = Buffer.byteLength(data);
    }

    const options = {
      method: method,
      headers: reqHeaders,
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

    if (data) {
      req.write(data);
    }
    req.end();
  });
};

const setupDbConnection = async () => {
  const uri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/kutumbsetu';
  await mongoose.connect(uri, { serverSelectionTimeoutMS: 5000 });
  console.log(`Test suite connected to MongoDB at ${uri}`);
};

const cleanupDatabase = async () => {
  console.log('Connecting to database for cleanup before test...');
  await setupDbConnection();

  const testPhone = '+919888877777';
  console.log(`Cleaning up test user data for ${testPhone}...`);

  const user = await mongoose.connection.db.collection('users').findOne({ phoneNumber: testPhone });
  if (user) {
    await mongoose.connection.db.collection('campaign_registrations').deleteMany({ userId: user._id });
    await mongoose.connection.db.collection('users').deleteOne({ _id: user._id });
  }

  await mongoose.connection.db.collection('campaigns').deleteMany({ title: /Test Campaign/i });
  console.log('Database cleanup completed.\n');
};

const runCampaignTests = async () => {
  console.log('=== STARTING CAMPAIGN MODULE BACKEND TESTS ===\n');
  await cleanupDatabase();

  let userId = null;
  let campaignId = null;
  let registrationId = null;

  // 1. Create Test User
  try {
    console.log('Test 1: Registering Test User...');
    const userRes = await request('/api/users/register', 'POST', {
      fullName: 'Campaign Test User',
      phoneNumber: '+919888877777',
      gender: 'Male',
      dateOfBirth: '1995-05-15',
      city: 'Anand',
      role: 'admin',
    });

    if (userRes.statusCode === 201 && userRes.body.success) {
      userId = userRes.body.user._id;
      console.log(`PASS: Test User Registered. ID: ${userId}`);
    } else {
      console.error('FAIL: User Registration Failed:', userRes.body);
      process.exit(1);
    }
  } catch (err) {
    console.error('FAIL: Test 1 Error:', err.message);
    process.exit(1);
  }

  // 2. Fetch Categories
  try {
    console.log('\nTest 2: Fetching Categories...');
    const catRes = await request('/api/categories', 'GET');
    if (catRes.statusCode === 200 && catRes.body.success && catRes.body.categories.length > 0) {
      console.log(`PASS: Categories Fetched successfully. Total: ${catRes.body.categories.length}`);
    } else {
      console.error('FAIL: Fetch Categories Failed:', catRes.body);
      process.exit(1);
    }
  } catch (err) {
    console.error('FAIL: Test 2 Error:', err.message);
    process.exit(1);
  }

  // 3. Create Campaign (SCRUM-67, SCRUM-69, SCRUM-76)
  try {
    console.log('\nTest 3: Creating Campaign with Dynamic Fields...');
    const startDate = new Date();
    const endDate = new Date(startDate.getTime() + 10 * 24 * 60 * 60 * 1000); // 10 days later

    const campaignData = {
      title: 'Test Campaign — Blood Donation Drive 2026',
      description: 'Annual mega blood donation drive for community welfare.',
      category: 'Blood Donation',
      bannerUrl: '/uploads/campaigns/sample.jpg',
      startDate: startDate.toISOString(),
      endDate: endDate.toISOString(),
      status: 'Active',
      targetAmount: 50000,
      objective: 'Collect 500 units of blood',
      contactInfo: {
        phone: '+919888877777',
        email: 'organizer@kutumbsetu.org',
        organizerName: 'KutumbSetu Admin',
      },
      additionalNotes: 'Refreshments will be provided for all donors.',
      createdBy: userId,
      dynamicFields: [
        {
          fieldName: 'bloodGroup',
          label: 'Blood Group',
          type: 'dropdown',
          required: true,
          options: ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'],
          order: 1,
        },
        {
          fieldName: 'tShirtSize',
          label: 'Volunteer T-Shirt Size',
          type: 'dropdown',
          required: false,
          options: ['S', 'M', 'L', 'XL', 'XXL'],
          order: 2,
        },
      ],
    };

    const campaignRes = await request('/api/campaigns', 'POST', campaignData);
    if (campaignRes.statusCode === 201 && campaignRes.body.success) {
      campaignId = campaignRes.body.campaign._id;
      console.log(`PASS: Campaign Created Successfully! ID: ${campaignId}`);
    } else {
      console.error('FAIL: Campaign Creation Failed:', campaignRes.body);
      process.exit(1);
    }
  } catch (err) {
    console.error('FAIL: Test 3 Error:', err.message);
    process.exit(1);
  }

  // 4. Fetch Campaign List (SCRUM-65, SCRUM-71)
  try {
    console.log('\nTest 4: Fetching Campaigns List...');
    const listRes = await request('/api/campaigns?category=Blood%20Donation', 'GET');
    if (listRes.statusCode === 200 && listRes.body.success && listRes.body.campaigns.length > 0) {
      console.log(`PASS: Campaign List Fetched. Count: ${listRes.body.campaigns.length}`);
    } else {
      console.error('FAIL: Fetch Campaign List Failed:', listRes.body);
      process.exit(1);
    }
  } catch (err) {
    console.error('FAIL: Test 4 Error:', err.message);
    process.exit(1);
  }

  // 5. Register for Campaign (SCRUM-75, SCRUM-77, SCRUM-78, SCRUM-80)
  try {
    console.log('\nTest 5: Registering User for Campaign...');
    const regData = {
      userId: userId,
      submittedData: {
        bloodGroup: 'O+',
        tShirtSize: 'L',
      },
    };

    const regRes = await request(`/api/campaigns/${campaignId}/register`, 'POST', regData);
    if (regRes.statusCode === 201 && regRes.body.success) {
      registrationId = regRes.body.registration._id;
      console.log(`PASS: Registered Successfully! Registration ID: ${regRes.body.registration.registrationNumber}`);
    } else {
      console.error('FAIL: Campaign Registration Failed:', regRes.body);
      process.exit(1);
    }
  } catch (err) {
    console.error('FAIL: Test 5 Error:', err.message);
    process.exit(1);
  }

  // 6. Test Duplicate Registration Prevention (SCRUM-78)
  try {
    console.log('\nTest 6: Testing Duplicate Registration Prevention...');
    const duplicateRes = await request(`/api/campaigns/${campaignId}/register`, 'POST', {
      userId: userId,
      submittedData: { bloodGroup: 'O+' },
    });

    if (duplicateRes.statusCode === 400 && !duplicateRes.body.success) {
      console.log('PASS: Duplicate Registration correctly blocked by backend.');
    } else {
      console.error('FAIL: Duplicate Registration was NOT blocked!', duplicateRes.body);
      process.exit(1);
    }
  } catch (err) {
    console.error('FAIL: Test 6 Error:', err.message);
    process.exit(1);
  }

  // 7. Fetch My Registrations (SCRUM-82)
  try {
    console.log('\nTest 7: Fetching User Registrations (My Registrations)...');
    const myRegRes = await request('/api/campaign-registrations/my', 'GET', null, { 'x-user-id': userId });
    if (myRegRes.statusCode === 200 && myRegRes.body.success && myRegRes.body.registrations.length > 0) {
      console.log(`PASS: My Registrations Fetched. Total: ${myRegRes.body.registrations.length}`);
    } else {
      console.error('FAIL: My Registrations Failed:', myRegRes.body);
      process.exit(1);
    }
  } catch (err) {
    console.error('FAIL: Test 7 Error:', err.message);
    process.exit(1);
  }

  // 8. Admin List Campaign Registrations (SCRUM-79)
  try {
    console.log('\nTest 8: Admin Fetching Campaign Registration List...');
    const adminRegRes = await request(`/api/campaigns/${campaignId}/registrations`, 'GET');
    if (adminRegRes.statusCode === 200 && adminRegRes.body.success && adminRegRes.body.registrations.length > 0) {
      console.log(`PASS: Admin Registered User List Fetched. Count: ${adminRegRes.body.registrations.length}`);
    } else {
      console.error('FAIL: Admin Registration List Failed:', adminRegRes.body);
      process.exit(1);
    }
  } catch (err) {
    console.error('FAIL: Test 8 Error:', err.message);
    process.exit(1);
  }

  // 9. Cancel Registration (SCRUM-83)
  try {
    console.log('\nTest 9: Cancelling Registration...');
    const cancelRes = await request(`/api/campaign-registrations/${registrationId}/cancel`, 'PATCH', {}, { 'x-user-id': userId });
    if (cancelRes.statusCode === 200 && cancelRes.body.success && cancelRes.body.registration.registrationStatus === 'Cancelled') {
      console.log('PASS: Registration Cancelled successfully.');
    } else {
      console.error('FAIL: Registration Cancellation Failed:', cancelRes.body);
      process.exit(1);
    }
  } catch (err) {
    console.error('FAIL: Test 9 Error:', err.message);
    process.exit(1);
  }

  // 10. Fetch User Notifications (SCRUM-74, SCRUM-81)
  try {
    console.log('\nTest 10: Fetching User Notifications...');
    const notifRes = await request('/api/notifications/my', 'GET', null, { 'x-user-id': userId });
    if (notifRes.statusCode === 200 && notifRes.body.success && notifRes.body.notifications.length > 0) {
      console.log(`PASS: User Notifications Fetched. Count: ${notifRes.body.notifications.length}`);
    } else {
      console.error('FAIL: Fetch Notifications Failed:', notifRes.body);
      process.exit(1);
    }
  } catch (err) {
    console.error('FAIL: Test 10 Error:', err.message);
    process.exit(1);
  }

  console.log('\n=== ALL 10 CAMPAIGN MODULE BACKEND TESTS PASSED SUCCESSFULLY! ===\n');
  process.exit(0);
};

setTimeout(runCampaignTests, 1500);
