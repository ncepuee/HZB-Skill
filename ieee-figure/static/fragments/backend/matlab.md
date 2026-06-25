# MATLAB Backend — IEEE Transactions Quick-Start

## Execution rule

When the user selects MATLAB, **all** figure generation, previewing, exporting, and
visual QA must use MATLAB. Do not fall back to Python/R for any visual output.

Check MATLAB availability early:
```matlab
matlab -batch "ver"   % or: which matlab
```
If MATLAB is unavailable, stop and report the blocker.

## Global defaults (run once at top of script)

```matlab
%% IEEE Transactions global figure defaults
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
set(0, 'DefaultAxesColorOrder', ...
    [0 0 0; 0.00 0.45 0.74; 0.85 0.33 0.10; 0.00 0.62 0.45; 0.50 0.15 0.50]);
```

## Paul Tol muted palette (IEEE-ready)

```matlab
% 6 distinguishable colors, safe for colorblind readers
IEEE_COLORS.black       = [0.00 0.00 0.00];
IEEE_COLORS.blue        = [0.00 0.45 0.74];
IEEE_COLORS.vermillion  = [0.85 0.33 0.10];
IEEE_COLORS.green       = [0.00 0.62 0.45];
IEEE_COLORS.purple      = [0.50 0.15 0.50];
IEEE_COLORS.grey        = [0.50 0.50 0.50];
IEEE_COLORS.lightgrey   = [0.85 0.85 0.85];

% Line styles for >3 curves (color + linestyle = 12+ combinations)
IEEE_LINES = {'-','--', '-.', ':'};
IEEE_MARKERS = {'o','s','d','^','v','<','>','p','h'};
```

## Optional slanCM palettes

When the third-party `slanCM` function is available on the MATLAB path, it may
be used as an alternative palette source. Prefer restrained categorical
palettes such as `Pastel1`, `Pastel2`, `Set2`, `Paired`, or `Dark2`, then verify
contrast at the final 90 mm figure width and in grayscale. Do not hard-code a
machine-specific `slanCM` directory into reusable plotting functions.

```matlab
N = 5;
if exist('slanCM','file') == 2
    colors = slanCM('Pastel2', N);
else
    colors = ieee_colors(N);
end
```

Use sequential or diverging `slanCM` maps only when the data semantics require
ordered magnitude or a meaningful center point. Avoid rainbow-like maps.

## Single-figure creation template

```matlab
%% Create IEEE-style figure
fig = figure('Color','w', 'Units','inches', ...
    'Position', [3 3 3.5 2.6]);  % single-column
ax = axes('Position', [0.13 0.14 0.82 0.78]);
hold(ax, 'on');

% --- Plot data ---
plot(ax, x, y1, '-', 'Color', IEEE_COLORS.black, 'LineWidth', 1.2);
plot(ax, x, y2, '--', 'Color', IEEE_COLORS.blue, 'LineWidth', 1.0);
plot(ax, x, y3, '-.', 'Color', IEEE_COLORS.vermillion, 'LineWidth', 1.0);

% --- Axes ---
set(ax, 'FontName', 'Times New Roman', 'FontSize', 8);
set(ax, 'LineWidth', 0.6, 'Box', 'on');
set(ax, 'TickDir', 'in', 'TickLength', [0.015 0.015]);
xlabel(ax, 'Time (s)', 'FontSize', 9);
ylabel(ax, 'Voltage (p.u.)', 'FontSize', 9);
legend(ax, {'Case A','Case B','Case C'}, 'Location', 'northeast', ...
    'FontSize', 8, 'Box', 'on', 'FontName', 'Times New Roman');

% --- Panel label ---
text(ax, 0.01, 0.99, '(a)', 'Units', 'normalized', ...
    'FontSize', 10, 'FontWeight', 'bold', 'VerticalAlignment', 'top');

% --- Export ---
save_ieee(fig, 'Fig1a_Voltage');
```

## Multi-panel figure template

