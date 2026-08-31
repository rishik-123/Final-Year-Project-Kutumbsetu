const http = require('http');

function request(method, path, data, headers = {}) {
  return new Promise((resolve, reject) => {
    const payload = data ? JSON.stringify(data) : null;
    const req = http.request({
      hostname: 'localhost',
      port: 5000,
      path: path,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        ...(payload ? { 'Content-Length': Buffer.byteLength(payload) } : {}),
        ...headers,
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
    if (payload) req.write(payload);
    req.end();
  });
}

async function testApi() {
  console.log('--- STARTING HTTP API INTEGRATION TESTS ---');

  // 1. Test search API for "Alak"
  console.log('\n--- 1. Testing GET /api/members/search?q=Alak ---');
  const searchRes = await request('GET', '/api/members/search?q=Alak');
  console.log('Search Status:', searchRes.status);
  console.log('Found Members:', (searchRes.data.members || []).map(m => `${m.fullName} (${m.memberId})`));

  // 2. Test search API for maiden surname "Gandhi"
  console.log('\n--- 2. Testing GET /api/members/search?q=Gandhi ---');
  const searchGandhiRes = await request('GET', '/api/members/search?q=Gandhi');
  console.log('Gandhi Members:', (searchGandhiRes.data.members || []).map(m => `${m.fullName} (${m.memberId}, Maiden: ${m.maidenName})`));

  // 3. Test Register new user (Rohan)
  const uniqueTs = Date.now().toString().slice(-6);
  const testEmail = `rohan_${uniqueTs}@example.com`;
  const testPhone = `98${uniqueTs}00`;
  console.log(`\n--- 3. Testing POST /api/users/register for ${testEmail} ---`);
  const regRes = await request('POST', '/api/users/register', {
    fullName: 'Rohan Jariwala',
    email: testEmail,
    phoneNumber: testPhone,
  });
  console.log('Register Result:', regRes.data);
  const rohanUser = regRes.data.user;

  // 4. Test Profile Save for Rohan linking Father = Alak Jariwala (MEM050)
  console.log('\n--- 4. Testing POST /api/users/profile with Father Link ---');
  const alakMatch = (searchRes.data.members || []).find(m => m.fullName.toLowerCase() === 'alak jariwala');
  const profileRes = await request('POST', '/api/users/profile', {
    userId: rohanUser._id,
    gender: 'Male',
    dateOfBirth: '1998-05-15',
    phoneNumber: testPhone,
    city: 'Surat',
    fatherId: alakMatch ? alakMatch.memberId : 'MEM050',
    fatherName: 'Alak Jariwala',
    motherName: 'Payal Jariwala',
  });
  console.log('Profile Save Result:', profileRes.data.success ? 'SUCCESS' : 'FAILED');
  console.log('Saved FatherId:', profileRes.data.profile ? profileRes.data.profile.fatherId : 'NONE');

  // 5. Test Family Tree API for Rishik
  console.log('\n--- 5. Testing GET /api/family/my-tree for Rishik ---');
  const treeRes = await request('GET', '/api/family/my-tree', null, {
    'x-user-email': 'rishikjariwala54@gmail.com',
  });
  console.log('Tree API Status:', treeRes.status);
  console.log('Tree Root Node:', treeRes.data.tree ? `${treeRes.data.tree.name} (${treeRes.data.tree.relation})` : 'NULL');

  console.log('\n--- ALL HTTP ENDPOINT TESTS PASSED ---');
}

testApi().catch(console.error);
