# 专利下载技术笔记

## Google Patents URL 格式规律

### 中国专利
| URL 模式 | 是否可访问 | 是否有PDF |
|---------|-----------|-----------|
| `patents.google.com/patent/CN{申请号}` | ❌ 404 | - |
| `patents.google.com/patent/CN{申请号}.X` | ❌ 404 | - |
| `patents.google.com/patent/CN{申请号}A` | ❌ 404 | - |
| `patents.google.com/patent/CN{公开号}A` | ✅ 200 | ✅ 一般都有 |
| `patents.google.com/patent/CN{公开号}B` | ✅ 200 | ⚠️ 常无PDF |

**关键结论**：中国专利必须用**公开号**（不是申请号），且优先用 **A 版**（申请公开）而非 B 版（授权公告）。

### 美国专利
| URL 模式 | 结果 |
|---------|------|
| `patents.google.com/patent/US{公告号}B1` | ✅ 有PDF |
| `patents.google.com/patent/US{公告号}B2` | ✅ 有PDF |
| `patents.google.com/patent/US{公告号}A1` | ✅ 有PDF（申请公开）|

### 欧洲专利
| URL 模式 | 结果 |
|---------|------|
| `patents.google.com/patent/EP{号码}` | ✅ |
| `patents.google.com/patent/EP{号码}A1` | ✅ |

## Google Patents 搜索API

未公开的公开 API 端点：
```
https://patents.google.com/xhr/query?url=q%3D{关键词}&exp=
```

参数说明：
- `q` = URL-encoded 查询词，可用申请号纯数字/公开号/标题
- `exp` = 空即可

返回 JSON 结构：
```json
{
  "results": {
    "total_num_results": 1,
    "cluster": [{
      "result": [{
        "id": "patent/CN{XXXXXX}B/en",
        "patent": {
          "title": "...",
          "publication_number": "CN{XXXXXX}B",
          "assignee": "...",
          "inventor": "...",
          "priority_date": "...",
          "grant_date": "...",
          "pdf": ""    // ⚠️ 这个字段常为空，不能直接用
        }
      }]
    }]
  }
}
```

**注意** `pdf` 字段常为空 —— 必须访问详情页HTML再提取PDF链接。

## PDF 存储 CDN

Google 把专利 PDF 存放在：
```
https://patentimages.storage.googleapis.com/{hash1}/{hash2}/{hash3}/{hash4}/{filename}.pdf
```

- 4级 hash 目录路径无规律，只能从 HTML 提取
- 文件名 = 公开号 + 扩展名（如 `CN{XXXXXX}A.pdf`）
- CDN 全球可访问，速度快，无认证

## 常见坑

### 1. 网络问题
- Google Patents 在中国大陆需要代理/VPN
- SSL 连接可能突然断开：`SSLEOFError: EOF occurred in violation of protocol`
- 解决：加 `time.sleep(2)` 间隔 + 请求失败重试1次

### 2. 授权版无PDF
中国专利授权后 `CN{num}B` 的详情页 HTML 里**没有** PDF 链接。
- 现象：页面正常打开、有标题有摘要，但正则匹配不到 `patentimages.storage.googleapis.com/*.pdf`
- 解决：改用申请公开版 `CN{num}A`

### 3. 最新专利未同步
最新公开的专利（一般是当年公开的），Google Patents 可能还没同步 PDF：
- 页面能打开
- 但 PDF 字段和链接都没有
- 只能从其他渠道获取（国知局/CNKI/本地）

### 4. Chinese application number 格式
- 老格式：`ZL2015XXXXXXX.0`（13位数字）
- 新格式：`ZL2022XXXXXXXX.X`（12位数字 + 校验位）
- 校验位可能是 0-9 或 X
- 搜索API时要去掉 `ZL`/`CN` 前缀和 `.X` 校验位

## 备用下载渠道（按推荐度）

### 免费无需登录
1. **Google Patents** — 首选，全球覆盖
2. **Espacenet** (worldwide.espacenet.com) — 欧洲专利局，403需UA伪装
3. **SooPAT** (www.soopat.com) — 国内可访问，中国专利多

### 免费需注册
1. **国家知识产权局公开系统** (pss-system.cponline.cnipa.gov.cn) — 最权威，需实名注册
2. **Baiten** (baiten.cn) — 佰腾专利，注册后可下载
3. **Himmpat** (himmpat.com) — 佛山知识产权服务平台

### 有限制
1. **CNKI 知网** — 有专利但只提供 CAJ 格式，需 CAJViewer 转 PDF
2. **智慧芽/incopat** — 付费机构订阅

### 本地资源
用户往往有本地存档，常见路径：
- 项目材料 / 专利全文
- 报奖材料 / 相关知识产权
- 论文归档 / 个人成果

## 命名规范

推荐格式：
```
{序号}.{专利名称}（{公开号}）.pdf
```

Windows 非法字符处理：
- `< > : " / \ | ? *` → `-`
- 文件名长度 ≤ 200 字符（含扩展名）

## 补充：国知局官方 epub.cnipa.gov.cn 下载渠道（备用）

**特点**：
- 免费、无需登录
- 有反爬保护（瑞数信息），必须用真实浏览器（Playwright）访问
- **PDF文件是完整的授权版**（含说明书、权利要求、附图）
- 对最新专利也有

**流程**（用Playwright）：
1. 打开 `http://epub.cnipa.gov.cn/`
2. 搜索框输入完整专利号（含B/A后缀），如 `CN{XXXXXX}B`
3. 点击"查询"按钮
4. 查询结果页面显示专利信息（授权号、公告日、发明人等）
5. 点击"发明专利"按钮 → 会打开新tab显示PDF预览
6. 页面顶部"下载PDF"按钮 或 **直接触发浏览器下载**
7. PDF会自动下载到Playwright的默认下载目录 (`.playwright-mcp/{申请号}.pdf`)

**PDF直链URL格式**：
```
http://egaz.cnipa.gov.cn/filedl?path={加密的path参数}
```
- 加密path每次不同，无法预测，必须通过页面点击触发

**Playwright脚本示例**：
```python
# 使用MCP Playwright或pypuppeteer
# 1. browser_navigate('http://epub.cnipa.gov.cn/')
# 2. browser_type(搜索框, 'CN{XXXXXX}B')
# 3. browser_click(查询按钮)
# 4. browser_click(发明专利按钮)
# 5. 等待下载完成
# 6. 从 .playwright-mcp/{申请号}.pdf 复制到目标位置
```

**适用场景**：
- Google Patents 找不到PDF的中国专利（尤其最新授权）
- 需要最完整的授权版（含专利证书扫描件）
- 一次只下载少量专利（大规模用Google Patents更快）

**限制**：
- 每小时可能有访问频率限制
- 需要通过图形化浏览器，无法直接requests.get
- 加密参数每次刷新
