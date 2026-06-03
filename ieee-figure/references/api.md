# IEEE Figure API — Helper Functions and Palettes

## MATLAB palette module

Save as `ieee_palette.m` in your project:

```matlab
function c = ieee_palette(name)
%IEEE_PALETTE Return IEEE-safe color by name
%   c = ieee_palette('blue')     -> [0.00 0.45 0.74]
%   c = ieee_palette('vermillion') -> [0.85 0.33 0.10]
    persistent map
    if isempty(map)
        map = containers.Map();
        map('black')      = [0.00 0.00 0.00];
        map('blue')       = [0.00 0.45 0.74];
        map('vermillion') = [0.85 0.33 0.10];
        map('green')      = [0.00 0.62 0.45];
        map('purple')     = [0.50 0.15 0.50];
        map('grey')       = [0.50 0.50 0.50];
        map('lightgrey')  = [0.85 0.85 0.85];
        map('red')        = [0.80 0.00 0.00];
    end
    c = map(lower(name));
end
```

## MATLAB IEEE default setter

```matlab
function set_ieee_defaults()
%SET_IEEE_DEFAULTS Apply IEEE Transactions figure defaults globally
    set(0, 'DefaultAxesFontName', 'Times New Roman');
    set(0, 'DefaultTextFontName', 'Times New Roman');
    set(0, 'DefaultAxesFontSize', 8);
    set(0, 'DefaultTextFontSize', 8);
    set(0, 'DefaultAxesLineWidth', 0.6);
    set(0, 'DefaultLineLineWidth', 1.2);
    set(0, 'DefaultAxesBox', 'on');
    set(0, 'DefaultAxesTickDir', 'in');
    set(0, 'DefaultAxesTickLength', [0.015 0.015]);
    set(0, 'DefaultFigureColor', 'w');
    set(0, 'DefaultAxesColorOrder', [0 0 0; 0 0.45 0.74; 0.85 0.33 0.10; 0 0.62 0.45; 0.5 0.15 0.5]);
end
```

## MATLAB export helper

```matlab
function save_ieee(fig, filename, width_in, height_in)
%SAVE_IEEE Export figure in IEEE Transactions format
%   save_ieee(fig, 'Fig1a')           -> single-column (3.5 x 2.6 in)
%   save_ieee(fig, 'Fig1a', 7.16)    -> double-column width
%   save_ieee(fig, 'Fig1a', 7.16, 4.5) -> custom size
    if nargin < 3, width_in = 3.5; end
    if nargin < 4, height_in = 2.6; end
    fig.Units = 'inches';
    fig.Position(3:4) = [width_in, height_in];
    drawnow;
    exportgraphics(fig, [filename '.pdf'], 'ContentType', 'vector', 'Resolution', 600);
    try
        exportgraphics(fig, [filename '.emf']);
        fmt = 'PDF + EMF';
    catch
        fmt = 'PDF';
    end
    fprintf('IEEE export: %s (%s, %.1f x %.1f in)\n', filename, fmt, width_in, height_in);
end
```

## MATLAB N-color generator

```matlab
function colors = ieee_colors(N)
%IEEE_COLORS Generate N IEEE-safe distinguishable colors
%   colors = ieee_colors(4)  -> 4x3 matrix of RGB values
    base = [0 0 0; 0 0.45 0.74; 0.85 0.33 0.10; 0 0.62 0.45; 0.5 0.15 0.5; 0.55 0.34 0.16];
    if N <= size(base,1)
        colors = base(1:N, :);
    else
        cmap = parula(N + 4);
        colors = cmap(round(linspace(3, size(cmap,1)-2, N)), :);
    end
end
```

## MATLAB axes helper

```matlab
function ax = ieee_axes(fig, pos)
%IEEE_AXES Create axes with IEEE defaults
%   ax = ieee_axes(fig)           -> default position [0.13 0.14 0.82 0.78]
%   ax = ieee_axes(fig, [l b w h]) -> custom position
    if nargin < 2, pos = [0.13 0.14 0.82 0.78]; end
    ax = axes(fig, 'Position', pos);
    set(ax, 'FontName', 'Times New Roman', 'FontSize', 8, ...
        'LineWidth', 0.6, 'Box', 'on', 'TickDir', 'in', 'TickLength', [0.015 0.015]);
    hold(ax, 'on');
end
```

## Python palette

```python
IEEE_COLORS = {
    "black":      "#000000",
    "blue":       "#0072B2",
    "vermillion": "#D55E00",
    "green":      "#009E73",
    "purple":     "#882255",
    "grey":       "#808080",
    "lightgrey":  "#D9D9D9",
    "red":        "#CC0000",
}
```
