const fs = require('fs');
const path = require('path');

// Copy index.html to 404.html
const srcHtml = path.join(__dirname, 'dist', 'index.html');
const destHtml = path.join(__dirname, 'dist', '404.html');

if (fs.existsSync(srcHtml)) {
  fs.copyFileSync(srcHtml, destHtml);
  console.log('Successfully copied index.html to 404.html');
} else {
  console.error('dist/index.html not found');
}

// Copy logo-BfdUS4sd.png to dist/assets/
const srcLogo = path.join(__dirname, 'assets', 'logo-BfdUS4sd.png');
const destLogo = path.join(__dirname, 'dist', 'assets', 'logo-BfdUS4sd.png');

if (fs.existsSync(srcLogo)) {
  fs.copyFileSync(srcLogo, destLogo);
  console.log('Successfully copied logo-BfdUS4sd.png to dist/assets/');
} else {
  console.error('assets/logo-BfdUS4sd.png not found');
}
