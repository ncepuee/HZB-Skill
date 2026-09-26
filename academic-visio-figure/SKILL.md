---
name: academic-visio-figure
description: Create, reconstruct, refine, and audit editable Microsoft Visio VSDX figures for papers, theses, reports, and technical publications. Use for flowcharts, control block diagrams, circuit and network schematics, architecture diagrams, scientific workflows, image-to-Visio reconstruction, publication sizing, mathematical typography, style normalization, or structural QA on Windows with Visio installed.
---

# Academic Visio Figure

Apply publication-level reasoning to Visio diagrams without imposing one paper's visual choices on unrelated figures. Use `visio-skill` for general COM drawing mechanics when available; this skill supplies the publication contract, style resolution, semantic typography, and regression gates.

## Choose the operating mode

- **Create** — build a new editable figure from a description, data, or source material.
- **Reconstruct** — convert a screenshot or raster reference into native Visio shapes, text, and one-dimensional lines.
- **Refine** — resize, restyle, relabel, or repair an existing `.vsdx`.
- **Audit** — inspect structure and style without changing the file.

The modes share the same style-resolution and validation rules. Read [references/style-contract.md](references/style-contract.md) whenever sizing, typography, line styling, or a named profile is involved.

## Resolve the style before editing

Build a task-specific style contract from the highest available source:

1. explicit instructions in the current request;
2. a user-corrected exemplar or accepted prior revision;
3. the target venue, thesis, or report template;
4. a named profile supplied with the skill;
5. conservative defaults inferred from the final output size and diagram type.

Do not treat values learned from one diagram as universal. Page width, font size, line weight, arrow style, palette, symbol conventions, and math typography are independent parameters. Ask only when a missing choice would materially change the result and cannot be inferred from the target format.

## Workflow

1. Inventory the source: pages, dimensions, recursive shapes, groups, one-dimensional lines, text runs, embedded media, colors, line weights, arrows, and reusable masters.
2. For an existing file, save a timestamped sibling backup before the first mutation. Preserve user-authored local corrections.
3. Establish the final physical size before detailed layout. Fit the composition, symbols, spacing, labels, and arrowheads as a system; changing only the font size does not create a manuscript-ready figure.
4. Keep the result editable: native Visio shapes, one-dimensional lines/connectors, and text. Do not use a rasterized page as the deliverable or simulate lines with narrow rectangles.
5. Apply styles by semantic role rather than global replacement: primary flow, secondary relation, enclosure, annotation, source, load, warning, or domain-specific symbol.
6. Apply mixed typography within a single semantic label. Keep acronyms and descriptive identifiers upright; italicize mathematical variables where appropriate; format descriptive and variable subscripts separately.
7. Export a preview at the intended physical size and inspect balance, clipping, overlaps, margins, legibility, and symbol-to-text proportion.
8. Run the structural audit with explicit expectations or a named profile. Compare shape/line/media counts with the baseline when refining an existing file.
9. When reverting a late correction, change only the requested property and repeat the audit. Do not roll back unrelated accepted edits.

## General audit

Run without expectations to obtain a reusable inventory:

```powershell
powershell -ExecutionPolicy Bypass -File "<skill>/scripts/audit_visio_figure.ps1" `
  -VsdxPath "<figure.vsdx>"
```

Pass requirements explicitly for any project:

```powershell
powershell -ExecutionPolicy Bypass -File "<skill>/scripts/audit_visio_figure.ps1" `
  -VsdxPath "<figure.vsdx>" `
  -ExpectedPageWidthCm 8.8 `
  -ExpectedLineWeightPt 0.6 `
  -ExpectedArrowType 4 `
  -AllowedFontSizePt 7,8,9 `
  -RequireNoMedia
```

Use `-ProfilePath "<profile.json>"` when a project has a stable house style. `profiles/hzb-paper-8pt-electrical.json` preserves the values learned in the originating workflow, but it must be selected explicitly and is not the default for other figures.

## Semantic text rules

- Keep one semantic label in one Visio text shape even when it mixes base text, subscripts, superscripts, upright identifiers, and italic variables.
- Treat domain acronyms and named components—such as `GFL`, `GFM`, `PLL`, `PI`, `REF`, `API`, or `PCC`—as upright unless the notation definition says otherwise.
- Treat mathematical quantities and indices as variables according to the notation used by the document. Descriptive subscripts are normally upright; variable indices are normally italic; numerals are upright.
- Preserve user-selected Unicode glyphs and normalization forms. Visually similar precomposed and combining sequences are not automatically interchangeable.
- Use `math-latex-auditor` as a second pass when available, while preserving explicit exceptions and the source document's notation table.

## Diagram-aware layout

- **Flow/process diagrams:** preserve reading order and decision semantics; keep connectors distinguishable at the final size.
- **Control block diagrams:** align signal paths, summing junctions, branch points, and feedback loops; avoid ambiguous crossings.
- **Circuit/network schematics:** preserve topology, node identity, terminal orientation, and symbol semantics before visual cleanup.
- **Architecture/scientific workflows:** preserve hierarchy and grouping; use restrained role-based color rather than decorative variation.
- **Image reconstruction:** reproduce semantic objects, not pixels; identify complete reusable blocks and keep them groupable or master-ready.

## Completion report

Report the deliverable, preview, backup if created, page dimensions, recursive shape count, one-dimensional line count, embedded-media count, applied profile or explicit expectations, and intentional exceptions. Structural checks supplement visual inspection; they do not replace it.

