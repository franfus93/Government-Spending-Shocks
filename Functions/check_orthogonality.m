function [mdl_suff_surprise, mdl_suff_news] = check_orthogonality(macro_data, factor, opt)
% CHECK_ORTHOGONALITY  Test informational sufficiency (Forni & Gambetti 2014).
%
%  Regresses the Cholesky surprise shock (col 1) and news shock (col 2)
%  on lags 1, 1:2, 1:3, and 1:4 of each principal component in FACTOR.
%  Reports F-test p-values for each regression.
%
%  INPUTS
%   macro_data – (T × q) data matrix used for OLS VAR shock extraction
%   factor     – (T × n_pc) principal components to test against
%   opt        – structure with fields: .q, .p, .c, .t, .hor
%
%  OUTPUTS (each n_pc × 4 cell, {i,j} = scalar p-value for PC i, lag group j)
%   mdl_suff_surprise – F-test p-values for the surprise shock
%   mdl_suff_news     – F-test p-values for the news shock
%
%  NOTE: shocks are identified by OLS Cholesky on macro_data.
%    Shock 1 = surprise (unanticipated)  → col 1 of eta
%    Shock 2 = news     (anticipated)    → col 2 of eta

n_pc = size(factor, 2);
T    = size(factor, 1);

%% ── Step 1: Extract OLS Cholesky shocks from macro_data ─────────────────
% chol_irf returns eta as (T-p × q) matrix of structural shocks
[~,~,~,~,~,~,~,~,~,~, eta] = chol_irf(macro_data, opt.q, opt.p, opt.c, opt.t, opt.hor);

%% ── Step 2: Build lagged factor matrices ─────────────────────────────────
% factor_lags(t, lag, i) = factor i, lag lags back at time t
factor_lags = zeros(T, opt.p, n_pc);
for i = 1:n_pc
    factor_lags(:,:,i) = lagmatrix(factor(:,i), 1:opt.p);
end

%% ── Step 3: F-tests – surprise shock (eta col 1) ─────────────────────────
mdl_suff_surprise = cell(n_pc, 4);

for i = 1:n_pc
    X = factor_lags(opt.p+1:end, :, i);   % (T-p) × p, discard first p NaN rows
    for j = 1:4
        colnames = compose('X%d', 1:j)';
        tbl = [array2table(X(:,1:j), 'VariableNames', colnames), ...
               table(eta(:,1), 'VariableNames', {'eta'})];
        mdl = fitlm(tbl);
        mdl_suff_surprise{i,j} = mdl.ModelFitVsNullModel.Pvalue;
    end
end

%% ── Step 4: F-tests – news shock (eta col 2) ─────────────────────────────
mdl_suff_news = cell(n_pc, 4);

for i = 1:n_pc
    X = factor_lags(opt.p+1:end, :, i);
    for j = 1:4
        colnames = compose('X%d', 1:j)';
        tbl = [array2table(X(:,1:j), 'VariableNames', colnames), ...
               table(eta(:,2), 'VariableNames', {'eta'})];
        mdl = fitlm(tbl);
        mdl_suff_news{i,j} = mdl.ModelFitVsNullModel.Pvalue;
    end
end

end
