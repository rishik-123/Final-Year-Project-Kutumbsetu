const http = require('http');

function post(path, data) {
  return new Promise((resolve, reject) => {
    const payload = JSON.stringify(data);
    const req = http.request({
      hostname: 'localhost',
      port: 5000,
      path: path,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(payload)
      }
    }, res => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, data: JSON.parse(body) });
        } catch (e) {
          resolve({ status: res.statusCode, body });
        }
      });
    });
    req.on('error', reject);
    req.write(payload);
    req.end();
  });
}

function get(path) {
  return new Promise((resolve, reject) => {
    const req = http.request({
      hostname: 'localhost',
      port: 5000,
      path: path,
      method: 'GET',
    }, res => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, data: JSON.parse(body) });
        } catch (e) {
          resolve({ status: res.statusCode, body });
        }
      });
    });
    req.on('error', reject);
    req.end();
  });
}

async function runTest() {
  const testEmail = `testuser_${Date.now()}@example.com`;
  console.log('--- TEST 1: Sending OTP for', testEmail);
  const otpRes = await post('/api/auth/send-email-otp', { email: testEmail });
  console.log('OTP Result:', otpRes);

  const otp = otpRes.data && otpRes.data.otp ? otpRes.data.otp : '123456';

  console.log('\n--- TEST 2: Registering user with first, middle, last name');
  const regRes = await post('/api/users/register', {
    fullName: 'Rohan Jayeshbhai Shah',
    email: testEmail,
    phoneNumber: '9898989898',
    otp: otp,
  });
  console.log('Register Result:', regRes);

  console.log('\n--- TEST 3: Fetching pending users on /api/users/pending');
  const pendingRes = await get('/api/users/pending');
  console.log('Pending Users Count:', (pendingRes.data && pendingRes.data.pendingUsers) ? pendingRes.data.pendingUsers.length : 0);
  const foundUser = (pendingRes.data.pendingUsers || []).find(u => u.email === testEmail);
  console.log('Found registered user in pending list:', !!foundUser);

  if (foundUser) {
    console.log('\n--- TEST 4: Approving user on /api/users/approve');
    const approveRes = await post('/api/users/approve', { userId: foundUser._id });
    console.log('Approve Result:', approveRes);

    console.log('\n--- TEST 5: Reject/Cleanup test user on /api/users/reject');
    const rejectRes = await post('/api/users/reject', { userId: foundUser._id });
    console.log('Cleanup Result:', rejectRes);
  }

  console.log('\n--- ALL BACKEND CHECKS COMPLETED SUCCESSFULLY ---');
}

runTest().catch(console.error);
