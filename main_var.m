%% main_var.m  –  Baseline medium-scale VAR (DFT 2026)
%
%  Identification: Forni & Gambetti (2016) recursive Cholesky
%  Variables  (ordered for identification):
%    1  Government Spending (G)
%    2  Fiscal-news measure Ft(1,4)        <-- ordered second
%    3  Real GDP
%    4  Federal Surplus / GDP
%    5  10-year Treasury yield
%    6  Real Exchange Rate
%    7  Corporate Profits (real, after-tax)
%    8  Federal Funds Rate
%    9  Consumer Confidence
%   10  Consumption Inequality (cross-sectional std-dev)
%
%  Estimation: Bayesian VAR(4) with Normal-Inverse-Wishart (NIW) priors
%              4 lags, intercept, 5 000 posterior draws
%  Sample:     1981:Q4 – 2019:Q4
%
%  Outputs (saved to Figures/):
%    Figure1.{pdf,png}   IRFs to surprise shock
%    Figure2.{pdf,png}   IRFs to news shock

clc; clear; close all;

%% ── 0. Paths ─────────────────────────────────────────────────────────────
root_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(root_dir, 'Functions'));
data_dir = fullfile(root_dir, 'Data');
fig_dir  = fullfile(root_dir, 'Figures');
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end

%% ── 1. Load data ─────────────────────────────────────────────────────────
data = readtable(fullfile(data_dir, 'data.xlsx'));

start_sample = datetime('01-Dec-1981', 'InputFormat', 'dd-MMM-yyyy');
end_sample   = datetime('01-Dec-2019', 'InputFormat', 'dd-MMM-yyyy');

idx_start = find(data.TIME == start_sample);
idx_end   = find(data.TIME == end_sample);

F            = data(idx_start:idx_end,  2);   % Ft(1,4) – SPF news measure 1
FEDGOV       = data(idx_start:idx_end,  4);   % Real govt spending
GDP          = data(idx_start:idx_end,  5);   % Real GDP
SUR          = data(idx_start:idx_end,  7);   % Federal surplus / GDP
BONDY        = data(idx_start:idx_end,  9);   % 10-yr Treasury yield
RER          = data(idx_start:idx_end, 10);   % Real exchange rate
C_SD_LNCONS_SA = data(idx_start:idx_end, 11); % Consumption std-dev (main ineq. measure)
FED_FUNDS    = data(idx_start:idx_end, 16);   % Federal funds rate
CP_REAL      = data(idx_start:idx_end, 35);   % Corporate profits (real)
CCI          = data(idx_start:idx_end, 23);   % Consumer confidence

%% ── 2. Model options ─────────────────────────────────────────────────────
opt.r       = 9;     % max factors for get_factors
opt.p       = 4;     % VAR lags
opt.c       = 1;     % include intercept
opt.t       = 0;     % no deterministic trend
opt.drawfin = 5000;  % posterior draws
opt.hor     = 17;    % impulse-response horizons

%% ── 3. Assemble VAR data matrix ──────────────────────────────────────────
vardata = [FEDGOV.FEDGOV, F.F, GDP.GDP, SUR.SUR, BONDY.x10YBOND, ...
           RER.RER, CP_REAL.CP_REAL, FED_FUNDS.FED_FUNDS, ...
           CCI.CSCICP03USM665S, C_SD_LNCONS_SA.C_SD_LNCONS_SA];

VARnames = {'Government Spending'; '$F_t(1,4)$'; 'Real GDP'; ...
            'Federal Surplus'; 'Bond Yield'; 'Real Exchange Rate'; ...
            'Corporate Profits'; 'Fed Funds Rate'; ...
            'Consumer Confidence'; 'Consumption Inequality'};

[opt.T, opt.n] = size(vardata);
opt.q = opt.n;   % pure VAR: no latent factors

%% ── 4. BVAR estimation (NIW priors) ──────────────────────────────────────
fprintf('Estimating baseline VAR (%d draws)...\n', opt.drawfin);

PI         = zeros(opt.n*opt.p + opt.c + opt.t, opt.n, opt.drawfin);
BigA       = zeros(opt.n*opt.p, opt.n*opt.p, opt.drawfin);
Sigma      = zeros(opt.n, opt.n, opt.drawfin);
errornorm  = zeros(opt.T - opt.p, opt.n, opt.drawfin);
fittednorm = zeros(opt.T - opt.p, opt.n, opt.drawfin);

