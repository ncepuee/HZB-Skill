# IEEE Transactions Figure Style Guide

## Dimension requirements

| Layout | Width | Height (typical) | Use |
|---|---|---|---|
| Single column | 3.5 in (88 mm) | 2.4–3.0 in | One chart or simple panel |
| 1.5 column | 5.0 in (127 mm) | 3.5–4.0 in | Medium complexity |
| Double column | 7.16 in (182 mm) | 4.0–5.0 in | Multi-panel figures |

**Maximum height**: 9.5 in (241 mm) including caption space.

## Font requirements

- **Primary font**: Times New Roman (serif). This is mandatory for IEEE Transactions.
- **Minimum size at publication scale**: 6 pt (after reduction). In practice, use 8 pt
  minimum for tick labels.
- **Superscripts/subscripts**: Must be clearly distinguishable.
- **Greek letters**: Use proper Unicode or LaTeX rendering, not roman substitution.

## Line and marker specifications

| Element | Minimum width | Recommended |
|---|---|---|
| Data curves | 0.5 pt | 1.0–1.5 pt |
| Axis borders | 0.3 pt | 0.5–0.6 pt |
| Grid lines | 0.25 pt | 0.4 pt |
| Threshold/reference lines | 0.4 pt | 0.8 pt (dashed) |
| Data markers | 3 pt | 4–5 pt |
| Peak/annotation markers | 4 pt | 5 pt |

## Color requirements

- Must be distinguishable in grayscale (for print).
- Must be accessible to colorblind readers.
- Use ≤6 colors per figure.
- Avoid: pure red/green pairs, yellow on white, saturated blue text on white background.

## Export requirements

| Format | Resolution | Use case |
|---|---|---|
| PDF | Vector (native) | Primary: LaTeX `\includegraphics` |
| EPS | Vector (native) | Legacy LaTeX |
| EMF | Vector (native) | Word/PowerPoint (editable text) |
| TIFF | 600 dpi, LZW | When vector not possible |
| PNG | 300 dpi | Review/submission portal only |
| SVG | Vector | Web/HTML |

**Critical**: All text in exported figures must remain editable. Do not rasterize text
layers. In MATLAB, use `exportgraphics` with `'ContentType', 'vector'`.

## Common IEEE figure types (power systems)

| Figure type | Typical panels | Key elements |
|---|---|---|
| Bode plot | magnitude + phase | Dual Y-axes, log X, grid |
| Nyquist plot | polar or rectangular | Stability boundary |
| Pole-zero map | Re vs Im/2π | Stability boundary, mode labels |
| Parameter sweep | multi-curve or heatmap | Colorbar, contour lines |
| Waveform comparison | time-domain subplots | Legend, annotation |
| Bar chart (participation) | horizontal bars | Threshold line, labels |
| 3D surface | surf with colorbar | View angle, grid |
| Stability boundary | contourf + contour | Critical line (Re=0 or PM=0) |

## Checklist before submission

- [ ] Figure width matches target (3.5 / 5.0 / 7.16 in)
- [ ] All fonts are Times New Roman
- [ ] Tick labels ≥ 8 pt
- [ ] Axis labels ≥ 9 pt
- [ ] All text is editable (not rasterized)
- [ ] Colors are distinguishable in grayscale
- [ ] ≤6 colors per figure
- [ ] Line widths ≥ 0.5 pt
- [ ] Export at ≥ 300 dpi (600 preferred)
- [ ] PDF + EMF both exported
- [ ] Panel labels (a), (b), ... present and bold
- [ ] No background color (white only)
- [ ] Legend has border (Box on)
