const { chromium } = require('playwright');
const { createServer } = require('node:http');

async function smokeTest() {
  const executablePath = process.env.LOLI_CHROMIUM_EXECUTABLE || undefined;
  const server = createServer((_, response) => {
    response.writeHead(200, { 'content-type': 'text/html; charset=utf-8' });
    response.end('<h1>ok</h1>');
  });
  await new Promise((resolve, reject) => {
    server.once('error', reject);
    server.listen(0, '127.0.0.1', resolve);
  });
  let browser;
  try {
    browser = await chromium.launch({
      executablePath,
      headless: true,
      timeout: 15000,
      args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage', '--disable-gpu'],
    });
    const page = await browser.newPage();
    await page.goto(`http://127.0.0.1:${server.address().port}/`, { timeout: 10000 });
    if (await page.textContent('h1') !== 'ok') throw new Error('Réponse locale inattendue');
    console.log('ok');
  } finally {
    try {
      await browser?.close();
    } finally {
      server.close();
    }
  }
}

smokeTest().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
