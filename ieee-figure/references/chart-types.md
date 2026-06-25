# IEEE Chart Types — Power Systems / Power Electronics

MATLAB-native recipes for common IEEE PES/PEL figure types.

## 1. Bode plot (impedance / transfer function)

```matlab
fig = figure('Color','w','Units','inches','Position',[3 3 3.5 4.0]);

% Magnitude
ax1 = subplot(2,1,1);
semilogx(ax1, freq, mag, '-', 'Color', IEEE_COLORS.black, 'LineWidth', 1.2); hold on;
set(ax1, 'FontName','Times New Roman','FontSize',8,'LineWidth',0.6,'Box','on','TickDir','in');
ylabel(ax1, 'Magnitude (dB)', 'FontSize', 9);
ax1.YGrid = 'on'; ax1.GridColor = IEEE_COLORS.lightgrey; ax1.GridAlpha = 0.5;

% Phase
ax2 = subplot(2,1,2);
semilogx(ax2, freq, phase, '-', 'Color', IEEE_COLORS.black, 'LineWidth', 1.2); hold on;
set(ax2, 'FontName','Times New Roman','FontSize',8,'LineWidth',0.6,'Box','on','TickDir','in');
xlabel(ax2, 'Frequency (Hz)', 'FontSize', 9);
ylabel(ax2, 'Phase (deg)', 'FontSize', 9);
ax2.YGrid = 'on'; ax2.GridColor = IEEE_COLORS.lightgrey; ax2.GridAlpha = 0.5;

save_ieee(fig, 'Fig_Bode', 3.5, 4.0);
```

## 2. Impedance ratio (IR) with stability margin

```matlab
fig = figure('Color','w','Units','inches','Position',[3 3 3.5 2.6]);
ax = axes('Position',[0.13 0.14 0.82 0.78]); hold(ax,'on');

% IR curve
plot(ax, freq, 20*log10(abs(IR)), '-', 'Color', IEEE_COLORS.black, 'LineWidth', 1.2);

% 0 dB line (stability boundary)
yline(ax, 0, '--', 'Color', IEEE_COLORS.red, 'LineWidth', 0.8);

% Gain margin annotation
[gm_val, gm_idx] = min(20*log10(abs(IR)));
plot(ax, freq(gm_idx), gm_val, 'v', 'Color', IEEE_COLORS.vermillion, ...
    'MarkerFaceColor', IEEE_COLORS.vermillion, 'MarkerSize', 5);
text(ax, freq(gm_idx)*1.5, gm_val+3, sprintf('GM = %.1f dB', -gm_val), ...
    'Color', IEEE_COLORS.vermillion, 'FontSize', 8, 'FontName', 'Times New Roman');

set(ax, 'XScale','log','FontName','Times New Roman','FontSize',8,'LineWidth',0.6,'Box','on','TickDir','in');
xlabel(ax, 'Frequency (Hz)', 'FontSize', 9);
ylabel(ax, 'Magnitude (dB)', 'FontSize', 9);
save_ieee(fig, 'Fig_IR');
```

## 3. Pole map with frequency coloring

```matlab
fig = figure('Color','w','Units','inches','Position',[3 3 3.5 2.6]);
ax = axes('Position',[0.13 0.14 0.82 0.78]); hold(ax,'on');

freq_hz = imag(poles)/(2*pi);
scatter(ax, real(poles), freq_hz, 30, freq_hz, 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 0.3);
colormap(ax, parula);
cb = colorbar(ax); cb.Label.String = 'Frequency (Hz)'; cb.FontName = 'Times New Roman'; cb.FontSize = 8;

xline(ax, 0, '--', 'Color', IEEE_COLORS.grey, 'LineWidth', 0.5);
set(ax, 'FontName','Times New Roman','FontSize',8,'LineWidth',0.6,'Box','on','TickDir','in');
xlabel(ax, 'Real (\sigma)', 'FontSize', 9);
ylabel(ax, 'Imaginary / 2\pi (Hz)', 'FontSize', 9);
save_ieee(fig, 'Fig_Poles');
```

## 4. Stability boundary heatmap

```matlab
fig = figure('Color','w','Units','inches','Position',[3 3 4.5 3.5]);
ax = axes; hold(ax,'on');

contourf(ax, X, Y, Z, 20, 'LineStyle', 'none');
colormap(ax, parula);
contour(ax, X, Y, Z, [0 0], '-', 'Color', IEEE_COLORS.vermillion, 'LineWidth', 2);

cb = colorbar(ax); cb.FontName = 'Times New Roman'; cb.FontSize = 8;
set(ax, 'FontName','Times New Roman','FontSize',8,'LineWidth',0.6,'Box','on','TickDir','in');
xlabel(ax, 'X', 'FontSize', 9);
ylabel(ax, 'Y', 'FontSize', 9);
save_ieee(fig, 'Fig_StabilityMap', 4.5, 3.5);
```

## 5. Participation factor bar chart

```matlab
fig = figure('Color','w','Units','centimeters', ...
    'Position',[3 3 9 7], 'Renderer','painters');
ax = axes; hold(ax,'on');

height = 0.62;
for k = 1:numel(data)
    value = data(k);
    color = IEEE_COLORS.blue;
    if value > 0, color = IEEE_COLORS.vermillion; end
    rectangle(ax,'Position', ...
        [min(0,value),k-height/2,abs(value),height], ...
        'FaceColor',color, ...
        'EdgeColor',[0.78 0.78 0.78], ...
        'LineWidth',0.3);
end

xline(ax,0,'-','Color',[0.5 0.5 0.5],'LineWidth',0.5);
set(ax,'YLim',[0.5 numel(data)+0.5], ...
    'YTick',1:numel(data),'YTickLabel',labels, ...
    'FontName','Times New Roman','FontSize',8, ...
    'LineWidth',0.6,'Box','on','TickDir','in');
xlabel(ax, 'Participation Index', 'FontSize', 9);
grid(ax,'off');
```

