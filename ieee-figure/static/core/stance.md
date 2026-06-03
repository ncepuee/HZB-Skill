# Default Operating Stance — IEEE Transactions

## Composition

- **Hero panel first.** One panel should dominate (≥50% of canvas). Supporting panels
  are smaller and serve as evidence reinforcement.
- **White background always.** No colored figure backgrounds. No gradient fills on axes.
- **Direct labels over legends** when categories are spatially fixed or ≤4 items.
  Legends go inside the axes (top-right or bottom-left) to minimize dead space.
- **Panel labels**: `(a)`, `(b)`, `(c)` in **bold Times New Roman 10pt**, placed at
  top-left corner of each panel with 1% offset from edges.

## Typography

| Element | Font | Size | Weight |
|---|---|---|---|
| Axis labels | Times New Roman | 9 pt | Normal |
| Tick labels | Times New Roman | 8 pt | Normal |
| Panel labels | Times New Roman | 10 pt | **Bold** |
| Legend text | Times New Roman | 8 pt | Normal |
| Annotation text | Times New Roman | 8 pt | Normal |
| Title (if used) | Times New Roman | 10 pt | **Bold** |

**Do not use Arial, Helvetica, or sans-serif fonts** unless the journal explicitly
requires it (IEEE Access allows sans-serif, but IEEE Trans requires serif).

## Color policy

### Primary palette (data curves)

Use a **maximum of 6 distinguishable colors**. For power systems / power electronics:

| Role | Color | RGB |
|---|---|---|
| Primary data | Black | `[0 0 0]` |
| Secondary data | Strong Blue | `[0.00 0.45 0.74]` |
| Tertiary data | Vermillion | `[0.85 0.33 0.10]` |
| Quaternary data | Bluish Green | `[0.00 0.62 0.45]` |
| Quinary data | Reddish Purple | `[0.50 0.15 0.50]` |
| Reference/grid | Grey | `[0.50 0.50 0.50]` |

This is the Paul Tol muted palette, widely used in IEEE publications.

### Signal colors (for annotations, alerts, boundaries)

| Role | Color | RGB |
|---|---|---|
| Stable / positive | Bluish Green | `[0.00 0.62 0.45]` |
| Unstable / negative | Vermillion | `[0.85 0.33 0.10]` |
| Boundary / threshold | Red | `[0.80 0.00 0.00]` |
| Fill / highlight | Same hue, 8–12% alpha | — |

### Anti-patterns

- Do not use `jet`, `rainbow`, or `hsv` colormaps. Use `parula`, `turbo`, or custom.
- Do not encode more than 3 categories with color alone. Use line style (solid/dashed/dotted)
  and marker shape as secondary channels.
- Do not use yellow for data. It disappears on white background.

## Axes

| Property | Setting |
|---|---|
| Box | `on` (bordered) |
| TickDir | `in` (inward) |
| TickLength | `[0.015 0.015]` |
| LineWidth | 0.6 pt |
| Grid | Off by default; enable only Y-grid with `[0.85 0.85 0.85]` at alpha 0.5 |
| MinorTick | Off (unless log-scale with sparse major ticks) |

## Markers and lines

| Element | Style |
|---|---|
| Data curves | Solid, 1.0–1.5 pt |
| Reference curves | Dashed, 1.0 pt |
| Threshold lines | Dashed or dotted, 0.8 pt |
| Data markers | Circle 4pt, filled, 0.6pt edge |
| Peak markers | 5pt, filled with signal color |

## Export policy

**Always export as vector format first** (PDF or EMF). Raster (TIFF/PNG) at 600 dpi
is acceptable only when vector is not possible (e.g., heatmaps with rasterized colors).

| Format | Use case |
|---|---|
| PDF | Primary vector format (LaTeX inclusion) |
| EMF | Word/PowerPoint inclusion (editable text) |
| TIFF | Raster fallback (600 dpi, LZW compression) |
| PNG | Quick preview only (not for publication) |
| SVG | Web/HTML inclusion |

Export helper (MATLAB):
```matlab
function save_ieee(fig, filename, width_in, height_in)
    if nargin < 3, width_in = 3.5; end
    if nargin < 4, height_in = 2.6; end
    fig.Units = 'inches';
    fig.Position(3:4) = [width_in, height_in];
    exportgraphics(fig, [filename '.pdf'], 'ContentType', 'vector', 'Resolution', 600);
    exportgraphics(fig, [filename '.emf']);
    fprintf('Saved: %s.pdf + %s.emf (%.1f x %.1f in)\n', filename, filename, width_in, height_in);
end
```
