---
name: patent-pdf-download
description: Batch download patent full-text PDF files. Use when the user asks to download patent PDFs (single or batch) by Chinese application number (like ZL2022xxxxxxxx.X), publication number (like CNxxxxxxxB, USxxxxxxxxB2, EPxxxxxxxA1), or when they provide a list of patents from an IP inventory / 知识产权清单. Supports CN/US/EP/JP patents. Two-tier strategy: Google Patents API (fast, batch) + epub.cnipa.gov.cn (authoritative fallback via Playwright) + local disk search.
---

# Patent PDF Download (Multi-Source)

Batch download patent full-text PDFs. **Never give up after one source fails** — this skill maintains an ordered list of independent channels; if channel A fails for a particular patent, fall through to channel B, then C.

## When to use

- User provides a list of Chinese/US/EP/JP patent numbers and asks to get the PDFs
- User has a "知识产权清单" (IP inventory) doc and wants each patent's PDF
- User needs patents in bulk (>5 items) — for 1-2 patents doing it manually via browser is faster

## Channels — try in this order

| # | Source | Requires | Best for | Speed |
|---|--------|----------|----------|-------|
| 1 | **Google Patents** (`patents.google.com`) | Network reach to Google | CN/US/EP/JP, bulk >20 patents | ⚡ Fast, scriptable |
| 2 | **epub.cnipa.gov.cn** (国知局公报公告站) | Playwright/browser (has anti-scraping) | Latest CN patents Google hasn't indexed | 🐢 Slower, GUI-driven |
| 3 | **User's local disk** | Access to project folders | Recovery when both online sources fail | ✅ Zero network |
| 4 | **CNKI, SooPAT, Baiten, Himmpat** | Manual browser (may need account) | Last resort | Manual |

Report per-patent which channel succeeded so the user can trust the source.

---

## Channel 1: Google Patents (primary)

### Step 1a — Confirm network

```bash
curl -o /dev/null -w "%{http_code}\n" https://patents.google.com --max-time 15
```

If not 200 → skip to Channel 2 for CN patents; for US/EP tell the user to enable proxy.

### Step 1b — Look up publication number (CN only)

Chinese patents use **publication numbers** on Google Patents, not application numbers.

```
https://patents.google.com/xhr/query?url=q%3D{application_number_digits}&exp=
```

Parse JSON:
```json
{"results":{"cluster":[{"result":[{"patent":{
  "publication_number": "CN{XXXXXX}B",
  "title": "..."
}}]}]}}
```

**⚠️ Number parsing gotcha**: Split the application number at `.` — the digit(s) after `.` are the check digit, don't include them in the search query. Example:
- `ZL202XXXXXXXX.X` → search `202XXXXXXXX` (12 digits, `.X` dropped)
- `ZL202XXXXXXXX.6` → search `202XXXXXXXX` (drop the `.6`, or `re.sub` will glue "6" into the query and return nothing)

### Step 1c — Try A version first (申请公开), then B (授权公告)

```python
base = re.sub(r'[AB]$', '', pub_no)
for suffix in ['A', 'B', '']:
    pnum = f'{base}{suffix}' if suffix else pub_no
    url = f'https://patents.google.com/patent/{pnum}'
    r = session.get(url, timeout=30)
    pdf_links = re.findall(
        r'https://patentimages\.storage\.googleapis\.com/[^"\']+\.pdf',
        r.text,
    )
    if pdf_links:
        break
```

**Empirical: A版 (申请公开) has PDFs in ~99% of cases, B版 (授权) often doesn't.**

### Step 1d — Download PDF, validate `%PDF` header

```python
r = requests.get(pdf_url, timeout=90)
if r.status_code == 200 and r.content[:4] == b'%PDF' and len(r.content) > 10240:
    open(save_path, 'wb').write(r.content)
```

### Step 1e — Naming

`{序号}.{专利名称去掉非法字符}（{实际下载的公开号}）.pdf`

Sanitize `< > : " / \ | ? *` → `-`.

**Full runnable script**: `scripts/download_patents.py`

---

## Channel 2: epub.cnipa.gov.cn (Chinese official, Playwright)

Use when Google Patents has no PDF for a specific CN patent (typically most recent grants) or when Google is unreachable.

**Requires an MCP Playwright browser session** — can't be done with plain `requests` (site uses 瑞数信息 anti-bot with obfuscated JS).

### Flow

1. `mcp__playwright__browser_navigate('http://epub.cnipa.gov.cn/')`
2. Type the **full publication number with A/B suffix** into the search box (e.g. `CN{XXXXXX}B`)
3. Click the "查询" (Search) button
4. On the result page, click the "发明专利" (Invention Patent) button — this opens a new tab with the PDF preview
5. The PDF **auto-downloads** to Playwright's download dir (`.playwright-mcp/{application_no}.pdf`)
6. Copy that file to the target folder with the correct name

