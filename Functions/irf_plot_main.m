function irf_plot_main(n, plot_vars, hor, MiddleIRF, HighIRF, LowIRF, ...
                        HighIRF_large, LowIRF_large, VARnames, colorBNDS)
% IRF_PLOT_MAIN  2×3 IRF figure for a selected subset of variables.
%
%  Creates TWO figures:
%    Figure 1 (first created)  – responses to SHOCK 1 = SURPRISE shock
%    Figure 2 (second created) – responses to SHOCK 2 = NEWS shock
%
%  Layout: subplot(2,3) — up to 6 panels; last panel left blank if fewer
%  than 6 variables are supplied.
%
%  INPUTS
%   n           – total number of VAR variables (determines column index)
%   plot_vars   – vector of variable indices to display (e.g. [1 2 3 5 10])
%   hor         – IRF horizon
%   MiddleIRF   – (hor × n²) posterior median
%   HighIRF     – (hor × n²) upper 68% band
%   LowIRF      – (hor × n²) lower 68% band
%   HighIRF_large – (hor × n²) upper 90% band
%   LowIRF_large  – (hor × n²) lower 90% band
%   VARnames    – (length(plot_vars) × 1) cell of labels for plot_vars
%   colorBNDS   – fill colour (1×3 RGB)
%
%  Column convention: col = shock + n*(variable-1)
%    shock 1 = surprise   → Figure 1
%    shock 2 = news       → Figure 2

q = numel(plot_vars);

for shock = 1:2
    figure('Units','normalized','Position',[0.05 0.15 0.70 0.55]);
    for i = 1:q
        k   = plot_vars(i);
        col = shock + n*(k-1);

        subplot(2, 3, i);
        set(gca, 'FontSize', 10, 'FontName', 'Times');

        % 90% band (lighter)
        fill([0:hor-1, fliplr(0:hor-1)]', ...
             [HighIRF_large(:,col); flipud(LowIRF_large(:,col))], ...
             colorBNDS, 'EdgeColor', 'none');
        alpha(0.12); hold on;

        % 68% band (darker)
        fill([0:hor-1, fliplr(0:hor-1)]', ...
             [HighIRF(:,col); flipud(LowIRF(:,col))], ...
             colorBNDS, 'EdgeColor', 'k');
        alpha(0.25);

        % Median
        plot(0:hor-1, MiddleIRF(:,col), 'k-.', 'LineWidth', 2);
        line(get(gca,'xlim'), [0 0], 'Color', [1 0 0], 'LineStyle', '-', 'LineWidth', 1);
        xlim([0 hor-1]);
        axis tight;
        ytickformat('%.2f');
        xlabel(VARnames{i}, 'FontSize', 13, 'FontName', 'Times', 'Interpreter', 'latex');
        ax = gca;
        ax.XAxis.FontSize = 10;
        ax.YAxis.FontSize = 10;
        hold off;
    end
end

end
