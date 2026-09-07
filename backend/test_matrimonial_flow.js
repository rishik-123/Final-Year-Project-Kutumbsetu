require('dotenv').config();
const mongoose = require('mongoose');
const http = require('http');
const User = require('./models/User');
const Profile = require('./models/Profile');
const MatrimonialProfile = require('./models/MatrimonialProfile');
const { MatrimonialRequest } = require('./models/MatrimonialCollections');

function request(method, path, body = null) {
  return new Promise((resolve, reject) => {
    const postData = body ? JSON.stringify(body) : '';
    const options = {
      hostname: '127.0.0.1',
      port: 5000,
      path: path,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        ...(body ? { 'Content-Length': Buffer.byteLength(postData) } : {}),
      },
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        try {
          const json = JSON.parse(data);
          resolve({ status: res.statusCode, body: json });
        } catch (e) {
          resolve({ status: res.statusCode, raw: data });
        }
      });
    });

    req.on('error', (e) => reject(e));
    if (postData) req.write(postData);
    req.end();
  });
}

async function runMatrimonialTests() {
  console.log('=== STARTING MATRIMONIAL MODULE INTEGRATION TEST ===\n');
  const uri = process.env.MONGODB_URI;
  await mongoose.connect(uri);

  // 1. Create or resolve two test matrimonial users
  console.log('Step 1: Setting up Test User A (Sender) and Test User B (Receiver)...');
  
  let userA = await User.findOne({ email: 'test_matrimony_groom@example.com' });
  if (!userA) {
    userA = new User({
      fullName: 'Rohan Sharma',
      email: 'test_matrimony_groom@example.com',
      phoneNumber: '+919811122233',
      role: 'user',
      isApproved: true,
    });
    await userA.save();
  }

  let userB = await User.findOne({ email: 'test_matrimony_bride@example.com' });
  if (!userB) {
    userB = new User({
      fullName: 'Pooja Patel',
      email: 'test_matrimony_bride@example.com',
      phoneNumber: '+919844455566',
      role: 'user',
      isApproved: true,
    });
    await userB.save();
  }

  // Create Matrimonial Profiles for both
  await MatrimonialProfile.findOneAndUpdate(
    { userId: userA._id },
    {
      userId: userA._id,
      name: 'Rohan Sharma',
      gender: 'Male',
      dob: new Date('1998-05-10'),
      heightCm: 178,
      weightKg: 72,
      bloodGroup: 'B+',
      maritalStatus: 'Never Married',
      education: 'B.Tech',
      occupation: 'Software Engineer',
      company: 'Tech Corp',
      annualIncome: 1800000,
      village: 'Surat',
      city: 'Surat',
    },
    { upsert: true, new: true }
  );

  await MatrimonialProfile.findOneAndUpdate(
    { userId: userB._id },
    {
      userId: userB._id,
      name: 'Pooja Patel',
      gender: 'Female',
      dob: new Date('2000-08-20'),
      heightCm: 165,
      weightKg: 58,
      bloodGroup: 'O+',
      maritalStatus: 'Never Married',
      education: 'MBBS',
      occupation: 'Doctor',
      company: 'Civil Hospital',
      annualIncome: 1500000,
      village: 'Ahmedabad',
      city: 'Ahmedabad',
    },
    { upsert: true, new: true }
  );

  // Clean any previous test requests between A and B
  await MatrimonialRequest.deleteMany({
    $or: [
      { senderId: userA._id, receiverId: userB._id },
      { senderId: userB._id, receiverId: userA._id },
    ],
  });

  console.log(`User A (Groom ID): ${userA._id}`);
  console.log(`User B (Bride ID): ${userB._id}`);
  console.log('✓ Test profiles initialized.\n');

  // 2. Send interest request: User A -> User B
  console.log('Step 2: Sending Matrimonial Interest Request (User A -> User B)...');
  const sendRes = await request('POST', '/api/matrimonial/request', {
    senderId: userA._id.toString(),
    receiverId: userB._id.toString(),
  });

  console.log('Response status:', sendRes.status);
  console.log('Response body:', sendRes.body);
  if (sendRes.status !== 201 || !sendRes.body.success) {
    throw new Error(`Failed to send request: ${JSON.stringify(sendRes.body)}`);
  }
  console.log('✓ Request successfully sent!\n');

  // 3. Prevent duplicate request test
  console.log('Step 3: Verifying Duplicate Prevention...');
  const dupRes = await request('POST', '/api/matrimonial/request', {
    senderId: userA._id.toString(),
    receiverId: userB._id.toString(),
  });
  console.log('Duplicate check status:', dupRes.status, 'message:', dupRes.body.message);
  if (dupRes.status !== 400) {
    throw new Error('Duplicate check failed! Expected status 400.');
  }
  console.log('✓ Duplicate request correctly blocked!\n');

  // 4. Fetch Sent requests for User A
  console.log('Step 4: Fetching Sent Requests for User A...');
  const sentRes = await request('GET', `/api/matrimonial/requests?userId=${userA._id}`);
  console.log('User A Sent count:', sentRes.body.sent ? sentRes.body.sent.length : 0);
  if (!sentRes.body.sent || sentRes.body.sent.length === 0) {
    throw new Error('Sent request not found for User A');
  }
  const createdReq = sentRes.body.sent[0];
  console.log(`✓ Verified sent request ID: ${createdReq._id}, Status: ${createdReq.status}\n`);

  // 5. Fetch Received requests and Incoming Alerts for User B
  console.log('Step 5: Fetching Received Requests and Incoming Alerts for User B...');
  const recvRes = await request('GET', `/api/matrimonial/requests?userId=${userB._id}`);
  console.log('User B Received count:', recvRes.body.received ? recvRes.body.received.length : 0);
  if (!recvRes.body.received || recvRes.body.received.length === 0) {
    throw new Error('Received request not found for User B');
  }

  const alertRes = await request('GET', `/api/matrimonial/incoming-alerts/${userB._id}`);
  console.log('Incoming Alerts count:', alertRes.body.requests ? alertRes.body.requests.length : 0);
  console.log('✓ Verified User B correctly received the interest alert!\n');

  // 6. User B responds to request (Accept)
  console.log('Step 6: User B Accepts the Matrimonial Request...');
  const respondRes = await request('POST', '/api/matrimonial/request/respond', {
    requestId: createdReq._id,
    status: 'Accepted',
  });
  console.log('Respond status:', respondRes.status);
  console.log('Respond body:', respondRes.body);
  if (respondRes.status !== 200 || !respondRes.body.success) {
    throw new Error(`Failed to respond to request: ${JSON.stringify(respondRes.body)}`);
  }
  console.log('✓ Matrimonial Request successfully Accepted!\n');

  // 7. Verify updated status in database
  console.log('Step 7: Verifying Final Request Status in Database...');
  const updatedDoc = await MatrimonialRequest.findById(createdReq._id);
  console.log(`DB Request Status: "${updatedDoc.status}"`);
  if (updatedDoc.status !== 'Accepted') {
    throw new Error(`Status mismatch! Expected 'Accepted', got '${updatedDoc.status}'`);
  }
  console.log('✓ Database verification confirmed: Status is Accepted!\n');

  // 8. Clean up test records
  console.log('Step 8: Cleaning up test records...');
  await MatrimonialRequest.deleteOne({ _id: createdReq._id });
  await MatrimonialProfile.deleteMany({ userId: { $in: [userA._id, userB._id] } });
  await User.deleteMany({ _id: { $in: [userA._id, userB._id] } });
  console.log('✓ Clean up finished.\n');

  console.log('====================================================');
  console.log('🎉 ALL MATRIMONIAL REQUEST TESTS PASSED PERFECTLY!');
  console.log('====================================================\n');

  await mongoose.disconnect();
}

runMatrimonialTests().catch((err) => {
  console.error('❌ MATRIMONIAL TEST FAILED:', err);
  process.exit(1);
});
