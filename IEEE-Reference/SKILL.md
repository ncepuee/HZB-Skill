---
name: ieee-reference
description: Format, audit, and generate BibTeX references for IEEE Transactions style, especially IEEE TIE LaTeX templates using cite, Bibliography/IEEEtranTIE.bst, IEEEabrv.bib, and Bibliography/BIB_xx-TIE-xxxx.bib. Use when preparing IEEE/TIE/TPEL/TIA references, converting manual references to BibTeX, checking citation style, DOI/page/author fields, @standard, @patent, @inbook/@incollection entries, or LaTeX/BibTeX bibliography setup.
---

# IEEE Reference

Use this skill to prepare references for IEEE Transactions papers, with the local TIE template as the source of truth:

```latex
\usepackage{cite}
\bibliographystyle{Bibliography/IEEEtranTIE}
\bibliography{Bibliography/IEEEabrv,Bibliography/BIB_xx-TIE-xxxx}
```

Write project references to `Bibliography/BIB_xx-TIE-xxxx.bib` unless the user names another `.bib` file. Use `IEEE_Reference_BibTeX_Templates.bib` in this skill folder for copyable entry patterns.

## Workflow

1. Inspect the target paper's `.tex` and `.bib` files before editing.
2. Add or normalize BibTeX entries in the project bibliography file.
3. Make sure every bibliography entry is cited in the text, and every `\cite{...}` key exists.
4. Use the template build order when compiling is available:

```bash
pdflatex main.tex
bibtex main
pdflatex main.tex
pdflatex main.tex
```

5. Check the `.blg`/LaTeX log for `Warning--empty`, undefined references, duplicate keys, and multiply defined citations.

## TIE Citation Rules

- Do not cite references in the abstract.
- Cite where the statement first needs support in the main text.
- Use `\cite{key}` for numeric citations. For multiple references, use one command such as `\cite{Wen2016DQImpedance,Kong2025DampingGFM}` and let the `cite` package format the labels.
- Put citation commands before sentence punctuation:

```latex
The impedance-based criterion is widely used for converter stability analysis~\cite{Wen2016DQImpedance}.
```

- Do not write `Ref. \cite{...}` inside a sentence. Use the numeric citation directly, or write `Reference~\cite{...}` only when the sentence begins with "Reference".
- Do not combine multiple papers into one BibTeX entry. Each numbered reference must map to one source.

## BibTeX Rules

- Use `and` between authors:

```bibtex
author = {B. Wen and D. Boroyevich and R. Burgos and P. Mattavelli and Z. Shen}
```

- Initial-based names are appropriate for IEEE output. `Wen, B. and Boroyevich, D.` is also valid BibTeX, but do not comma-separate multiple authors inside one name field.
- List all authors by default. Use `and others` only for exceptional very-long author lists where the journal or source style requires `et al.`; the local `IEEEtranTIE.bst` does not force truncation by default.
- Use sentence case for article and conference paper titles. Protect required capitalization with braces, for example `{IEEE}`, `{GFM}`, `{GFL}`, `{IBR}`, `{VSC}`, `{PLL}`, `{VSG}`, `{STATCOM}`, `{HVDC}`, `{SISO}`, `{MIMO}`, `{dq}`, `{d-q}`, `{LC}`, `{LCL}`, `{DC}`, `{AC}`.
- Use double hyphens in page ranges, for example `pages = {675--687}`.
- Prefer BibTeX month macros such as `jan`, `apr`, and `sep`.
- For IEEE journal names, either use a known `IEEEabrv.bib` macro or write the full journal name. If the macro name is uncertain, use the full journal name.

## Required Fields

For `@article`, include `author`, `title`, `journal`, `volume`, `number`, `pages`, `month` or `year`, and `doi` when available.

For `@inproceedings`, include `author`, `title`, `booktitle`, `pages`, `year`, and add `address`, `month`, and `doi` when available.

For `@standard`, use `title`, `organization`, `type`, `number`, and `year`. In this TIE `.bst`, `@standard` does not call the normal `doi` formatter, so put a standards DOI in `note`:

```bibtex
note = {doi: 10.xxxx/xxxx}
```

For `@patent`, use `author`, `title`, `nationality`, `type`, `number`, `month`, `day`, and `year` when available.

For book sections:

- Use `@inbook` when citing pages or a chapter inside a book and the entry title is the book title.
- Use `@incollection` when the chapter/section has its own title and `booktitle` is the book title. The local `IEEEtranTIE.bst` supports `@incollection`.

## Online Sources

Use DOI fields for papers when a DOI exists; do not place DOI URLs in `url`:

```bibtex
doi = {10.1109/xxxx}
```

Use `url` for true online sources or when the print reference needs a web source. The local `.bst` outputs URL fields with the IEEE online prefix. Include access dates in `note` when needed:

```bibtex
note = {Accessed: Oct. 7, 2024}
url  = {https://example.com}
```

Use `@misc` only when the item does not fit a paper, standard, report, patent, thesis, or book type.

## Final Check

- Abstract contains no `\cite{}`.
- Every BibTeX entry is cited, and every citation key exists.
- Article/conference entries include DOI when available.
- Standards use `@standard`, not `@patent` or `@misc`.
- Patent entries use `@patent` and include country/region, patent number, and date.
- Page ranges use `--`.
- Author lists use `and`.
- Required capitalization is protected with braces.
- BibTeX and LaTeX logs have no unresolved reference or empty-field warnings that affect the final bibliography.
