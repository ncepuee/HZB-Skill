---
name: openstd-pdf-download
description: Download public PDF full texts from China's SAMR/SAC national standards platforms, especially openstd.samr.gov.cn and std.samr.gov.cn GB/T detail pages. Use when the user asks to fetch national standard PDF source files, resolve hcno download links, keep only GB/T standards, or rename PDFs by release date, Chinese standard name, and standard number.
---

# Openstd PDF Download

## Workflow

Use `scripts/download-openstd-pdf.ps1` for repeatable downloads. It handles the fragile platform sequence:

1. Read each input URL or saved HTML source page.
2. Extract `标准号`, `中文标准名称` or page title, `发布日期`, and `hcno`.
3. Skip non-`GB/T` entries when `-GbTOnly` is set.
4. Visit `showGb?type=download&hcno=...` first to establish the download page/session.
5. Download the real PDF from `viewGb?hcno=...`.
6. Keep the file only if the first four bytes are `%PDF`.

Run from PowerShell:

```powershell
.\scripts\download-openstd-pdf.ps1 `
  -Urls @(
    'https://std.samr.gov.cn/gb/search/gbDetailed?id=...',
    'https://openstd.samr.gov.cn/bzgk/std/newGbInfo?hcno=...'
  ) `
  -OutDir 'C:\Users\hzb\Downloads\许继国家标准' `
  -GbTOnly
```

For saved browser source pages, pass file paths:

```powershell
.\scripts\download-openstd-pdf.ps1 `
  -Urls @('C:\Users\hzb\Downloads\许继国家标准\view-source_https___openstd...html') `
  -OutDir 'C:\Users\hzb\Downloads\许继国家标准' `
  -GbTOnly
```

## Naming

Name successful PDFs as:

```text
yyyyMMdd_中文标准名称_标准号.pdf
```

On Windows, sanitize forbidden filename characters. In practice `GB/T 34120-2023` becomes `GB_T 34120-2023`.

## Failure Rules

- Do not keep zero-byte files or HTML files renamed as `.pdf`.
- If `showGb` returns 404, no download button exists, or `viewGb` returns 0 bytes, report the entry as skipped.
- `std.samr.gov.cn` detail pages may point to replaced/newer GB/T entries; only download those if the user asked to include replacement standards.
- Industry standards and备案 pages are out of scope unless the user explicitly asks for non-GB/T items.

