require('dotenv').config();
const mongoose = require('mongoose');
const http = require('http');

const PORT = 5000;
const BASE_URL = `http://localhost:${PORT}`;

const request = (path, method, body) => {
  return new Promise((resolve, reject) => {
    const url = `${BASE_URL}${path}`;
    const data = JSON.stringify(body);

    const options = {
      method: method,
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(data),
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

    req.write(data);
    req.end();
  });
};

const cleanupDatabase = async () => {
  console.log('Connecting to database for test cleanup...');
  const uri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/kutumbsetu';
  await mongoose.connect(uri);
  
  // Clean up any old test records to ensure repeatable test execution
  const testPhone = '+919999999999';
  
  console.log(`Deleting test user: ${testPhone}`);
  await mongoose.connection.db.collection('directory').deleteMany({ phoneNumber: testPhone });
  
  console.log(`Deleting test OTPs for: ${testPhone}`);
  await mongoose.connection.db.collection('otp_verifications').deleteMany({ phone: testPhone });
  
  await mongoose.connection.close();
  console.log('Cleanup completed and database connection closed.\n');
};

const runTests = async () => {
  console.log('--- STARTING BACKEND INTEGRATION TESTS ---');
  
  // Run cleanup first
  await cleanupDatabase();

  const testPhone = '+919999999999';
  let generatedOtp = '';

  // Test 1: Send OTP
  try {
    console.log('Test 1: Sending OTP...');
    const res = await request('/api/auth/send-otp', 'POST', { phone: testPhone });
    console.log('Status Code:', res.statusCode);
    console.log('Body:', res.body);
    if (res.statusCode === 200 && res.body.success && res.body.otp) {
      console.log('PASS: Send OTP Successful.');
      generatedOtp = res.body.otp;
    } else {
      console.error('FAIL: Send OTP Failed.');
      process.exit(1);
    }
  } catch (error) {
    console.error('FAIL: Test 1 Error:', error.message);
    process.exit(1);
  }

  // Test 2: Verify Incorrect OTP
  try {
    console.log('\nTest 2: Verifying Incorrect OTP...');
    const res = await request('/api/auth/verify-otp', 'POST', { phone: testPhone, otp: '000000' });
    console.log('Status Code:', res.statusCode);
    console.log('Body:', res.body);
    if (res.statusCode === 400 && !res.body.success) {
      console.log('PASS: Incorrect OTP rejected correctly.');
    } else {
      console.error('FAIL: Incorrect OTP was not rejected correctly.');
      process.exit(1);
    }
  } catch (error) {
    console.error('FAIL: Test 2 Error:', error.message);
    process.exit(1);
  }

  // Test 3: Verify Correct OTP
  try {
    console.log('\nTest 3: Verifying Correct OTP...');
    const res = await request('/api/auth/verify-otp', 'POST', { phone: testPhone, otp: generatedOtp });
    console.log('Status Code:', res.statusCode);
    console.log('Body:', res.body);
    if (res.statusCode === 200 && res.body.success) {
      console.log('PASS: Correct OTP verified successfully.');
    } else {
      console.error('FAIL: Correct OTP verification failed.');
      process.exit(1);
    }
  } catch (error) {
    console.error('FAIL: Test 3 Error:', error.message);
    process.exit(1);
  }

  // Test 4: Register New User
  try {
    console.log('\nTest 4: Registering User...');
    const userData = {
      fullName: 'Test User',
      surname: 'Surname',
      fatherName: 'Father Name',
      phoneNumber: testPhone,
      gender: 'Male',
      dateOfBirth: '1990-01-01',
      nativePlace: 'Native Village',
      city: 'Mumbai',
      state: 'Maharashtra',
      maritalStatus: 'Single',
      profilePhoto: 'avatar_male_1',
    };

    const res = await request('/api/users/register', 'POST', userData);
    console.log('Status Code:', res.statusCode);
    console.log('Body:', res.body);
    if (res.statusCode === 201 && res.body.success) {
      console.log('PASS: User registered successfully.');
    } else {
      console.error('FAIL: User registration failed.');
      process.exit(1);
    }
  } catch (error) {
    console.error('FAIL: Test 4 Error:', error.message);
    process.exit(1);
  }

  // Test 5: Register Duplicate User
  try {
    console.log('\nTest 5: Registering Duplicate User...');
    const userData = {
      fullName: 'Test User Duplicate',
      phoneNumber: testPhone,
      gender: 'Male',
      dateOfBirth: '1990-01-01',
      city: 'Mumbai',
    };

    const res = await request('/api/users/register', 'POST', userData);
    console.log('Status Code:', res.statusCode);
    console.log('Body:', res.body);
    if (res.statusCode === 400 && !res.body.success) {
      console.log('PASS: Duplicate phone registration rejected correctly.');
    } else {
      console.error('FAIL: Duplicate phone registration was not rejected.');
      process.exit(1);
    }
  } catch (error) {
    console.error('FAIL: Test 5 Error:', error.message);
    process.exit(1);
  }

  console.log('\n--- ALL BACKEND INTEGRATION TESTS PASSED SUCCESSFULY ---');
  process.exit(0);
};

// Wait 1 second before running to ensure server is ready (if invoked together)
setTimeout(runTests, 1500);