```matlab
fig = figure('Color','w', 'Units','inches', 'Position', [2 2 7.16 4.5]); % double-column

% Panel (a)
ax1 = subplot(2,2,1);
hold(ax1, 'on');
% ... plot ...
text(ax1, 0.02, 0.97, '(a)', 'Units','normalized', 'FontSize',10, ...
    'FontWeight','bold', 'VerticalAlignment','top');

% Panel (b) - same pattern
ax2 = subplot(2,2,2);
% ...

% Adjust spacing
set([ax1 ax2 ax3 ax4], 'FontName','Times New Roman', 'FontSize',8, ...
    'LineWidth',0.6, 'Box','on', 'TickDir','in');

save_ieee(fig, 'Fig2_FourPanels');
```

## Semilog / log-log template

```matlab
fig = figure('Color','w', 'Units','inches', 'Position', [3 3 3.5 2.6]);
ax = axes('Position', [0.13 0.14 0.82 0.78]);
hold(ax, 'on');

semilogx(ax, freq, mag, '-', 'Color', IEEE_COLORS.black, 'LineWidth', 1.2);

set(ax, 'XScale', 'log', 'XLim', [1 1e4]);
set(ax, 'XTick', [1 1e1 1e2 1e3 1e4]);
set(ax, 'FontName', 'Times New Roman', 'FontSize', 8);
set(ax, 'LineWidth', 0.6, 'Box', 'on', 'TickDir', 'in');
xlabel(ax, 'Frequency (Hz)', 'FontSize', 9);
ylabel(ax, 'Magnitude (dB)', 'FontSize', 9);

% Y-grid only (subtle)
ax.YGrid = 'on'; ax.XGrid = 'off';
ax.GridColor = IEEE_COLORS.lightgrey;
ax.GridAlpha = 0.5;

save_ieee(fig, 'Fig3_Bode');
```

## Heatmap / colorbar template

```matlab
fig = figure('Color','w', 'Units','inches', 'Position', [3 3 4.5 3.5]);
imagesc(x_range, y_range, data_matrix);
set(gca, 'YDir', 'normal', 'FontName', 'Times New Roman', 'FontSize', 8);
colormap(parula);  % NOT jet
cb = colorbar;
cb.FontName = 'Times New Roman';
cb.FontSize = 8;
xlabel('Parameter X', 'FontSize', 9);
ylabel('Parameter Y', 'FontSize', 9);
save_ieee(fig, 'Fig4_Heatmap');
```

## Contour / stability boundary template

```matlab
fig = figure('Color','w', 'Units','inches', 'Position', [3 3 3.5 3.0]);
ax = axes; hold(ax, 'on');
contourf(X, Y, Z, 20, 'LineStyle', 'none');
colormap(parula);
contour(X, Y, Z, [0 0], 'r-', 'LineWidth', 2);  % stability boundary
cb = colorbar; cb.FontName = 'Times New Roman'; cb.FontSize = 8;
set(ax, 'FontName', 'Times New Roman', 'FontSize', 8, 'LineWidth', 0.6, 'Box', 'on', 'TickDir', 'in');
xlabel('X', 'FontSize', 9); ylabel('Y', 'FontSize', 9);
save_ieee(fig, 'Fig5_Contour');
```

## Polar / compass template

```matlab
fig = figure('Color','w', 'Units','inches', 'Position', [3 3 3.5 3.5]);
ax = polaraxes; hold(ax, 'on');
for k = 1:N
    polarplot(ax, angle(z(k)), abs(z(k)), 'o', 'Color', colors(k,:), ...
        'MarkerFaceColor', colors(k,:), 'MarkerSize', 5);
end
ax.FontName = 'Times New Roman';
ax.FontSize = 8;
ax.ThetaTickLabel = {'0','30','60','90','120','150','180','210','240','270','300','330'};
save_ieee(fig, 'Fig6_Polar');
```

## Visio-editable bar chart template

For MATLAB figures intended to be pasted into Visio and ungrouped, draw bars
with individual `rectangle` objects instead of `bar`/`barh`. Use a 90 mm figure
width, `painters`, `grid off`, and a light-grey thin edge.

```matlab
fig = figure('Color','w','Units','centimeters', ...
    'Position',[3 3 9 7], 'Renderer','painters');
ax = axes; hold(ax, 'on');

width = 0.7;
for k = 1:numel(values)
    value = values(k);
    rectangle(ax,'Position',[k-width/2,min(0,value),width,abs(value)], ...
        'FaceColor',colors(k,:), ...
        'EdgeColor',[0.78 0.78 0.78], ...
        'LineWidth',0.3);
end

set(ax,'XLim',[0.5 numel(values)+0.5], ...
    'XTick',1:numel(values),'XTickLabel',labels, ...
    'FontName','Times New Roman','FontSize',8, ...
    'LineWidth',0.6,'Box','on','TickDir','in');
yline(ax,0,'-','Color',[0.5 0.5 0.5],'LineWidth',0.5);
grid(ax,'off');
```

