---
name: math-latex-auditor
description: Draft, audit, and safely repair academic Markdown/MathJax formulas according to the user's formula-writing standard. Use whenever creating or editing Markdown documents containing LaTeX equations, especially derivations, reviewer responses, research notes, and simulation-validation reports. Also use when the user asks to check formula formatting, equation tags, textual subscripts, matrices, units, imaginary units, or MathJax rendering.
---

# Math LaTeX Auditor

Apply the rules in [references/formula-standard.md](references/formula-standard.md). If the user names a newer project-specific SOP, read it completely and treat it as authoritative where it conflicts with this bundled reference.

## Operating modes

- **Drafting:** Apply the standard while composing every formula-bearing Markdown document.
- **Audit-only:** Inspect and report exact line numbers without changing the file.
- **Repair:** Preserve technical meaning and prose, create a timestamped backup beside the target, make only formula-formatting changes, then validate and read back the actual target.

Infer the requested mode from the user's wording. “看看、检查、审阅” means audit-only. “修改、整理、规范化” authorizes repair. Never silently turn an audit into an edit.

## Required workflow

1. Read the whole target and identify frontmatter, fenced code blocks, tables, inline math, and display math.
2. Shield frontmatter and fenced code blocks from formula rewrites. Do not rewrite MATLAB, Python, shell, JSON, YAML, or other source code as LaTeX.
3. Preserve mathematical meaning, variable definitions, equation order, existing section structure, and the document's established tag prefix.
4. Apply the bundled formula rules. Use mathematical context to distinguish textual labels from true mathematical indices.
5. Run `scripts/audit_math_markdown.ps1` against the actual target. Treat deterministic errors as blocking.
6. Manually review semantic items that a script cannot decide reliably: matrix/vector typography, whether a subscript is textual, unit scope, equation-tag scheme, and whether claims exceed the stated model or validation domain.
7. For repairs, read back the named target after writing and report its path, backup path, audit status, and SHA-256 hash.

## Equation-tag policy

For formal derivations and reviewer-response notes, require exactly one `\tag{...}` in each display-math block unless the user or the active template explicitly permits unnumbered equations. Preserve the existing tag family. If no scheme exists, choose a local section-based prefix only when it is unambiguous; otherwise report the missing decision instead of inventing manuscript-wide numbering.

## Audit result

Return one of these states:

- `PASS`: no deterministic error remains and manual semantic checks pass.
- `PASS WITH WARNINGS`: rendering is valid, but contextual typography or numbering needs author confirmation.
- `NEEDS FIX`: at least one blocking syntax, delimiter, environment, or tag error remains.

List only actionable findings. Include severity, line number, current fragment, and recommended form. Do not declare `PASS` solely because the script exits successfully.

## Deterministic checker

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/audit_math_markdown.ps1 -Path "<document.md>"
```

Use `-AllowUntagged` only when the applicable document template intentionally permits unnumbered display equations. Use `-Json` for machine-readable output.
