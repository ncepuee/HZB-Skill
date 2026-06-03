# R Backend — IEEE Transactions Quick-Start

## Execution rule

All figure generation, previewing, exporting, and visual QA must use R.
Do not call MATLAB or Python for any visual output.

## Global theme

```r
library(ggplot2)
library(patchwork)

theme_set(
  theme_classic(base_size = 8, base_family = "Times New Roman") +
    theme(
      axis.line = element_line(linewidth = 0.35, colour = "black"),
      axis.ticks = element_line(linewidth = 0.35, colour = "black"),
      axis.ticks.length = unit(0.15, "cm"),
      axis.text = element_text(size = 8, family = "Times New Roman"),
      axis.title = element_text(size = 9, family = "Times New Roman"),
      legend.title = element_text(size = 8),
      legend.text = element_text(size = 7.5),
      strip.text = element_text(size = 8, face = "bold"),
      plot.title = element_text(size = 10, face = "bold"),
      panel.grid = element_blank(),
      legend.background = element_rect(fill = "white", color = "black", linewidth = 0.3),
      legend.key.size = unit(0.5, "cm")
    )
)

# IEEE Paul Tol muted palette
ieee_colors <- c(
  black      = "#000000",
  blue       = "#0072B2",
  vermillion = "#D55E00",
  green      = "#009E73",
  purple     = "#882255",
  grey       = "#808080"
)
```

## Export helper

```r
save_ieee <- function(plot, filename, width_in = 3.5, height_in = 2.6, dpi = 600) {
  ggsave(paste0(filename, ".pdf"), plot, width = width_in, height = height_in, dpi = dpi)
  ggsave(paste0(filename, ".svg"), plot, width = width_in, height = height_in)
  ggsave(paste0(filename, ".tiff"), plot, width = width_in, height = height_in, dpi = dpi,
         compression = "lzw")
  cat(sprintf("IEEE export: %s (%.1f x %.1f in, %d dpi)\n", filename, width_in, height_in, dpi))
}
```