For horizontal ranked bars, use
`Position=[min(0,value), k-height/2, abs(value), height]`.
Prefer `copygraphics(gcf,'ContentType','vector')` for clipboard transfer to Visio.

## 3D surface template

```matlab
fig = figure('Color','w', 'Units','inches', 'Position', [3 3 4.5 3.5]);
ax = axes; hold(ax, 'on');
surf(X, Y, Z, 'EdgeColor', 'none', 'FaceAlpha', 0.85);
shading interp; colormap(parula);
cb = colorbar; cb.FontName = 'Times New Roman'; cb.FontSize = 8;
view([-35 30]); grid on;
set(ax, 'FontName', 'Times New Roman', 'FontSize', 8, 'LineWidth', 0.6);
xlabel('X', 'FontSize', 9); ylabel('Y', 'FontSize', 9); zlabel('Z', 'FontSize', 9);
save_ieee(fig, 'Fig8_Surface');
```

## Pole-zero map template

```matlab
fig = figure('Color','w', 'Units','inches', 'Position', [3 3 3.5 2.6]);
ax = axes; hold(ax, 'on');

plot(ax, real(poles), imag(poles)/(2*pi), 'o', 'Color', IEEE_COLORS.black, ...
    'MarkerFaceColor', IEEE_COLORS.blue, 'MarkerSize', 5, 'LineWidth', 0.8);
xline(ax, 0, '--', 'Color', IEEE_COLORS.grey, 'LineWidth', 0.5, 'HandleVisibility', 'off');

set(ax, 'FontName', 'Times New Roman', 'FontSize', 8, 'LineWidth', 0.6, 'Box', 'on', 'TickDir', 'in');
xlabel(ax, 'Real (\sigma)', 'FontSize', 9);
ylabel(ax, 'Imaginary / 2\pi (Hz)', 'FontSize', 9);

% Stability boundary patch
yl = ylim; patch(ax, [0 0 0 0], [yl(1) yl(2) yl(2) yl(1)], ...
    'r', 'FaceAlpha', 0.05, 'EdgeColor', 'none', 'HandleVisibility', 'off');
save_ieee(fig, 'Fig9_Poles');
```

## Two-eigenvalue Nyquist figures

For a 2×2 return-ratio matrix, use the dedicated recipe in
`references/chart-types.md`. It fixes the two axes at identical physical sizes,
uses `painters` for Visio-editable output, excludes reference objects from
legends, and places `Eigen1/Eigen2` inside the axes instead of above them.

## Helper: adaptive color generation for N items

```matlab
function colors = ieee_colors(N)
% Generate N distinguishable IEEE-safe colors
    base = [0 0 0; 0.00 0.45 0.74; 0.85 0.33 0.10; 0.00 0.62 0.45; 0.50 0.15 0.50; 0.55 0.34 0.16];
    if N <= size(base,1)
        colors = base(1:N, :);
    else
        cmap = parula(N);
        colors = cmap(round(linspace(1, size(cmap,1), N)), :);
    end
end
```

## Helper: export function

```matlab
function save_ieee(fig, filename, width_in, height_in)
%SAVE_IEEE Export figure in IEEE Transactions format
%   save_ieee(fig, 'Fig1a')           -> single-column (3.5 x 2.6 in)
%   save_ieee(fig, 'Fig1a', 7.16)    -> double-column width
    if nargin < 3, width_in = 3.5; end
    if nargin < 4, height_in = 2.6; end
    fig.Units = 'inches';
    fig.Position(3:4) = [width_in, height_in];
    drawnow;
    exportgraphics(fig, [filename '.pdf'], 'ContentType', 'vector', 'Resolution', 600);
    try
        exportgraphics(fig, [filename '.emf']);
        fmt_str = 'PDF + EMF';
    catch
        fmt_str = 'PDF';
    end
    fprintf('IEEE export: %s (%s, %.1f x %.1f in)\n', filename, fmt_str, width_in, height_in);
end
```
