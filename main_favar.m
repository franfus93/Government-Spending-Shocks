%% main_favar.m  –  FAVAR robustness (Appendix E, DFT 2026)
%
%  Tests informational sufficiency of a small-scale VAR (4 macro variables)
%  and of the FAVAR augmented with 5 principal components from FRED-QD.
%  Reports Tables E.4 and E.5 and plots Figures E.14–E.15.
%
%  Small-scale VAR variables (Table E.4):
%    1  Government Spending   2  Ft(1,4)   3  Real GDP
%    4  Federal Surplus       5  10-yr Bond yield
%
%  FAVAR variables (Table E.5, Figures E.14–E.15):
%    [Small-scale VAR (5)] + [C_SD (inequality)] + [5 PCs from FRED-QD]
%
%  Estimation: Bayesian VAR(4), NO intercept (factors are demeaned),
%              5 000 posterior draws

clc; clear; close all;

%% ── 0. Paths ─────────────────────────────────────────────────────────────
root_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(root_dir, 'Functions'));
data_dir = fullfile(root_dir, 'Data');
fig_dir  = fullfile(root_dir, 'Figures');
tab_dir  = fullfile(root_dir, 'Tables');
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end
if ~exist(tab_dir, 'dir'), mkdir(tab_dir); end

%% ── 1. Load data ─────────────────────────────────────────────────────────
data = readtable(fullfile(data_dir, 'data.xlsx'));

start_sample = datetime('01-Dec-1981', 'InputFormat', 'dd-MMM-yyyy');
end_sample   = datetime('01-Dec-2019', 'InputFormat', 'dd-MMM-yyyy');
idx_start = find(data.TIME == start_sample);
idx_end   = find(data.TIME == end_sample);

F          = data(idx_start:idx_end,  2);   % Ft(1,4)
FEDGOV     = data(idx_start:idx_end,  4);   % Real govt spending
GDP        = data(idx_start:idx_end,  5);   % Real GDP
SUR        = data(idx_start:idx_end,  7);   % Federal surplus
BONDY      = data(idx_start:idx_end,  9);   % 10-yr bond yield
C_SD_LNCONS_SA = data(idx_start:idx_end, 11); % Consumption std-dev

%% ── 2. Model options ─────────────────────────────────────────────────────
opt.r       = 9;
opt.p       = 4;
opt.c       = 0;     % no intercept (factors already demeaned)
opt.t       = 0;
opt.drawfin = 5000;
opt.hor     = 17;

%% ── 3. Estimate factors from FRED-QD ────────────────────────────────────
factor = get_factors(opt.r, start_sample, end_sample);
% factor is (T × r), columns ordered by eigenvalue magnitude

%% ── 4. Table E.4 – Informational sufficiency of the small-scale VAR ─────
%  Small-scale VAR: G, Ft(1,4), GDP, Federal Surplus, Bond Yield
small_var = [FEDGOV.FEDGOV, F.F, GDP.GDP, SUR.SUR, BONDY.x10YBOND];
opt_small      = opt;
opt_small.q    = size(small_var, 2);   % = 5
opt_small.c    = 1;                    % constant in OLS step of check_orthogonality
[pval_surp_E4, pval_news_E4] = check_orthogonality(small_var, factor, opt_small);

n_pc = min(7, size(factor, 2));
save_sufficiency_table(pval_surp_E4, pval_news_E4, n_pc, 'E.4', ...
    fullfile(tab_dir, 'TableE4.txt'));

%% ── 5. Table E.5 – Informational sufficiency of the FAVAR ───────────────
%  Full FAVAR: [small_var, C_SD, 5 PCs] = 11 variables total
macro_favar = [FEDGOV.FEDGOV, F.F, GDP.GDP, SUR.SUR, BONDY.x10YBOND, ...
               C_SD_LNCONS_SA.C_SD_LNCONS_SA];
n_macro = size(macro_favar, 2);   % = 6
favar_data = [macro_favar, factor(:, 1:5)];

% Test shocks from the FAVAR against the remaining factors (6 and 7)
remaining_factors = factor(:, 6:7);
opt_favar   = opt;
opt_favar.q = size(favar_data, 2);   % = 11
[pval_surp_E5, pval_news_E5] = check_orthogonality(favar_data, remaining_factors, opt_favar);

n_rem = size(remaining_factors, 2);   % = 2
save_sufficiency_table(pval_surp_E5, pval_news_E5, n_rem, 'E.5', ...
    fullfile(tab_dir, 'TableE5.txt'));

%% ── 6. FAVAR BVAR estimation ─────────────────────────────────────────────
VARnames_favar = {'Government Spending'; '$F_t(1,4)$'; 'Real GDP'; ...
                  'Federal Surplus'; 'Bond Yield'; 'Consumption Inequality'};

[opt_favar.T, opt_favar.n] = size(favar_data);
fprintf('Estimating FAVAR (%d draws)...\n', opt_favar.drawfin);

[candidateirf_wold_favar, eta_favar, ~, ~, ~, ~] = ...
    bvar_estimate(favar_data, opt_favar);

%% ── 7. Confidence bands ──────────────────────────────────────────────────
[LowD_f, MiddleD_f, HighD_f] = compute_conf_bands( ...
    candidateirf_wold_favar, opt_favar.n, opt_favar.hor, 68, 90);

%% ── 8. Figures E.14 & E.15 ──────────────────────────────────────────────
colorBNDS = [0 0 1];

% irf_plot_var uses subplot(3,3) for q=6 macro variables
irf_plot_var(opt_favar.n, n_macro, opt_favar.hor, ...
             MiddleD_f, HighD_f, LowD_f, VARnames_favar, colorBNDS);

figs = findall(0, 'Type', 'figure');
if numel(figs) >= 2
    saveas(figs(end),   fullfile(fig_dir, 'FigureE14.pdf'));
    saveas(figs(end),   fullfile(fig_dir, 'FigureE14.png'));
    saveas(figs(end-1), fullfile(fig_dir, 'FigureE15.pdf'));
    saveas(figs(end-1), fullfile(fig_dir, 'FigureE15.png'));
    fprintf('Saved FigureE14 and FigureE15.\n');
end

%% ── 9. Save workspace ────────────────────────────────────────────────────
save(fullfile(root_dir, 'Results_FAVAR.mat'), ...
     'favar_data', 'opt_favar', 'VARnames_favar', ...
     'candidateirf_wold_favar', 'MiddleD_f', 'HighD_f', 'LowD_f', ...
     'eta_favar', 'pval_surp_E4', 'pval_news_E4', ...
     'pval_surp_E5', 'pval_news_E5');

fprintf('FAVAR complete.\n');
