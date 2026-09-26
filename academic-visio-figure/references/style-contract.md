# General academic Visio style contract

Use this reference to derive a figure-specific contract. It defines decision fields and verification methods, not a mandatory visual theme.

## Contract fields

| Field | Decide from | Verification |
|---|---|---|
| Target medium | journal, thesis, report, slide, poster | preview at intended physical size |
| Page width/height | venue column or user-established canvas | PageSheet dimensions |
| Typography | venue template and document notation | effective Character rows and visual preview |
| Line hierarchy | diagram density and semantic roles | recursive line-weight distribution |
| Arrow style | flow semantics and accepted exemplar | begin/end arrow type and size |
| Palette | print mode, accessibility, semantic roles | line/fill/text color distribution |
| Editability | downstream editing needs | native shapes/text/1-D lines; media inventory |
| Structural invariants | source topology or accepted revision | shape, group, line, connection, and media counts |

Values are independent. A compact page does not automatically imply one font, arrow, or color. A named profile is a convenience only after the user or project has chosen it.

## Precedence

Use: current explicit request → manually corrected exemplar → venue or project template → explicitly selected profile → conservative inference. Never promote a one-off correction into a global rule without evidence that it is part of the house style.

## Semantic typography

Keep each semantic expression in one text shape and format character ranges. This applies across domains:

- acronyms, function names, named subsystems, and descriptive prose are normally upright;
- mathematical quantities and variable indices are normally italic;
- descriptive subscripts and numerals are normally upright;
- superscript/subscript position is independent from italic/upright style;
- preserve the source document's notation table and explicit user exceptions.

Visio may store several Character rows in a single text shape. Inspect the effective rows rather than editing only the shape default. Do not split a label into multiple boxes merely to obtain mixed formatting.

## Geometry and scaling

Establish final page dimensions first. Adjust symbols, gaps, text blocks, line weights, arrows, and label offsets together. For dense figures, prefer simplifying nonessential detail and improving grouping over shrinking text below the publication's readable range.

Use native one-dimensional lines/connectors for semantic connections. Preserve endpoint identity and routing intent. Converting a visible segment must not silently change topology, z-order, or glue behavior.

## Safe edit sequence

1. Back up the source and export a baseline preview.
2. Inventory structure and style distributions.
3. Resolve the task-specific style contract.
4. Set or preserve the target page dimensions.
5. Adjust layout and symbol scale.
6. Normalize connections and line geometry.
7. Apply role-based strokes, arrows, fills, and colors.
8. Apply text size and mixed character formatting.
9. Save, close, reopen for audit, and export the final preview.
10. Ensure automation did not leave hidden orphan Visio processes.

## Regression gates

Investigate before completion when any of these occurs:

- topology, recursive shape count, group structure, or 1-D line count changes unexpectedly;
- embedded media appears without being part of the requested deliverable;
- a semantic label is fragmented solely for formatting;
- a user-approved page dimension changes;
- a local typography correction changes unrelated geometry or colors;
- a global style replacement modifies semantically different roles;
- the file passes structural checks but is illegible or visually unbalanced at final size.

## Named profiles

Profiles are JSON files containing only stable project choices. Supported audit keys are:

```json
{
  "name": "project-style-name",
  "expectedPageWidthCm": 8.8,
  "expectedLineWeightPt": 0.5,
  "expectedArrowType": 5,
  "allowedFontSizesPt": [7, 8, 9],
  "requireNoMedia": true,
  "notes": ["Human-readable semantic conventions not enforced mechanically."]
}
```

Keep domain-specific colors, symbol rules, and notation exceptions in `notes` unless their scope can be identified deterministically. Do not audit a role-specific color as though every shape must use it.

