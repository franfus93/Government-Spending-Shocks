function irf_plot_var(n, q, hor, MiddleIRF, HighIRF, LowIRF, VARnames, colorBNDS)
% IRF_PLOT_VAR  Plot IRFs for q variables to two shocks.
%
%  Creates TWO figures:
%    Figure 1 (first created)  – responses to SHOCK 1 = SURPRISE shock
%    Figure 2 (second created) – responses to SHOCK 2 = NEWS shock
%
%  Layout: subplot(3,3) – supports up to 9 variables.
%  Used for the FAVAR specification (6 macro variables displayed).
%
%  INPUTS
%   n         – total number of VAR variables (including any latent factors)
%   q         – number of variables to display (≤ n, ≤ 9)
%   hor       – IRF horizon
%   MiddleIRF – (hor × n²) posterior median
%   HighIRF   – (hor × n²) upper 68% band
%   LowIRF    – (hor × n²) lower 68% band
%   VARnames  – (q × 1) cell array of variable labels
%   colorBNDS – fill colour (RGB, e.g. [0 0 1])
%
%  Column convention: col = shock + n*(variable-1)
%    shock 1 = surprise → Figure 1
%    shock 2 = news     → Figure 2

plot_indices = 1:q;

%% ── Figure 1: SURPRISE shock (shock 1) ──────────────────────────────────
figure;
for i = 1:q
    k = plot_indices(i);
    col = 1 + n*(k-1);   % shock 1, variable k

    subplot(3, 3, i);
    set(gca, 'FontSize', 8, 'FontName', 'Times');
    fill([0:hor-1, fliplr(0:hor-1)]', ...
         [HighIRF(:,col); flipud(LowIRF(:,col))], ...
         colorBNDS, 'EdgeColor', 'k');
    alpha(0.20); hold on;
    plot(0:hor-1, MiddleIRF(:,col), 'LineWidth', 1.5, 'Color', 'k', 'LineStyle', '-.');
    xlim([0 hor-1]);
    line(get(gca,'xlim'), [0 0], 'Color', [1 0 0], 'LineStyle', '-', 'LineWidth', 1);
    hold off;
    ax = gca;
    xlabel(ax, VARnames{k}, 'FontSize', 14, 'FontName', 'Times', 'Interpreter', 'latex');
    ax.XAxis.FontSize = 12;
    ax.YAxis.FontSize = 12;
    axis tight;
    ytickformat('%.2f');
end

%% ── Figure 2: NEWS shock (shock 2) ───────────────────────────────────────
figure;
for i = 1:q
    k = plot_indices(i);
    col = 2 + n*(k-1);   % shock 2, variable k

    subplot(3, 3, i);
    set(gca, 'FontSize', 8, 'FontName', 'Times');
    fill([0:hor-1, fliplr(0:hor-1)]', ...
         [HighIRF(:,col); flipud(LowIRF(:,col))], ...
         colorBNDS, 'EdgeColor', 'k');
    alpha(0.20); hold on;
    plot(0:hor-1, MiddleIRF(:,col), 'LineWidth', 1.5, 'Color', 'k', 'LineStyle', '-.');
    xlim([0 hor-1]);
    line(get(gca,'xlim'), [0 0], 'Color', [1 0 0], 'LineStyle', '-', 'LineWidth', 1);
    hold off;
    ax = gca;
    xlabel(ax, VARnames{k}, 'FontSize', 14, 'FontName', 'Times', 'Interpreter', 'latex');
    ax.XAxis.FontSize = 12;
    ax.YAxis.FontSize = 12;
    axis tight;
    ytickformat('%.2f');
end

end
