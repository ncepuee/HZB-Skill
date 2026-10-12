---
name: excel-to-pdf
description: Convert Excel workbooks to verified A4 PDFs. Preserve the workbook's native layout for formal forms with merged cells, fixed row heights, signatures, or print formatting; rebuild only simple rosters and sign-in sheets when a clean table is desired.
---

# Excel to verified A4 PDF

Choose the mode from the workbook and the user's intent.

## Mode selection

- **Preserve mode (default):** use for applications, approvals, certificates, official forms, merged cells, custom borders/fonts, or when the user says to keep the original layout. Run `scripts/excel_to_pdf_preserve.ps1` on Windows with desktop Excel.
- **Rebuild mode:** use only for simple rosters, sign-in sheets, and plain data tables when restyling is acceptable. Run `scripts/excel_to_pdf_signin.py`.
- Do not use rebuild mode for a formal workbook merely because it contains a table: that script discards merges and native formatting.

## Preserve-mode workflow

1. Inspect sheet names, used range, merged ranges, explicit row heights, print area, and orientation.
2. Keep the source workbook unchanged. The preserve script opens it read-only and applies print fixes only in memory.
3. Set ISO A4, the requested orientation, print area, proportional fit, and page centering. Default to one page only when the form is intended to be one page; otherwise use `OnePageWide`.
4. Treat fixed-height merged rows containing wrapped text as a clipping risk. Render once, inspect, then pass only the necessary corrections with `-RowHeight '4=105','7=50'` and `-WrapRange 'B4:E4','B7:E7'`. Do not guess row changes before inspecting the output.
5. Preserve an existing output PDF unless the user explicitly does not need a backup. The script creates a timestamped backup by default.
6. Normalize the exported PDF to exact ISO A4 through the sibling `pdf-a4-normalizer` skill when available, then run `scripts/verify_excel_pdf.py`.
7. For a small document, visually inspect every page. Confirm that headers, final lines in merged cells, borders, signatures, and page breaks are visible. Text extraction alone does not prove that text is not covered by a border.

### Preserve-mode examples

```powershell
# Preserve native layout, one-page portrait, centered on the sheet
powershell -ExecutionPolicy Bypass -File scripts/excel_to_pdf_preserve.ps1 `
  -InputPath 'C:\path\form.xlsx' `
  -OutputPath 'C:\path\form.pdf' `
  -Orientation Portrait `
  -PageMode OnePage `
  -CenterHorizontally:$true `
  -CenterVertically:$true `
  -PreviewDir 'C:\path\preview'

# Correct only rows proven to clip after the first render
powershell -ExecutionPolicy Bypass -File scripts/excel_to_pdf_preserve.ps1 `
  -InputPath 'C:\path\form.xlsx' `
  -OutputPath 'C:\path\form.pdf' `
  -RowHeight '4=105','7=50' `
  -WrapRange 'B4:E4','B7:E7' `
  -RequiredText '比赛或项目等名称需写清楚' `
  -ExpectedPages 1 `
  -PreviewDir 'C:\path\preview'
```

Useful preserve-mode options:

- `-Sheet '申请简表'`
- `-Orientation Auto|Portrait|Landscape`
- `-PageMode OnePage|OnePageWide|Existing`
- `-MarginMm 8`
- `-RowHeight 'ROW=POINTS'`
- `-WrapRange 'A1:D4'`
- `-RequiredText 'critical final phrase'`
- `-ExpectedPages 1`
- `-NoBackup`, `-SkipA4Normalize`, or `-SkipVerify` only for a specific reason

## Rebuild mode

```powershell
python scripts/excel_to_pdf_signin.py 'C:\path\roster.xlsx'
```

The rebuild script creates a new ReportLab table with Chinese fonts. Its `--columns`, `--col-widths`, `--orientation`, `--margin`, `--row-height`, and `--font-size` options are intended for plain tabular data, not native Excel layout preservation.

## Acceptance criteria

- Output opens successfully and has the expected page count.
- Every page is ISO A4 portrait or landscape within 2 points.
- The source workbook is unchanged.
- No wrapped or merged-cell text is clipped, hidden by borders, or truncated at the right edge.
- Required final phrases are extractable from the PDF.
- Existing output was backed up before replacement unless explicitly disabled.
- The final PDF was rendered and visually inspected in proportion to the document size.

## Dependencies

- Preserve mode: Windows desktop Excel; Python 3 with `pypdf`; `pypdfium2` for previews; sibling `pdf-a4-normalizer` with PyMuPDF for exact A4 normalization.
- Rebuild mode: Python 3 with `openpyxl` and `reportlab`, plus a Chinese-capable system font.

If desktop Excel is unavailable, use LibreOffice headless export as a fallback and report that rendering may differ; do not silently rebuild a formal form.
