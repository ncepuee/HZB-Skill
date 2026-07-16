const { loadConfig, connect, ensureLoggedIn } = require('./cdp-utils');

const config = loadConfig();

async function scrapeTweets(page, maxTweets = 12) {
  const results = [];
  const seenTexts = new Set();
  let stableCount = 0;
  let lastHeight = 0;

  for (let i = 0; i < 8 && results.length < maxTweets; i++) {
    const articles = await page.locator('article[data-testid="tweet"]').all();
    for (const article of articles) {
      if (results.length >= maxTweets) break;
      try {
        const textEl = article.locator('[data-testid="tweetText"]').first();
        const text = await textEl.innerText({ timeout: 2000 }).catch(() => '');
        if (!text || text.length < 5 || seenTexts.has(text)) continue;
        seenTexts.add(text);

        let handle = '';
        try {
          const links = await article.locator('a[role="link"]').all();
          for (const l of links) {
            const href = await l.getAttribute('href', { timeout: 500 }).catch(() => '');
            if (href && href.match(/^\/[^/]+$/)) { handle = href.slice(1); break; }
          }
        } catch {}

        let time = '';
        try { time = await article.locator('time').first().getAttribute('datetime', { timeout: 1000 }).catch(() => ''); } catch {}

        results.push({ handle, text: text.slice(0, 400), time });
      } catch(e) {}
    }

    const currentHeight = await page.evaluate(() => document.body.scrollHeight).catch(() => 0);
    if (currentHeight === lastHeight) { stableCount++; if (stableCount >= 2) break; }
    lastHeight = currentHeight;
    await page.evaluate(() => window.scrollBy(0, 1500)).catch(() => {});
    await page.waitForTimeout(2500);
  }
  return results;
}

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
  console.log('Logged in OK');

  const research = config.research || {};

  // 1. Scrape Twitter profiles
  if (research.twitter_profiles && research.twitter_profiles.length > 0) {
    for (const profile of research.twitter_profiles) {
      const handle = profile.replace('@', '');
      console.log(`\n=== @${handle} OWN TWEETS ===`);
      await page.goto(`https://x.com/${handle}`, { waitUntil: 'domcontentloaded', timeout: 30000 });
      await page.waitForTimeout(5000);
      const tweets = await scrapeTweets(page, 12);
      console.log(`${tweets.length} tweets`);
      tweets.forEach((t, i) => {
        console.log(`\n[${i+1}] ${t.time || ''}`);
        console.log(t.text);
      });
    }
  }

  // 2. Twitter keyword search
  if (research.twitter_search_queries && research.twitter_search_queries.length > 0) {
    console.log('\n=== TWITTER SEARCH RESULTS ===');
    for (const query of research.twitter_search_queries) {
      const url = `https://x.com/search?q=${encodeURIComponent(query)}&src=typed_query&f=live`;
      await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 30000 }).catch(() => {});
      await page.waitForTimeout(4000);
      const tweets = await scrapeTweets(page, 10);
      console.log(`\n[query: ${query}] ${tweets.length} tweets`);
      tweets.slice(0, 8).forEach((t, i) => {
        console.log(`\n[${i+1}] @${t.handle} ${t.time || ''}`);
        console.log(t.text);
      });
    }
  }

  // 3. Sogou WeChat search
  if (research.wechat_search_keywords && research.wechat_search_keywords.length > 0) {
    console.log('\n=== WECHAT TUTORIALS (Sogou) ===');
    for (const wq of research.wechat_search_keywords) {
      const url = `https://weixin.sogou.com/weixin?type=2&query=${encodeURIComponent(wq)}`;
      await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 30000 }).catch(() => {});
      await page.waitForTimeout(3000);
      const items = await page.locator('.news-list li, .news-box, .results .rb').all().catch(() => []);
      console.log(`\n[${wq}] ${items.length} results`);
      let count = 0;
      for (const item of items) {
        if (count >= 5) break;
        try {
          const title = await item.locator('h3, .txt-box h3 a, .tit a').first().innerText({ timeout: 2000 }).catch(() => '');
          const summary = await item.locator('.txt-info, .s-p, p').first().innerText({ timeout: 2000 }).catch(() => '');
          if (title && title.length > 5) {
            console.log(`  ${count+1}. ${title.trim().slice(0, 80)}`);
            if (summary) console.log(`     ${summary.trim().slice(0, 120)}`);
            count++;
          }
        } catch(e) {}
      }
    }
  }

  await page.close();
  await browser.close();
})().catch(e => { console.error('ERROR:', e.message); process.exit(1); });
