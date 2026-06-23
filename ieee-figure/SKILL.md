---
name: ieee-figure
description: >-
  Publication-quality IEEE Transactions figure workflow for MATLAB, Python, or R.
  Generates figures conforming to IEEE editorial standards: Times New Roman fonts,
  single/double column sizing (3.5/7.16 in), inward ticks, bordered axes, 300+ dpi
  output, editable text. Use when creating, revising, or polishing figures for IEEE
  Transactions, IEEE Access, IEEE conferences (PES, IEC, IAS), or other IEEE venues.
  Supports MATLAB native plotting (primary), matplotlib/seaborn, and ggplot2.
  Triggers on: IEEE figure, IEEE style, transaction figure, IEEE plot, 论文配图,
  科研绘图, 画图, 出图, 论文图表, IEEE格式, 期刊图, 会议图.
version: 1.0.1
author: HZB
---

# IEEE Transactions Figure — Router

This skill produces publication-quality figures for IEEE Transactions and conferences.
The primary backend is **MATLAB** (for power systems / power electronics research),
with Python and R as secondary options.

## Routing protocol

### 1. Load core material

Read [manifest.yaml](manifest.yaml), then read `static/core/contract.md` and
`static/core/stance.md` in full. These define the figure contract, backend gate,
and default operating stance.

### 2. Resolve backend

The backend axis supports three values:

- `matlab` — MATLAB native plotting (default for power systems/PE research)
- `python` — matplotlib / seaborn
- `r` — ggplot2 / patchwork

If the user has not explicitly chosen **and** the input is a `.m` file or MATLAB
workflow, default to `matlab`. Otherwise ask: **MATLAB, Python, or R?** and wait.

### 3. Load the matching backend fragment

Read `static/fragments/backend/matlab.md`, `python.md`, or `r.md` per the resolved
backend. Each fragment carries the backend-specific quick-start (rcParams/theme/defaults),
export helper, and execution rules.

### 4. Build the figure

Apply in order:

1. **Figure contract** — core conclusion, evidence chain, archetype, export contract
2. **Default stance** — IEEE composition rules, color policy, typography
3. **Backend fragment** — code generation using the exclusive backend

### 5. References on demand

Open `references/ieee-style-guide.md` when you need precise IEEE sizing, font, or
export rules. Open `references/api.md` for MATLAB/Python helper functions. Open
`references/chart-types.md` for specific chart recipes (Bode, Nyquist, bar, heatmap,
contour, polar, 3D surface, etc.).
