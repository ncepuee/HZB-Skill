# Design Theory — IEEE Figures

## Color theory for IEEE

### Why Paul Tol muted palette?

The Paul Tol muted palette was chosen because:
1. **Colorblind-safe**: All 6 colors are distinguishable by deuteranopia/protanopia readers
2. **Grayscale-safe**: When desaturated, all colors remain distinguishable by luminance
3. **Print-safe**: Works on both color and B&W printers
4. **Screen-safe**: High contrast on both LCD and OLED displays

### Luminance ordering

When using multiple colors, order by luminance (dark to light) for visual hierarchy:
1. Black `[0 0 0]` — primary data
2. Vermillion `[0.85 0.33 0.10]` — high emphasis
3. Blue `[0.00 0.45 0.74]` — medium emphasis
4. Green `[0.00 0.62 0.45]` — medium emphasis
5. Purple `[0.50 0.15 0.50]` — low emphasis
6. Grey `[0.50 0.50 0.50]` — reference/background

### Line style encoding

When >3 curves share one axes, use line style as secondary channel:

| Curve # | Color | Line style |
|---|---|---|
| 1 | Black | Solid `-` |
| 2 | Blue | Dashed `--` |
| 3 | Vermillion | Dash-dot `-.` |
| 4 | Green | Dotted `:` |
| 5+ | Remaining colors | Cycle styles |

## Typography rationale

IEEE requires Times New Roman because:
- Serif fonts improve readability in dense two-column layouts
- Mathematical symbols render correctly in serif context
- Consistency with IEEE LaTeX template (`\usepackage{times}`)

## White space policy

- **Between panels**: 0.05–0.08 of figure width
- **Axes margins**: 0.13 (left), 0.05 (right), 0.14 (bottom), 0.05 (top) of figure
- **No padding between figure edge and axes border** — the axes border IS the visual boundary
