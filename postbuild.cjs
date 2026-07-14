const fs = require('fs');
const path = require('path');

const src = path.join(__dirname, 'dist', 'index.html');
const dest = path.join(__dirname, 'dist', '404.html');

if (fs.existsSync(src)) {
  fs.copyFileSync(src, dest);
  console.log('Successfully copied index.html to 404.html');
} else {
  console.error('dist/index.html not found');
}
