%% run_all.m  –  Generate ALL empirical results for DFT2026.pdf
%
%  Dhamija, Fusari & Tara (2026)
%  "Government Spending Shocks and Consumption Inequality"
%
%  RESULTS PRODUCED
%  ─────────────────────────────────────────────────────────────────────────
%  Main text
%    Figure 1    IRFs to surprise shock        (medium-scale VAR, all vars)
%    Figure 2    IRFs to news shock            (medium-scale VAR, all vars)
%
%  Appendix B – Informational sufficiency
%    Table B.3   Orthogonality test            (medium-scale VAR)
%
%  Appendix C – Structural shock series
%    Figure C.7  Median surprise shock time series
%    Figure C.8  Median news shock time series
%
%  Appendix D – Robustness checks
%    Figure D.9   Full IRF grid (news shock) with nt(1,4)
%    Figure D.10  Consumption-inequality IRF – Gini    – surprise shock
%    Figure D.11  Consumption-inequality IRF – Gini    – news shock
%    Figure D.12  Consumption-inequality IRF – 90-10  – surprise shock
%    Figure D.13  Consumption-inequality IRF – 90-10  – news shock
%
%  Appendix E – FAVAR
%    Table E.4   Orthogonality test (small-scale VAR, 5 variables)
%    Table E.5   Orthogonality test (FAVAR: small-scale + 5 PCs)
%    Figure E.14 FAVAR IRFs to surprise shock
%    Figure E.15 FAVAR IRFs to news shock
%
%  ─────────────────────────────────────────────────────────────────────────
%  Usage
%    >> cd <path-to>/Government-Spending-Shocks
%    >> run_all
%
%  Outputs:
%    Figures/  – all figures as .pdf and .png
%    Tables/   – all tables as .txt

clc; clear; close all;
rng(12345);   % reproducibility

%% ════════════════════════════════════════════════════════════════════════
%  0.  PATHS & SETUP
%% ════════════════════════════════════════════════════════════════════════
root_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(root_dir, 'Functions'));

data_dir = fullfile(root_dir, 'Data');
fig_dir  = fullfile(root_dir, 'Figures');
tab_dir  = fullfile(root_dir, 'Tables');

if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end
if ~exist(tab_dir, 'dir'), mkdir(tab_dir); end

% Shared BVAR options (baseline)
BASE.p       = 4;     % VAR lags
BASE.c       = 1;     % include intercept
BASE.t       = 0;     % no deterministic trend
BASE.drawfin = 5000;  % posterior draws
BASE.hor     = 17;    % impulse-response horizons (quarters)

colorB = [0 0 1];   % fill colour for credibility bands

%% ════════════════════════════════════════════════════════════════════════
%  1.  LOAD DATA
%% ════════════════════════════════════════════════════════════════════════
fprintf('=== Loading data ===\n');
data = readtable(fullfile(data_dir, 'data.xlsx'));

start_sample = datetime('01-Dec-1981', 'InputFormat', 'dd-MMM-yyyy');
end_sample   = datetime('01-Dec-2019', 'InputFormat', 'dd-MMM-yyyy');
idx_s = find(data.TIME == start_sample);
idx_e = find(data.TIME == end_sample);

%  Fiscal-news series
F     = data(idx_s:idx_e,  2).F;             % Ft(1,4)  – SPF measure 1
N_var = data(idx_s:idx_e,  3).N;             % nt(1,4)  – SPF measure 2

%  Macro variables
G        = data(idx_s:idx_e,  4).FEDGOV;
Y        = data(idx_s:idx_e,  5).GDP;        % Real GDP
SUR      = data(idx_s:idx_e,  7).SUR;        % Federal surplus / GDP
BONDY    = data(idx_s:idx_e,  9).x10YBOND;  % 10-yr Treasury yield
RER      = data(idx_s:idx_e, 10).RER;        % Real exchange rate
CP       = data(idx_s:idx_e, 35).CP_REAL;    % Corporate profits (real)
FFR      = data(idx_s:idx_e, 16).FED_FUNDS;  % Federal funds rate
CCI      = data(idx_s:idx_e, 23).CSCICP03USM665S; % Consumer confidence

%  Inequality measures
C_SD   = data(idx_s:idx_e, 11).C_SD_LNCONS_SA;    % Std-dev (MAIN)
C_9010 = data(idx_s:idx_e, 12).C_9010_LNCONS_SA;  % 90-10 range
GINI   = data(idx_s:idx_e, 15).GINI;              % Gini coefficient

