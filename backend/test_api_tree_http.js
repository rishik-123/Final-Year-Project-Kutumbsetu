const http = require('http');

function getTree(phone, email) {
  return new Promise((resolve, reject) => {
    const headers = { 'Content-Type': 'application/json' };
    if (phone) headers['x-user-phone'] = phone;
    if (email) headers['x-user-email'] = email;

    const req = http.request({
      hostname: '127.0.0.1',
      port: 5000,
      path: '/api/family/my-tree',
      method: 'GET',
      headers: headers
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, body: JSON.parse(data) });
        } catch (e) {
          resolve({ status: res.statusCode, raw: data });
        }
      });
    });

    req.on('error', reject);
    req.end();
  });
}

async function testHttp() {
  console.log('Testing HTTP /api/family/my-tree on port 5000...');
  
  // Test Rishik
  const rishikRes = await getTree('+919136091620', 'rishikjariwala54@gmail.com');
  console.log('Rishik HTTP status:', rishikRes.status);
  if (rishikRes.body && rishikRes.body.success) {
    console.log('Rishik Tree root:', rishikRes.body.tree.name);
  } else {
    console.log('Rishik Response:', rishikRes.body || rishikRes.raw);
  }

  // Test Alak
  const alakRes = await getTree('+919136091624', null);
  console.log('Alak HTTP status:', alakRes.status);
  if (alakRes.body && alakRes.body.success) {
    console.log('Alak Tree root:', alakRes.body.tree.name);
  } else {
    console.log('Alak Response:', alakRes.body || alakRes.raw);
  }

  // Test Payal
  const payalRes = await getTree('+919136091625', null);
  console.log('Payal HTTP status:', payalRes.status);
  if (payalRes.body && payalRes.body.success) {
    console.log('Payal Tree root:', payalRes.body.tree.name);
  } else {
    console.log('Payal Response:', payalRes.body || payalRes.raw);
  }
}

testHttp().catch(console.error);
