"""Verify A4 dimensions, page count, critical text, and optional page previews."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

from pypdf import PdfReader


A4_PORTRAIT = (595.2756, 841.8898)
A4_LANDSCAPE = (841.8898, 595.2756)


def compact(text: str) -> str:
    return re.sub(r"\s+", "", text)


def is_a4(width: float, height: float, tolerance: float) -> bool:
    return any(
        abs(width - target_w) <= tolerance and abs(height - target_h) <= tolerance
        for target_w, target_h in (A4_PORTRAIT, A4_LANDSCAPE)
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("pdf", type=Path)
    parser.add_argument("--expected-pages", type=int, default=0)
    parser.add_argument("--required-text", action="append", default=[])
    parser.add_argument("--preview-dir", type=Path)
    parser.add_argument("--tolerance-pt", type=float, default=2.0)
    parser.add_argument("--json-out", type=Path)
    args = parser.parse_args()

    pdf = args.pdf.resolve()
    errors: list[str] = []
    warnings: list[str] = []
    if not pdf.is_file():
        print(f"ERROR: PDF not found: {pdf}", file=sys.stderr)
        return 2

    try:
        reader = PdfReader(str(pdf))
    except Exception as exc:
        print(f"ERROR: cannot open PDF: {exc}", file=sys.stderr)
        return 2

    page_count = len(reader.pages)
    if args.expected_pages and page_count != args.expected_pages:
        errors.append(f"expected {args.expected_pages} pages, got {page_count}")

    page_sizes = []
    extracted = []
    for index, page in enumerate(reader.pages, start=1):
        width = float(page.mediabox.width)
        height = float(page.mediabox.height)
        page_sizes.append({"page": index, "width_pt": width, "height_pt": height})
        if not is_a4(width, height, args.tolerance_pt):
            errors.append(f"page {index} is not A4: {width:.2f} x {height:.2f} pt")
        extracted.append(page.extract_text() or "")

    all_text = compact("\n".join(extracted))
    missing_text = [text for text in args.required_text if compact(text) not in all_text]
    for text in missing_text:
        errors.append(f"required text not found: {text}")

    previews: list[str] = []
    if args.preview_dir:
        try:
            import pypdfium2 as pdfium

            args.preview_dir.mkdir(parents=True, exist_ok=True)
            document = pdfium.PdfDocument(str(pdf))
            for index in range(len(document)):
                output = args.preview_dir / f"{pdf.stem}_page_{index + 1}.png"
                document[index].render(scale=1.5).to_pil().save(output)
                previews.append(str(output))
        except ImportError:
            warnings.append("pypdfium2 is unavailable; previews were not rendered")
        except Exception as exc:
            errors.append(f"preview rendering failed: {exc}")

    report = {
        "pdf": str(pdf),
        "pages": page_count,
        "page_sizes": page_sizes,
        "text_chars": sum(len(text) for text in extracted),
        "missing_required_text": missing_text,
        "previews": previews,
        "warnings": warnings,
        "errors": errors,
        "ok": not errors,
    }
    rendered = json.dumps(report, ensure_ascii=False, indent=2)
    print(rendered)
    if args.json_out:
        args.json_out.parent.mkdir(parents=True, exist_ok=True)
        args.json_out.write_text(rendered + "\n", encoding="utf-8")
    return 0 if not errors else 2


if __name__ == "__main__":
    raise SystemExit(main())
