const { chromium } = require('playwright-core');
const fs = require('fs');
const path = require('path');

const CONFIG_PATH = path.join(__dirname, 'config.json');

function loadConfig() {
  if (!fs.existsSync(CONFIG_PATH)) {
    console.error('config.json not found. Copy config.example.json to config.json and fill in your info.');
    process.exit(1);
  }
  return JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8'));
}

function buildCookies(config) {
  const c = config.cookies || {};
  const cookies = [];
  for (const domain of ['.twitter.com', '.x.com']) {
    if (c.auth_token) cookies.push({ name: 'auth_token', value: c.auth_token, domain, path: '/', httpOnly: true, secure: true, sameSite: 'None' });
    if (c.ct0) cookies.push({ name: 'ct0', value: c.ct0, domain, path: '/', httpOnly: false, secure: true, sameSite: 'None' });
    if (c.twid) cookies.push({ name: 'twid', value: c.twid, domain, path: '/', httpOnly: false, secure: true, sameSite: 'None' });
  }
  return cookies;
}

async function connect(config) {
  const browser = await chromium.connectOverCDP(config.cdp_endpoint);
  return browser;
}

async function ensureLoggedIn(page, context, config) {
  const sideNav = await page.locator('[data-testid="SideNav_NewTweet_Button"]').count().catch(() => 0);
  if (sideNav > 0) return true;

  const cookies = buildCookies(config);
  if (cookies.length === 0) {
    console.log('Not logged in and no cookies configured. Please log in to X in the CDP Chrome window.');
    return false;
  }

  console.log('Not logged in, injecting cookies...');
  await context.addCookies(cookies);
  await page.goto('https://x.com/home', { waitUntil: 'domcontentloaded', timeout: 30000 });
  await page.waitForTimeout(6000);

  const sideNav2 = await page.locator('[data-testid="SideNav_NewTweet_Button"]').count().catch(() => 0);
  if (sideNav2 > 0) {
    console.log('Cookie login succeeded');
    return true;
  }
  console.log('Cookie login failed - cookies may be expired. Please log in manually in the CDP Chrome window.');
  return false;
}

module.exports = { loadConfig, buildCookies, connect, ensureLoggedIn };
