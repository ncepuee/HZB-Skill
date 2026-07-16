---
name: twitter-auto-publisher
version: 1.0.0
description: 通过 Chrome CDP 自动调研并发布 Twitter/X 推文。支持抓取指定账号推文、关键词搜索、微信文章搜索，自动创作有营养的推文并发布。无需 Twitter API，复用浏览器登录态。适用于 AI 日报、技术分享、内容运营等场景。
---

# Twitter Auto Publisher

通过 Chrome CDP 自动调研并发布 Twitter/X 推文。复用浏览器已有登录态，无需 Twitter Developer API。

---

## 🎯 核心工作流

```
用户说"发一条推文"或"调研最新 AI 资讯并发布"
    ↓
读取 config.json 获取配置（CDP 端口、代理、调研目标等）
    ↓
运行 research.js 调研（抓 Twitter 账号 + 搜关键词 + 搜微信文章）
    ↓
Claude 基于调研结果创作推文，写入 tweet-content.txt
    ↓
运行 publish-tweet.js 通过 CDP 发布
    ↓
推文出现在用户的 X 账号
```

---

## 📦 前置条件

1. **Node.js** + **playwright-core**：`npm install playwright-core`
2. **Chrome 浏览器**：系统已安装 Google Chrome
3. **代理（可选）**：如果所在地区无法直接访问 x.com，需要 HTTP 代理（如 Clash、V2Ray）
4. **X/Twitter 账号**：已注册并能正常登录

---

## 🚀 首次配置

### Step 1: 创建 config.json

复制 `config.example.json` 为 `config.json`，填入你的信息：

```json
{
  "cdp_endpoint": "http://localhost:9222",
  "proxy": "http://127.0.0.1:7890",
  "chrome_path": "C:/Program Files/Google/Chrome/Application/chrome.exe",
  "twitter_handle": "你的用户名",
  "research": {
    "twitter_profiles": ["@someone"],
    "twitter_search_queries": ["AI OR Codex OR Claude"],
    "wechat_search_keywords": ["Codex 教程"]
  },
  "cookies": {
    "auth_token": "",
    "ct0": "",
    "twid": ""
  }
}
```

**字段说明**：
- `cdp_endpoint`：Chrome CDP 调试端口（默认 `http://localhost:9222`）
- `proxy`：HTTP 代理地址，不需要代理则留空 `""`
- `chrome_path`：Chrome 可执行文件路径
- `twitter_handle`：你的 X 用户名（用于验证登录）
- `research.twitter_profiles`：要抓取推文的 X 账号列表（如 `["@interesting_user"]`）
- `research.twitter_search_queries`：Twitter 搜索关键词
- `research.wechat_search_keywords`：搜狗微信搜索关键词（中文教程来源）
- `cookies`：可选，用于登录失效时自动注入 cookie 恢复登录（留空则需手动登录）

### Step 2: 启动 Chrome 带 CDP

```bash
# 关闭所有 Chrome
# Windows
taskkill //F //IM chrome.exe

# 启动带调试端口的 Chrome（使用独立 profile）
chrome.exe --remote-debugging-port=9222 \
           --user-data-dir="C:/Users/你的用户名/AppData/Local/Temp/chrome-debug-profile"

# 如果需要代理，加 --proxy-server 参数
chrome.exe --remote-debugging-port=9222 \
           --user-data-dir="C:/Users/你的用户名/AppData/Local/Temp/chrome-debug-profile" \
           --proxy-server="http://127.0.0.1:7890"
```

### Step 3: 登录 X

在弹出的 Chrome 窗口中，打开 `https://x.com/login`，登录你的账号。登录后 session 会保存在 user-data-dir，后续无需重复登录。

### Step 4: 验证连接

```bash
node cdp-utils.js
```

输出 `Logged in OK` 即配置成功。

---

## 📝 使用方式

### 单次发推

```bash
# 方式 1：直接传推文内容
node publish-tweet.js "你的推文内容"

# 方式 2：写入 tweet-content.txt 再发布
echo "推文内容" > tweet-content.txt
node publish-tweet.js
```

### 调研 + 创作 + 发布（完整流程）

```bash
# 1. 调研最新资讯
node research.js

# 2. Claude 读取调研输出，创作推文，写入 tweet-content.txt
#    （由 Claude Code 会话中的 AI 完成）

# 3. 发布
node publish-tweet.js
```

### 多行推文

```bash
node publish-tweet.js "第一行
第二行
第三行"
```

或写入 `tweet-content.txt`，用换行分隔。

---

## 🔄 自动循环发布

在 Claude Code 中使用 `/loop` 技能设置定时循环：

```
/loop 60m 自动调研并发布推文。步骤：1) 运行 `cd "skill目录" && node research.js` 调研；2) 基于结果创作有营养的推文写入 tweet-content.txt；3) 运行 `node publish-tweet.js` 发布；4) 报告结果
```

**推荐频率**：
- 1 小时一条：安全，每天 24 条
- 30 分钟一条：较激进，每天 48 条
- ⚠️ 不要低于 10 分钟，会触发 Twitter 反垃圾机制

---

## 🔧 脚本说明

### `cdp-utils.js`
CDP 连接 + 登录验证。如果未登录且有 cookie 配置，自动注入 cookie 恢复登录。

### `research.js`
调研脚本，输出结构化文本：
- `=== [账号] OWN TWEETS ===`：指定账号的最新推文
- `=== SEARCH RESULTS ===`：Twitter 关键词搜索结果
- `=== WECHAT TUTORIALS ===`：搜狗微信文章搜索结果

### `publish-tweet.js`
发布脚本，读取 `tweet-content.txt` 或命令行参数，通过 CDP 在 X 发布。

---

## 🐛 常见问题

### CDP 连接失败（ECONNREFUSED）
- Chrome 没启动或端口不对
- 检查：`curl http://localhost:9222/json/version`
- 重启 Chrome 带 `--remote-debugging-port=9222`

### 页面加载但内容为空
- 可能是代理问题：检查 `config.json` 的 `proxy` 配置
- 可能是 Twitter 检测自动化：确保用 CDP 连接已登录的 Chrome，不要用 `chromium.launch()`

### 发推按钮找不到
- X 前端经常变化，脚本已内置多种按钮选择器回退
- 如果界面语言不是中文，把 `publish-tweet.js` 里的 `'发帖'` 改成对应语言

### Cookie 登录失效
- `auth_token` 通常 1-5 年有效
- `ct0` 可能几周失效
- 重新从浏览器 DevTools 提取 cookie，更新 `config.json`

---

## ⚠️ 注意事项

1. **遵守 Twitter ToS**：自动化发推有风险，频率不要太高
2. **代理稳定性**：通过代理访问时，代理断了会导致脚本失败
3. **登录态保持**：CDP Chrome 窗口不要关，登录 session 保存在 user-data-dir
4. **隐私安全**：`config.json` 含敏感信息（cookie），不要提交到 git，不要分享
5. **内容质量**：推文要有营养，不要刷屏垃圾内容，否则账号会被限流或封禁
