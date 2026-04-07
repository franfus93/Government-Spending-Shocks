function [median_surprise_shock, median_news_shock] = get_shocks(vardata, eta, p, start_year)
% GET_SHOCKS  Extract and plot median structural shocks from BVAR draws.
%
%  Shock 1 (eta column 1) = SURPRISE (unanticipated) govt spending shock
%  Shock 2 (eta column 2) = NEWS     (anticipated)   govt spending shock
%
%  INPUTS:
%   vardata    – (T × n) raw data matrix
%   eta        – (T-p × n × drawfin) structural shocks from BVAR
%   p          – number of VAR lags
%   start_year – decimal year of first observation after p lags
%                (e.g. 1982.75 for 1982:Q4)
%
%  OUTPUTS:
%   median_surprise_shock  – (T-p × 1) median unanticipated shock
%   median_news_shock      – (T-p × 1) median anticipated shock

Tp = size(vardata, 1) - p;   % effective sample size

median_surprise_shock = zeros(Tp, 1);
median_news_shock     = zeros(Tp, 1);

for i = 1:Tp
    median_surprise_shock(i) = prctile(eta(i, 1, :), 50);   % shock 1 = surprise
    median_news_shock(i)     = prctile(eta(i, 2, :), 50);   % shock 2 = news
end

% Time axis: quarterly, starting from start_year
h = (start_year : 0.25 : start_year + (Tp-1)*0.25)';

% ── Figure: Surprise shock ────────────────────────────────────────────────
figure;
plot(h, median_surprise_shock, 'k', 'LineWidth', 1.2);
title('Unanticipated (surprise) government spending shock', 'Interpreter', 'none');
set(gca, 'FontSize', 18);
axis tight;
yline(0, 'r--');

% ── Figure: News shock ────────────────────────────────────────────────────
figure;
plot(h, median_news_shock, 'k', 'LineWidth', 1.2);
title('Anticipated (news) government spending shock', 'Interpreter', 'none');
set(gca, 'FontSize', 18);
axis tight;
yline(0, 'r--');

end
