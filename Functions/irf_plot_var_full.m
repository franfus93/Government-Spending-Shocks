function irf_plot_var_full(n, q, hor, MiddleIRF, HighIRF, LowIRF, ...
                           HighIRF_large, LowIRF_large, VARnames, colorBNDS)
% IRF_PLOT_VAR_FULL  Plot IRFs for all q variables to two shocks.
%
%  Creates TWO figures:
%    Figure 1 (first created)  – responses to SHOCK 1 = SURPRISE shock
%    Figure 2 (second created) – responses to SHOCK 2 = NEWS shock
%
%  Layout: subplot(4,3) – supports up to 12 variables (10 used here).
%
%  INPUTS
%   n           – total number of VAR variables (n × n IRF matrix)
%   q           – number of variables to display (≤ n)
%   hor         – IRF horizon
%   MiddleIRF   – (hor × n²) posterior median
%   HighIRF     – (hor × n²) upper 68% band
%   LowIRF      – (hor × n²) lower 68% band
%   HighIRF_large – (hor × n²) upper 90% band (currently unused)
%   LowIRF_large  – (hor × n²) lower 90% band (currently unused)
%   VARnames    – (q × 1) cell array of variable labels (LaTeX OK)
%   colorBNDS   – fill colour (1 × 3 RGB, e.g. [0 0 1])
%
%  Column convention: col = shock + n*(variable-1)
%    shock 1 = surprise (unanticipated)   → Figure 1
%    shock 2 = news     (anticipated)     → Figure 2

plot_indices = 1:q;   % plot all q variables

for shock = 1:2
    figure;
    for i = 1:q
        k   = plot_indices(i);
        col = shock + n*(k-1);

        subplot(4, 3, i);
        fill([0:hor-1, fliplr(0:hor-1)]', ...
             [HighIRF(:,col); flipud(LowIRF(:,col))], ...
             colorBNDS, 'EdgeColor', 'k');
        alpha(0.20); hold on;
        plot(0:hor-1, MiddleIRF(:,col), 'LineWidth', 1.5, 'Color', 'k', 'LineStyle', '-.');
        yline(0, 'r-', 'LineWidth', 1);
        hold off;

        axis tight;
        xlim([0 hor-1]);

        set(gca, 'FontSize', 14, 'FontName', 'Times');
        ytickformat('%.2f');
        xlabel(VARnames{k}, 'FontSize', 16, 'FontName', 'Times', 'Interpreter', 'latex');
    end
end

end