Use this `rectangle` pattern for Visio-editable IEEE bars. It keeps each bar
as a separate vector object after clipboard paste and ungrouping. Keep the
figure width at 90 mm, avoid dark bar borders, and do not enable grids.

## 6. Compass / sensitivity plot

```matlab
fig = figure('Color','w','Units','inches','Position',[3 3 3.5 3.5]);
ax = polaraxes; hold(ax,'on');

for k = 1:length(vectors)
    polarplot(ax, angle(vectors(k)), abs(vectors(k)), 'o', ...
        'Color', colors(k,:), 'MarkerFaceColor', colors(k,:), 'MarkerSize', 5);
end

ax.FontName = 'Times New Roman';
ax.FontSize = 8;
ax.RColor = 'k'; ax.ThetaColor = 'k';
save_ieee(fig, 'Fig_Compass', 3.5, 3.5);
```

## 7. 3D surface (eigenvalue vs parameters)

```matlab
fig = figure('Color','w','Units','inches','Position',[3 3 4.5 3.5]);
ax = axes; hold(ax,'on');

surf(ax, X, Y, Z, 'EdgeColor','none', 'FaceAlpha', 0.85);
shading(ax, 'interp'); colormap(ax, parula);

% Stability boundary plane
hold on;
mesh(ax, X(1,:), Y(:,1), zeros(size(Z)), 'FaceColor','none', ...
    'EdgeColor', IEEE_COLORS.grey, 'EdgeAlpha', 0.3, 'LineStyle', '--');
% Contour on plane
contour3(ax, X, Y, Z, [0 0], 'r-', 'LineWidth', 2);

cb = colorbar(ax); cb.FontName = 'Times New Roman'; cb.FontSize = 8;
view(ax, [-35 30]); grid(ax, 'on');
set(ax, 'FontName','Times New Roman','FontSize',8,'LineWidth',0.6);
xlabel(ax, 'X', 'FontSize', 9); ylabel(ax, 'Y', 'FontSize', 9); zlabel(ax, 'Z', 'FontSize', 9);
save_ieee(fig, 'Fig_3D', 4.5, 3.5);
```

## 8. Two-eigenvalue Nyquist plot for a 2×2 return-ratio matrix

Use this compact style for two continuously sorted eigenvalues. It is tuned for
MATLAB-to-Visio vector editing.

```matlab
function plot_eigen_nyquist_pair(fig_num,eig_curves,figure_name,colors,fixed_limit)
% eig_curves: 2×N complex matrix, one continuously sorted mode per row.
% fixed_limit: [] for per-mode autoscale, or 2 for x/y limits [-2,2].

figure(fig_num); clf;
fig=gcf;
set(fig,'Name',sprintf('Figure %d - %s',fig_num,figure_name), ...
    'NumberTitle','off','Color','w','Units','centimeters', ...
    'Position',[5,5,8,4],'PaperPositionMode','auto', ...
    'InvertHardcopy','off','Renderer','painters');

positions={[0.08,0.10,0.40,0.90],[0.58,0.10,0.40,0.90]};
t=linspace(0,2*pi,1000);

for mode=1:2
    ax=axes('Parent',fig,'Position',positions{mode});
    hold(ax,'on');
    curve=eig_curves(mode,:);
    plot(ax,real(curve),imag(curve),'-', ...
        'Color',colors(mode,:),'LineWidth',0.85);

    if isempty(fixed_limit)
        finite_curve=curve(isfinite(curve));
        lim=max([1.2;abs(real(finite_curve(:)));abs(imag(finite_curve(:)))])*1.05;
    else
        lim=fixed_limit;
    end
    xlim(ax,[-lim lim]); ylim(ax,[-lim lim]);

    plot(ax,cos(t),sin(t),'r-','LineWidth',0.5,'HandleVisibility','off');
    plot(ax,[0 0],ylim(ax),'-.','Color',[0.5 0.5 0.5], ...
        'LineWidth',0.5,'HandleVisibility','off');
    plot(ax,xlim(ax),[0 0],'-.','Color',[0.5 0.5 0.5], ...
        'LineWidth',0.5,'HandleVisibility','off');
    line(ax,[-1 -1],ylim(ax),'LineStyle','-.','Color',[0.5 0.5 0.5], ...
        'LineWidth',0.5,'HandleVisibility','off');

    text(ax,0.05,0.08,sprintf('Eigen%d',mode), ...
        'Units','normalized','FontName','Times New Roman','FontSize',7, ...
        'Color',colors(mode,:),'HorizontalAlignment','left');
    xlabel(ax,'Real','FontName','Times New Roman','FontSize',7);
    ylabel(ax,'Imag','FontName','Times New Roman','FontSize',7);
    set(ax,'DataAspectRatio',[1 1 1],'FontName','Times New Roman', ...
        'FontSize',7,'LineWidth',0.5,'Box','on','TickDir','in');
end
end
```

- Do not label return-ratio Nyquist axes with `s^{-1}`; use `Real` and `Imag`.
- Keep identification in the figure window `Name`; do not add `title` or `sgtitle`.
- Use `fixed_limit=2` when the unit-circle and `(-1,j0)` neighborhood are the evidence.
- Keep reference lines out of legends with `HandleVisibility='off'`.
- Use `copygraphics(gcf,'ContentType','vector')` or EMF/PDF for Visio editing.
