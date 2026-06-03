# Python Backend — IEEE Transactions Quick-Start

## Execution rule

All figure generation, previewing, exporting, and visual QA must use Python.
Do not call MATLAB or R for any visual output.

## Global defaults

```python
import matplotlib as mpl
import matplotlib.pyplot as plt

mpl.rcParams.update({
    "font.family": "serif",
    "font.serif": ["Times New Roman", "Times", "DejaVu Serif", "serif"],
    "svg.fonttype": "none",     # editable text in SVG
    "pdf.fonttype": 42,         # editable TrueType text in PDF
    "font.size": 8,             # IEEE tick-label size
    "axes.labelsize": 9,        # IEEE axis-label size
    "axes.titlesize": 10,       # IEEE title size
    "axes.linewidth": 0.6,      # IEEE axis line width
    "axes.spines.right": True,  # IEEE: bordered axes
    "axes.spines.top": True,
    "axes.direction": "in",     # IEEE: inward ticks
    "xtick.direction": "in",
    "ytick.direction": "in",
    "xtick.major.size": 3,
    "ytick.major.size": 3,
    "legend.fontsize": 8,
    "legend.frameon": True,     # IEEE: legend with frame
    "figure.facecolor": "white",
    "axes.facecolor": "white",
})

# IEEE Paul Tol muted palette
IEEE_COLORS = {
    "black":      "#000000",
    "blue":       "#0072B2",
    "vermillion": "#D55E00",
    "green":      "#009E73",
    "purple":     "#882255",
    "grey":       "#808080",
    "lightgrey":  "#D9D9D9",
}
```

## Export helper

```python
def save_ieee(fig, filename, width_in=3.5, height_in=2.6, dpi=600):
    fig.set_size_inches(width_in, height_in)
    fig.tight_layout()
    fig.savefig(f"{filename}.pdf", dpi=dpi, bbox_inches="tight")
    fig.savefig(f"{filename}.svg", bbox_inches="tight")
    fig.savefig(f"{filename}.tiff", dpi=dpi, bbox_inches="tight")
    print(f"IEEE export: {filename} ({width_in} x {height_in} in, {dpi} dpi)")
```