%% ════════════════════════════════════════════════════════════════════════
%  2.  FACTORS FROM FRED-QD
%% ════════════════════════════════════════════════════════════════════════
fprintf('=== Estimating factors from FRED-QD ===\n');
factor = get_factors(9, start_sample, end_sample);   % up to 9 factors

%% ════════════════════════════════════════════════════════════════════════
%  3.  BASELINE MEDIUM-SCALE VAR
%      Variables: G, Ft(1,4), GDP, Surplus, Bond, RER,
%                 Corp.Profits, FedFunds, ConsConf, C_SD  (n=10)
%      Prior: Jeffreys   Lags: 4   Constant: yes
%% ════════════════════════════════════════════════════════════════════════
fprintf('\n=== [Baseline VAR] ===\n');

% --- Assemble data -------------------------------------------------------
vardata_base = [G, F, Y, SUR, BONDY, RER, CP, FFR, CCI, C_SD];
VARnames_base = {'Government Spending'; '$F_t(1,4)$'; 'Real GDP'; ...
                 'Federal Surplus'; 'Bond Yield'; 'Real Exchange Rate'; ...
                 'Corporate Profits'; 'Fed Funds Rate'; ...
                 'Consumer Confidence'; 'Consumption Inequality'};

opt_b = BASE;
[opt_b.T, opt_b.n] = size(vardata_base);

% --- Estimate BVAR -------------------------------------------------------
[irf_b, eta_b, ~, ~, ~, ~] = bvar_estimate(vardata_base, opt_b);

% --- Confidence bands ----------------------------------------------------
[LowD_b, MidD_b, HighD_b, LowD90_b, HighD90_b] = ...
    compute_conf_bands(irf_b, opt_b.n, opt_b.hor, 68, 90);

% --- Figure 1 (surprise) & Figure 2 (news) -------------------------------
fprintf('  → Figure 1 & Figure 2\n');
close all;
irf_plot_var_full(opt_b.n, opt_b.n, opt_b.hor, ...
                  MidD_b, HighD_b, LowD_b, HighD90_b, LowD90_b, ...
                  VARnames_base, colorB);

figs = findall(0, 'Type', 'figure');
save_fig(figs(1), fig_dir, 'Figure1');   % surprise (first figure created)
save_fig(figs(2), fig_dir, 'Figure2');   % news     (second figure created)

%% ════════════════════════════════════════════════════════════════════════
%  4.  TABLE B.3 – INFORMATIONAL SUFFICIENCY, MEDIUM-SCALE VAR
%% ════════════════════════════════════════════════════════════════════════
fprintf('\n=== [Table B.3] Informational sufficiency ===\n');

opt_b3 = opt_b;
[pval_surp_B3, pval_news_B3] = check_orthogonality(vardata_base, factor, opt_b3);
n_pc_B3 = min(7, size(factor, 2));
save_sufficiency_table(pval_surp_B3, pval_news_B3, n_pc_B3, ...
    'B.3', fullfile(tab_dir, 'TableB3.txt'));

%% ════════════════════════════════════════════════════════════════════════
%  5.  FIGURES C.7 & C.8 – STRUCTURAL SHOCK SERIES
%% ════════════════════════════════════════════════════════════════════════
fprintf('\n=== [Figures C.7 & C.8] Shock series ===\n');

% After p=4 lags, first usable obs = 1981Q4 + 4Q = 1982Q4 = 1982.75
start_year_shock = 1982.75;
close all;
get_shocks(vardata_base, eta_b, opt_b.p, start_year_shock);

figs = findall(0, 'Type', 'figure');
save_fig(figs(1), fig_dir, 'FigureC7');   % surprise shock (created first)
save_fig(figs(2), fig_dir, 'FigureC8');   % news shock    (created second)

%% ════════════════════════════════════════════════════════════════════════
%  6.  APPENDIX D.1 – nt(1,4) ROBUSTNESS
%      Figure D.9: Full IRF grid to NEWS shock, with nt(1,4)
%% ════════════════════════════════════════════════════════════════════════
fprintf('\n=== [Figure D.9] Robustness: nt(1,4) ===\n');

vardata_N = [G, N_var, Y, SUR, BONDY, RER, CP, FFR, CCI, C_SD];
VARnames_N    = VARnames_base;
VARnames_N{2} = '$n_t(1,4)$';

opt_N      = opt_b;
[opt_N.T, opt_N.n] = size(vardata_N);