for i = 1:opt.drawfin
    stable = -1;
    while stable < 0
        [PI(:,:,i), BigA(:,:,i), Sigma(:,:,i), ...
         errornorm(:,:,i), fittednorm(:,:,i)] = ...
            BVAR_niw(vardata, opt.p, opt.c, opt.t, opt.n);
        if all(abs(eig(BigA(:,:,i))) < 1)
            stable = 1;
        end
    end
    if mod(i, 500) == 0
        fprintf('  Draw %d / %d\n', i, opt.drawfin);
    end
end

%% ── 5. Cholesky IRFs ─────────────────────────────────────────────────────
candidateirf = zeros(opt.n, opt.n, opt.hor, opt.drawfin);
eta          = zeros(opt.T - opt.p, opt.n, opt.drawfin);

news_shocks       = zeros(opt.T - opt.p, opt.drawfin);
gov_spending_shocks = zeros(opt.T - opt.p, opt.drawfin);

for k = 1:opt.drawfin
    % Wold representation
    C = zeros(opt.n, opt.n, opt.hor);
    for j = 1:opt.hor
        BigC = BigA(:,:,k)^(j-1);
        C(:,:,j) = BigC(1:opt.n, 1:opt.n);
    end
    % Cholesky factorisation
    S = chol(Sigma(:,:,k), 'lower');
    D = zeros(opt.n, opt.n, opt.hor);
    for j = 1:opt.hor
        D(:,:,j) = C(:,:,j) * S;
    end
    candidateirf(:,:,:,k) = D;
    % Structural shocks: epsilon = S * eta  =>  eta = S \ epsilon
    eta(:,:,k) = (D(:,:,1) \ errornorm(:,:,k)')';
    gov_spending_shocks(:,k) = eta(:,1,k);   % shock 1 = surprise
    news_shocks(:,k)         = eta(:,2,k);   % shock 2 = news
end

%% ── 6. Confidence bands ──────────────────────────────────────────────────
% Reshape IRFs: (hor × n² × drawfin), col = shock + n*(variable-1)
candidateirf_wold = zeros(opt.hor, opt.n*opt.n, opt.drawfin);
for k = 1:opt.drawfin
    candidateirf_wold(:,:,k) = reshape( ...
        permute(candidateirf(:,:,:,k), [3 2 1]), opt.hor, opt.n*opt.n, []);
end

conf_narrow = 68;
conf_large  = 90;

LowD   = zeros(opt.hor, opt.n*opt.n);
LowD90 = zeros(opt.hor, opt.n*opt.n);
MiddleD = zeros(opt.hor, opt.n*opt.n);
HighD  = zeros(opt.hor, opt.n*opt.n);
HighD90 = zeros(opt.hor, opt.n*opt.n);

for v = 1:opt.n
    for s = 1:opt.n
        col = s + opt.n*(v-1);
        LowD(:,col)    = prctile(candidateirf_wold(:,col,:), (100-conf_narrow)/2, 3);
        LowD90(:,col)  = prctile(candidateirf_wold(:,col,:), (100-conf_large)/2,  3);
        MiddleD(:,col) = prctile(candidateirf_wold(:,col,:), 50, 3);
        HighD(:,col)   = prctile(candidateirf_wold(:,col,:), (100+conf_narrow)/2, 3);
        HighD90(:,col) = prctile(candidateirf_wold(:,col,:), (100+conf_large)/2,  3);
    end
end

%% ── 7. Plot IRFs ─────────────────────────────────────────────────────────
colorBNDS = [0 0 1];

% Figure 1 – surprise shock | Figure 2 – news shock
irf_plot_var_full(opt.n, opt.q, opt.hor, MiddleD, HighD, LowD, ...
                  HighD90, LowD90, VARnames, colorBNDS);

% Save Figure 1 (first figure created)
figs = findall(0, 'Type', 'figure');
if numel(figs) >= 2
    saveas(figs(end),   fullfile(fig_dir, 'Figure1.pdf'));
    saveas(figs(end),   fullfile(fig_dir, 'Figure1.png'));
    saveas(figs(end-1), fullfile(fig_dir, 'Figure2.pdf'));
    saveas(figs(end-1), fullfile(fig_dir, 'Figure2.png'));
    fprintf('Saved Figure1 and Figure2.\n');
end

%% ── 8. Save workspace for downstream use ────────────────────────────────
save(fullfile(root_dir, 'Results_VAR.mat'), ...
     'vardata', 'opt', 'VARnames', ...
     'candidateirf_wold', 'MiddleD', 'HighD', 'LowD', 'HighD90', 'LowD90', ...
     'eta', 'gov_spending_shocks', 'news_shocks', ...
     'PI', 'BigA', 'Sigma', 'errornorm');

fprintf('Baseline VAR complete.\n');
