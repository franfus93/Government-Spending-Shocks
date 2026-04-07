function irf_plot_single(n, var_idx, hor, MiddleIRF, HighIRF, LowIRF, ...
                          title_surp, title_news, colorBNDS)
% IRF_PLOT_SINGLE  Side-by-side IRF panels for ONE variable, TWO shocks.
%
%  Used for inequality robustness checks (Appendix D.2 and D.3).
%
%  INPUTS
%   n          – total number of variables in the VAR
%   var_idx    – index of the variable to plot (e.g. 10 for last variable)
%   hor        – IRF horizon
%   MiddleIRF  – (hor × n²) posterior median IRFs
%   HighIRF    – (hor × n²) upper 68% band
%   LowIRF     – (hor × n²) lower 68% band
%   title_surp – title string for the surprise-shock panel
%   title_news – title string for the news-shock panel
%   colorBNDS  – fill colour (RGB, e.g. [0 0 1])
%
%  Column convention: col = shock_index + n*(variable_index - 1)
%   shock 1 = surprise (unanticipated)
%   shock 2 = news     (anticipated)

k = var_idx;
col_surp = 1 + n*(k-1);   % shock 1, variable k
col_news = 2 + n*(k-1);   % shock 2, variable k

h = 0:hor-1;

figure('Units', 'normalized', 'Position', [0.1 0.2 0.8 0.4]);

% ── Left panel: surprise shock ────────────────────────────────────────────
subplot(1, 2, 1);
fill([h, fliplr(h)], [HighIRF(:,col_surp)', flipud(LowIRF(:,col_surp))'], ...
     colorBNDS, 'EdgeColor', 'k');
alpha(0.20); hold on;
plot(h, MiddleIRF(:,col_surp), 'k-.', 'LineWidth', 1.5);
yline(0, 'r-', 'LineWidth', 1);
xlim([0 hor-1]);
set(gca, 'FontSize', 22, 'FontName', 'Times');
axis tight;
ytickformat('%.2f');
title(title_surp, 'FontSize', 20, 'FontName', 'Times');
hold off;

% ── Right panel: news shock ───────────────────────────────────────────────
subplot(1, 2, 2);
fill([h, fliplr(h)], [HighIRF(:,col_news)', flipud(LowIRF(:,col_news))'], ...
     colorBNDS, 'EdgeColor', 'k');
alpha(0.20); hold on;
plot(h, MiddleIRF(:,col_news), 'k-.', 'LineWidth', 1.5);
yline(0, 'r-', 'LineWidth', 1);
xlim([0 hor-1]);
set(gca, 'FontSize', 22, 'FontName', 'Times');
axis tight;
ytickformat('%.2f');
title(title_news, 'FontSize', 20, 'FontName', 'Times');
hold off;

end