The PDF URL that fires the download is:
```
http://egaz.cnipa.gov.cn/filedl?path={encrypted_path_that_expires}
```
— you can't shortcut the encrypted path; you MUST click through the UI.

### Rate limits

- No official documentation, but empirically ~1 request every 5 seconds is safe
- Anti-bot may trigger captcha (`egaz.cnipa.gov.cn/Captcha/...`) — pause and retry
- Do not run parallel requests to this site

### Playwright script skeleton

```python
# Assumes MCP Playwright is available in the current session
patent_no = 'CN{XXXXXX}B'

# 1. Navigate
mcp__playwright__browser_navigate(url='http://epub.cnipa.gov.cn/')

# 2. Type search
mcp__playwright__browser_type(target='<textbox ref>', text=patent_no)

# 3. Click search
mcp__playwright__browser_click(target='<查询 button ref>')

# 4. Wait for result page, then click 发明专利 button
mcp__playwright__browser_click(target='<发明专利 button ref>')

# 5. Wait for auto-download to .playwright-mcp/{application_no}.pdf
# 6. Copy to target folder
```

---

## Channel 3: User's local disk (recovery)

Users often have local copies of their own patents in project/archive folders. Search by patent number or title fuzzy match:

```bash
# Path keyword filter
find /path/to/archive -name "*.pdf" -path "*专利*" 2>/dev/null

# Filename contains patent number
find /path/to/archive -name "*{PATENT_NUM}*" 2>/dev/null

# Full-text search inside PDFs (requires pdfgrep)
pdfgrep -r "{PATENT_NUM}" /path/to/archive/
```

Or ask the user directly: "This patent isn't on Google Patents. Do you have a local copy?"

---

## Channel 4: Manual browser fallbacks (last resort)

| Site | URL | Notes |
|------|-----|-------|
| SooPAT | https://www.soopat.com | Free, CN patents, in-browser search |
| Baiten | https://www.baiten.cn | Free, requires account for full PDF |
| Himmpat | https://www.himmpat.com | Free, IP service platform |
| 国知局pss-system | https://pss-system.cponline.cnipa.gov.cn | Official, requires 实名注册 |
| CNKI | https://kns.cnki.net | Provides CAJ format only — user must convert via CAJViewer |
| Espacenet | https://worldwide.espacenet.com | EPO, US/EP/CN family lookup |
| Google Scholar | https://scholar.google.com | Sometimes hosts CN patents cited by papers |

For these, list the search URL for each failed patent so the user can click through manually.

---

## Batch execution strategy

For **>20 patents**, use subagents in parallel:

- Split patent list into groups of 15
- Launch 1 subagent per group with `Agent tool` (general-purpose)
- Each subagent uses Channel 1 (Google Patents) independently
- Failures from all subagents get collected, then run Channel 2 (epub.cnipa.gov.cn) sequentially in the main session
- Report final tally: `Channel 1: N succeeded, Channel 2: M succeeded, Channel 3: K succeeded, Failed: X`

---

## Common pitfalls & lessons learned

- **Wrong URL format for CN patents on Google**: `patents.google.com/patent/CN{application_number}` returns 404. Must use publication number.
- **B suffix vs A suffix**: Many CN B (grant) pages exist but have no PDF. Try A (application) first.
- **Application number check digit**: When calling the search API, strip the `.X` / `.数字` — otherwise the query returns 0 results.
- **SSL flakiness**: Google Patents drops occasional connections. Add `time.sleep(2)` between requests, retry once.
- **Playwright download location**: MCP Playwright saves to `.playwright-mcp/` inside the current working directory, filename derives from the application number (not the publication number).
- **epub.cnipa auto-download**: Clicking "发明专利" button in result page triggers download automatically — don't need to click "下载PDF" separately.
- **Latest CN patents (recent grants)**: Google Patents may not yet have PDFs. Always fall through to Channel 2.

## Empirical success rates

From batch runs on real IP inventories (60+ patents at a time):

| Patent type | Channel 1 (Google) | Channel 2 (epub) |
|-------------|--------------------|------------------|
| CN, filed years ago, grant status | ≈99% | 100% (fallback) |
| CN, freshly granted (< 3 months) | ~70% (may lack PDF) | 100% |
| US / EP / JP | ≈99% | N/A |

**Takeaway**: Google Patents alone gets you ~99% of the way. The remaining <1% (newest CN grants) needs epub.cnipa.gov.cn or the user's local disk.
