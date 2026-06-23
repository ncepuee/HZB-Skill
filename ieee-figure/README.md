# IEEE Figure Skill

Publication-quality IEEE Transactions figure generation for MATLAB, Python, and R.

Current version: **v1.0.1**

## Features

- **MATLAB-native support** (primary backend for power systems research)
- IEEE editorial standards: Times New Roman, bordered axes, inward ticks, 300+ dpi
- Paul Tol muted color palette (colorblind-safe, grayscale-safe)
- Optional `slanCM` palettes with an IEEE-safe fallback
- Visio-editable MATLAB bar charts using individual `rectangle` objects
- Pre-built templates for: Bode, Nyquist, pole maps, heatmaps, contour, bar, compass, 3D surface
- One-click export: PDF (vector) + EMF (editable) + TIFF (600 dpi)
- Single-column (3.5 in) and double-column (7.16 in) sizing

## Structure

```
ieee-figure/
├── SKILL.md                          # Router (entry point)
├── manifest.yaml                     # Backend routing manifest
├── static/
│   ├── core/
│   │   ├── contract.md               # Figure contract (pre-plot checklist)
│   │   └── stance.md                 # IEEE composition rules, color policy, typography
│   └── fragments/backend/
│       ├── matlab.md                 # MATLAB quick-start + all templates
│       ├── python.md                 # matplotlib quick-start
│       └── r.md                      # ggplot2 quick-start
├── references/
│   ├── ieee-style-guide.md           # IEEE editorial requirements
│   ├── api.md                        # Helper functions (palette, export, axes)
│   ├── chart-types.md                # Power systems chart recipes
│   ├── design-theory.md              # Color/typography rationale
│   ├── common-patterns.md            # Multi-panel layout patterns
│   ├── figure-contract.md            # Review-risk checks
│   └── tutorials.md                  # End-to-end examples
└── assets/                           # Example outputs
```

## Quick start (MATLAB)

```matlab
% 1. Set IEEE defaults (run once)
set_ieee_defaults();

% 2. Create figure
fig = figure('Color','w','Units','inches','Position',[3 3 3.5 2.6]);
ax = ieee_axes(fig);

% 3. Plot
plot(ax, x, y, '-', 'Color', ieee_palette('black'), 'LineWidth', 1.2);
xlabel(ax, 'Frequency (Hz)', 'FontSize', 9);
ylabel(ax, 'Magnitude (dB)', 'FontSize', 9);

% 4. Export
save_ieee(fig, 'Fig1_Impedance');
```

## Trigger phrases

- "IEEE figure", "IEEE style", "transaction figure"
- "论文配图", "科研绘图", "IEEE格式", "期刊图"
- "make a publication figure", "plot for IEEE paper"

## Color palette

| Name | RGB | Hex | Use |
|---|---|---|---|
| Black | `[0 0 0]` | `#000000` | Primary data |
| Blue | `[0 0.45 0.74]` | `#0072B2` | Secondary data |
| Vermillion | `[0.85 0.33 0.10]` | `#D55E00` | Alerts, peaks |
| Green | `[0 0.62 0.45]` | `#009E73` | Positive, stable |
| Purple | `[0.50 0.15 0.50]` | `#882255` | Additional data |
| Grey | `[0.50 0.50 0.50]` | `#808080` | Reference |

## Version history

| Version | Changes |
|---|---|
| v1.0.1 | Added Visio-editable `rectangle` bar charts, 90 mm MATLAB figure sizing, light bar borders, grid-off guidance, and optional `slanCM` palettes. |
| v1.0.0 | Initial IEEE figure workflow with MATLAB, Python, and R backends, core figure rules, chart templates, palettes, and export helpers. |

## License

MIT
