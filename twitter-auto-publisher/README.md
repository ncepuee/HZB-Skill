# Twitter Auto Publisher

通过 Chrome CDP 自动调研并发布 Twitter/X 推文。复用浏览器登录态，无需 Twitter API。

## 快速开始

```bash
# 1. 安装依赖
npm install

# 2. 复制配置模板
cp config.example.json config.json
# 编辑 config.json 填入你的信息

# 3. 启动 Chrome 带 CDP
chrome.exe --remote-debugging-port=9222 \
           --user-data-dir="C:/Users/你的用户名/AppData/Local/Temp/chrome-debug-profile" \
           --proxy-server="http://127.0.0.1:7890"

# 4. 在 Chrome 窗口登录 X
# 5. 验证连接
npm run test-connection

# 6. 调研
npm run research

# 7. 把推文写入 tweet-content.txt，然后发布
npm run publish
```

详细文档见 `SKILL.md`。