[irf_N, ~, ~, ~, ~, ~] = bvar_estimate(vardata_N, opt_N);
[LowD_N, MidD_N, HighD_N] = compute_conf_bands(irf_N, opt_N.n, opt_N.hor, 68, 90);

% Generate both figures, keep only the news figure
close all;
irf_plot_var_full(opt_N.n, opt_N.n, opt_N.hor, ...
                  MidD_N, HighD_N, LowD_N, HighD_N, LowD_N, VARnames_N, colorB);
figs = findall(0, 'Type', 'figure');
close(figs(1));                         % discard surprise figure
save_fig(figs(2), fig_dir, 'FigureD9'); % keep news figure

%% ════════════════════════════════════════════════════════════════════════
%  7.  APPENDIX D.2 – GINI COEFFICIENT ROBUSTNESS
%      Figure D.10: Gini IRF to SURPRISE shock
%      Figure D.11: Gini IRF to NEWS shock
%% ════════════════════════════════════════════════════════════════════════
fprintf('\n=== [Figures D.10 & D.11] Robustness: Gini ===\n');

vardata_Gini = [G, F, Y, SUR, BONDY, RER, CP, FFR, CCI, GINI];

opt_Gi = opt_b;
[opt_Gi.T, opt_Gi.n] = size(vardata_Gini);

[irf_Gi, ~, ~, ~, ~, ~] = bvar_estimate(vardata_Gini, opt_Gi);
[LowD_Gi, MidD_Gi, HighD_Gi] = compute_conf_bands(irf_Gi, opt_Gi.n, opt_Gi.hor, 68, 90);

% Figure D.10 – surprise shock, Gini only
close all;
plot_ineq_one_shock(opt_Gi.n, opt_Gi.n, opt_Gi.hor, ...
    MidD_Gi, HighD_Gi, LowD_Gi, 1, colorB, ...
    'Gini: Surprise shock');
save_fig(gcf, fig_dir, 'FigureD10');

% Figure D.11 – news shock, Gini only
close all;
plot_ineq_one_shock(opt_Gi.n, opt_Gi.n, opt_Gi.hor, ...
    MidD_Gi, HighD_Gi, LowD_Gi, 2, colorB, ...
    'Gini: News shock');
save_fig(gcf, fig_dir, 'FigureD11');

%% ════════════════════════════════════════════════════════════════════════
%  8.  APPENDIX D.3 – 90-10 PERCENTILE ROBUSTNESS
%      Figure D.12: 90-10 IRF to SURPRISE shock
%      Figure D.13: 90-10 IRF to NEWS shock
%% ════════════════════════════════════════════════════════════════════════
fprintf('\n=== [Figures D.12 & D.13] Robustness: 90-10 percentile ===\n');

vardata_90 = [G, F, Y, SUR, BONDY, RER, CP, FFR, CCI, C_9010];

opt_90 = opt_b;
[opt_90.T, opt_90.n] = size(vardata_90);

[irf_90, ~, ~, ~, ~, ~] = bvar_estimate(vardata_90, opt_90);
[LowD_90, MidD_90, HighD_90] = compute_conf_bands(irf_90, opt_90.n, opt_90.hor, 68, 90);

% Figure D.12 – surprise
close all;
plot_ineq_one_shock(opt_90.n, opt_90.n, opt_90.hor, ...
    MidD_90, HighD_90, LowD_90, 1, colorB, ...
    '90-10 Range: Surprise shock');
save_fig(gcf, fig_dir, 'FigureD12');

% Figure D.13 – news
close all;
plot_ineq_one_shock(opt_90.n, opt_90.n, opt_90.hor, ...
    MidD_90, HighD_90, LowD_90, 2, colorB, ...
    '90-10 Range: News shock');
save_fig(gcf, fig_dir, 'FigureD13');

%% ════════════════════════════════════════════════════════════════════════
%  9.  APPENDIX E – FAVAR
%% ════════════════════════════════════════════════════════════════════════

%% ── Table E.4: Small-scale VAR (5 variables) ─────────────────────────────
fprintf('\n=== [Table E.4] Small-scale VAR sufficiency test ===\n');

% 5 variables: G, Ft(1,4), GDP, Federal Surplus, Bond Yield
small_var   = [G, F, Y, SUR, BONDY];
opt_sm      = BASE;
opt_sm.q    = size(small_var, 2);   % = 5
[opt_sm.T, ~] = size(small_var);

[pval_surp_E4, pval_news_E4] = check_orthogonality(small_var, factor, opt_sm);
save_sufficiency_table(pval_surp_E4, pval_news_E4, min(7, size(factor,2)), ...
    'E.4', fullfile(tab_dir, 'TableE4.txt'));

