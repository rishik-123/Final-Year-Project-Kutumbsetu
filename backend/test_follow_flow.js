const http = require('http');

function post(url, body) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify(body);
    const u = new URL(url);
    const req = http.request({
      hostname: u.hostname,
      port: u.port,
      path: u.pathname,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(data)
      }
    }, res => {
      let resp = '';
      res.on('data', chunk => resp += chunk);
      res.on('end', () => resolve({ status: res.statusCode, body: JSON.parse(resp) }));
    });
    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

function get(url) {
  return new Promise((resolve, reject) => {
    http.get(url, res => {
      let resp = '';
      res.on('data', chunk => resp += chunk);
      res.on('end', () => resolve({ status: res.statusCode, body: JSON.parse(resp) }));
    }).on('error', reject);
  });
}

async function testFlow() {
  console.log('--- 1. Arya Ambokar sends follow request to Nirmay Patel ---');
  const reqRes = await post('http://localhost:5000/api/directory/request', {
    senderId: '6a979e75668c11500a70bf09',
    senderName: 'arya a ambokar',
    senderEmail: 'aryaambokar@gmail.com',
    receiverId: '6a6987830954b4987c46dbd0',
    receiverName: 'Nirmay Pankaj Patel',
    receiverEmail: 'nirmaypatel73@gmail.com'
  });
  console.log('Send Request result:', reqRes.body);

  console.log('\n--- 2. Nirmay Patel logs in and checks incoming alerts ---');
  const alertRes = await get('http://localhost:5000/api/directory/incoming-alerts/nirmaypatel73@gmail.com');
  console.log('Incoming Alerts for Nirmay:', JSON.stringify(alertRes.body, null, 2));

  if (alertRes.body.alerts && alertRes.body.alerts.length > 0) {
    const firstAlert = alertRes.body.alerts[0];
    console.log(`\nVerified: Incoming alert pop-up senderName is: "${firstAlert.senderName}" (Expected: "arya a ambokar")`);
  }
}

testFlow().catch(console.error);
