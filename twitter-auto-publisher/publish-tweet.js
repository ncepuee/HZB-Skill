const fs = require('fs');
const path = require('path');
const { loadConfig, connect, ensureLoggedIn } = require('./cdp-utils');

const TWEET_FILE = path.join(__dirname, 'tweet-content.txt');
const config = loadConfig();

const tweetRaw = process.argv[2]
  ? process.argv.slice(2).join(' ')
  : (fs.existsSync(TWEET_FILE) ? fs.readFileSync(TWEET_FILE, 'utf8') : '');

if (!tweetRaw.trim()) {
  console.error('No tweet content. Pass as argument or write to tweet-content.txt');
  process.exit(1);
}

const TWEET_LINES = tweetRaw.replace(/\r\n/g, '\n').split('\n');

(async () => {
  const browser = await connect(config);
  const context = browser.contexts()[0];
  const page = await context.newPage();

  await page.goto('https://x.com/home', { waitUntil: 'domcontentloaded', timeout: 30000 });
  await page.waitForTimeout(5000);
  const loggedIn = await ensureLoggedIn(page, context, config);
  if (!loggedIn) {
    await page.close();
    await browser.close();
    process.exit(1);
  }

  console.log('Opening compose...');
  await page.goto('https://x.com/compose/post', { waitUntil: 'domcontentloaded', timeout: 30000 });
  await page.waitForTimeout(5000);

  for (let i = 0; i < 3; i++) {
    await page.keyboard.press('Escape');
    await page.waitForTimeout(300);
  }
  await page.waitForTimeout(1000);

  console.log('Typing tweet...');
  const editor = page.locator('[data-testid="tweetTextarea_0"]').first();
  await editor.click({ force: true, timeout: 5000 });
  await page.waitForTimeout(300);

  for (let i = 0; i < TWEET_LINES.length; i++) {
    if (i > 0) await page.keyboard.press('Enter');
    await page.keyboard.type(TWEET_LINES[i], { delay: 5 });
  }
  await page.waitForTimeout(2000);

  const methods = [
    async () => { await page.getByText('发帖').click({ force: true, timeout: 3000 }); },
    async () => { await page.getByText('Post').click({ force: true, timeout: 3000 }); },
    async () => { await page.getByRole('button', { name: '发帖' }).click({ force: true, timeout: 3000 }); },
    async () => { await page.getByRole('button', { name: 'Post' }).click({ force: true, timeout: 3000 }); },
    async () => { await page.locator('[data-testid="tweetButton"]').first().click({ force: true, timeout: 3000 }); },
    async () => { await page.locator('[data-testid="tweetButtonInline"]').first().click({ force: true, timeout: 3000 }); },
  ];

  let posted = false;
  for (const method of methods) {
    try { await method(); posted = true; console.log('Clicked publish'); break; }
    catch(e) { continue; }
  }

  await page.waitForTimeout(4000);
  console.log(posted ? 'POSTED!' : 'POST FAILED');
  console.log('URL:', page.url());
  await page.close();
  await browser.close();
})().catch(e => { console.error('ERROR:', e.message); process.exit(1); });
