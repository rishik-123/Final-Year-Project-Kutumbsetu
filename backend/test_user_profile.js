const http = require('http');

http.get('http://localhost:5000/api/users/profile/aryaambokar@gmail.com', (res) => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    console.log('Profile API response:', data);
  });
}).on('error', err => console.error(err));