%% ── Table E.5: FAVAR (small-scale + 5 PCs) ──────────────────────────────
fprintf('\n=== [Table E.5] FAVAR sufficiency test ===\n');

% FAVAR variables: G, Ft(1,4), GDP, Surplus, Bond, C_SD, + first 5 PCs
macro_favar   = [G, F, Y, SUR, BONDY, C_SD];
n_mac_favar   = size(macro_favar, 2);   % = 6
favar_data    = [macro_favar, factor(:, 1:5)];
remain_factor = factor(:, 6:7);         % factors NOT included in FAVAR

opt_fav                = BASE;
opt_fav.c              = 0;            % no intercept (factors demeaned)
opt_fav.q              = size(favar_data, 2);   % = 11
[opt_fav.T, opt_fav.n] = size(favar_data);

[pval_surp_E5, pval_news_E5] = check_orthogonality(favar_data, remain_factor, opt_fav);
save_sufficiency_table(pval_surp_E5, pval_news_E5, size(remain_factor, 2), ...
    'E.5', fullfile(tab_dir, 'TableE5.txt'));

%% ── Figures E.14 & E.15: FAVAR IRFs ─────────────────────────────────────
fprintf('\n=== [Figures E.14 & E.15] FAVAR IRFs ===\n');

VARnames_favar = {'Government Spending'; '$F_t(1,4)$'; 'Real GDP'; ...
                  'Federal Surplus'; 'Bond Yield'; 'Consumption Inequality'};

[irf_fav, ~, ~, ~, ~, ~] = bvar_estimate(favar_data, opt_fav);
[LowD_f, MidD_f, HighD_f] = compute_conf_bands(irf_fav, opt_fav.n, opt_fav.hor, 68, 90);

close all;
irf_plot_var(opt_fav.n, n_mac_favar, opt_fav.hor, ...
             MidD_f, HighD_f, LowD_f, VARnames_favar, colorB);

figs = findall(0, 'Type', 'figure');
save_fig(figs(1), fig_dir, 'FigureE14');   % surprise
save_fig(figs(2), fig_dir, 'FigureE15');   % news

%% ════════════════════════════════════════════════════════════════════════
%  10.  SAVE RESULTS
%% ════════════════════════════════════════════════════════════════════════
fprintf('\n=== Saving workspace to Results_all.mat ===\n');
save(fullfile(root_dir, 'Results_all.mat'));

fprintf('\n╔═══════════════════════════════════════╗\n');
fprintf('║         run_all.m COMPLETE            ║\n');
fprintf('╚═══════════════════════════════════════╝\n');
fprintf('Figures  → %s\n', fig_dir);
fprintf('Tables   → %s\n', tab_dir);

%% ════════════════════════════════════════════════════════════════════════
%  LOCAL HELPER FUNCTIONS
%% ════════════════════════════════════════════════════════════════════════

function save_fig(fig_handle, out_dir, name)
% Save figure as PDF and PNG.
    try
        saveas(fig_handle, fullfile(out_dir, [name, '.pdf']));
        saveas(fig_handle, fullfile(out_dir, [name, '.png']));
        fprintf('    Saved %s\n', name);
    catch ME
        warning('Could not save %s: %s', name, ME.message);
    end
end

function plot_ineq_one_shock(n, var_idx, hor, MiddleIRF, HighIRF, LowIRF, ...
                              shock_num, colorBNDS, fig_title)
% Plot IRF of a single variable (var_idx = last variable) to one shock.
%
%  shock_num: 1 = surprise, 2 = news
%  var_idx:   index of the inequality variable (typically n = last)

col = shock_num + n*(var_idx - 1);   % column in the (hor × n²) band matrices
h   = 0:hor-1;

figure('Units', 'normalized', 'Position', [0.2 0.3 0.5 0.4]);
fill([h, fliplr(h)], [HighIRF(:,col)', flipud(LowIRF(:,col))'], ...
     colorBNDS, 'EdgeColor', 'k');
alpha(0.20); hold on;
plot(h, MiddleIRF(:,col), 'k-.', 'LineWidth', 2);
yline(0, 'r-', 'LineWidth', 1);
xlim([0 hor-1]);
set(gca, 'FontSize', 20, 'FontName', 'Times');
axis tight;
ytickformat('%.2f');
title(fig_title, 'FontSize', 18, 'FontName', 'Times');
xlabel('Quarters', 'FontSize', 16, 'FontName', 'Times');
hold off;
end
