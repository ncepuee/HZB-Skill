# Figure Contract

Before generating any code, establish this contract.

## 1. Core conclusion

Write the one-sentence claim the figure must defend. If the user does not state one,
infer it from the analysis context and confirm.

## 2. Evidence chain

Map each planned panel to the claim. Drop panels that do not carry a unique piece of
evidence. One hero panel is better than four equal subplots.

## 3. Archetype

Classify the figure:

| Archetype | When to use |
|---|---|
| `quantitative grid` | Multiple panels of the same chart type (e.g., 2×2 Bode plots) |
| `schematic-led composite` | Block diagram + quantitative panels |
| `image plate + quant` | Simulink screenshot / waveform + analysis panels |
| `asymmetric hero` | One large panel (60%+ canvas) + small supporting panels |

## 4. Journal/export contract

| Property | IEEE default |
|---|---|
| Single-column width | 3.5 in (88 mm) |
| Double-column width | 7.16 in (182 mm) |
| Font | Times New Roman |
| Min font size (print) | 8 pt |
| Axis label size | 9 pt |
| Tick label size | 8 pt |
| Title size | 10 pt |
| Line width (data) | 1.0–1.5 pt |
| Line width (axes) | 0.5–0.6 pt |
| Resolution | ≥ 300 dpi |
| Formats | PDF (vector), EMF (editable), TIFF (raster) |
| Text | Must be editable (not rasterized) |
| Background | White |
| Axis border | Bordered (Box on) |
| Tick direction | Inward |

## 5. Review-risk check

- Does the figure survive 50% size reduction and still be legible?
- Can a reader extract the core conclusion from the figure alone (without caption)?
- Are all axis labels, units, and legends present?
- Is color accessibility considered (avoid red-green only encoding)?
