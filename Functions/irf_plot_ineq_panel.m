function irf_plot_ineq_panel(n_gi, MidD_Gi, HighD_Gi, LowD_Gi, ...
                              n_90, MidD_90, HighD_90, LowD_90, ...
                              hor, colorBNDS)
% IRF_PLOT_INEQ_PANEL  2×2 panel for alternative inequality-measure IRFs.
%
%  Layout:
%    (1,1) Gini      – Surprise shock    (1,2) 90-10 range – Surprise shock
%    (2,1) Gini      – News shock        (2,2) 90-10 range – News shock
%
%  INPUTS
%   n_gi        – total VAR size for the Gini system
%   MidD_Gi     – (hor × n²) posterior median, Gini VAR
%   HighD_Gi    – (hor × n²) upper 68% band,   Gini VAR
%   LowD_Gi     – (hor × n²) lower 68% band,   Gini VAR
%   n_90        – total VAR size for the 90-10 system
%   MidD_90     – (hor × n²) posterior median, 90-10 VAR
%   HighD_90    – (hor × n²) upper 68% band,   90-10 VAR
%   LowD_90     – (hor × n²) lower 68% band,   90-10 VAR
%   hor         – IRF horizon (number of quarters)
%   colorBNDS   – fill colour (1×3 RGB)
%
%  Inequality variable is always the last in each system (index n).
%  Column convention: col = shock + n*(variable-1)

% Column indices for the inequality variable (last variable in each VAR)
col_gi_surp = 1 + n_gi*(n_gi - 1);   % Gini,  surprise
col_gi_news = 2 + n_gi*(n_gi - 1);   % Gini,  news
col_90_surp = 1 + n_90*(n_90 - 1);   % 90-10, surprise
col_90_news = 2 + n_90*(n_90 - 1);   % 90-10, news

h = 0:hor-1;

configs = { col_gi_surp, MidD_Gi, HighD_Gi, LowD_Gi, 'Gini Coefficient',   'Surprise Shock'; ...
            col_90_surp, MidD_90, HighD_90, LowD_90, '90-10 Range',         'Surprise Shock'; ...
            col_gi_news, MidD_Gi, HighD_Gi, LowD_Gi, 'Gini Coefficient',    'News Shock'; ...
            col_90_news, MidD_90, HighD_90, LowD_90, '90-10 Range',         'News Shock' };

figure('Units', 'normalized', 'Position', [0.10 0.10 0.60 0.65]);

for p = 1:4
    col     = configs{p,1};
    Middle  = configs{p,2};
    High    = configs{p,3};
    Low     = configs{p,4};
    var_lbl = configs{p,5};
    shk_lbl = configs{p,6};

    subplot(2, 2, p);
    fill([h, fliplr(h)]', [High(:,col); flipud(Low(:,col))], ...
         colorBNDS, 'EdgeColor', 'k');
    alpha(0.20); hold on;
    plot(h, Middle(:,col), 'k-.', 'LineWidth', 2);
    yline(0, 'r-', 'LineWidth', 1);
    hold off;

    axis tight;
    xlim([0 hor-1]);

    set(gca, 'FontSize', 14, 'FontName', 'Times');
    ytickformat('%.2f');
    title([var_lbl, ' — ', shk_lbl], 'FontSize', 15, ...
          'FontName', 'Times', 'FontWeight', 'normal');
    xlabel('Quarters', 'FontSize', 14, 'FontName', 'Times');
end

end
