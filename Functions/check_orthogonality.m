function mdl_suff_surprise = check_orthogonality(macro_data, factor, opt)
% CHECK_ORTHOGONALITY  Test informational sufficiency (Forni & Gambetti 2016).
%
%  Regresses the Cholesky surprise shock (col 1 of eta) on lags 1, 1:2,
%  1:3, and 1:4 of each principal component in FACTOR.  Reports F-test
%  p-values for each regression.  Consistently with FG2016, only the
%  surprise shock (shock 1, unanticipated government spending) is tested.
%
%  INPUTS
%   macro_data – (T × q) data matrix used for OLS VAR shock extraction
%   factor     – (T × n_pc) principal components to test against
%   opt        – structure with fields: .q, .p, .c, .t, .hor
%
%  OUTPUT
%   mdl_suff_surprise – (n_pc × 4) cell: {i,j} = F-test p-value for PC i,
%                       lag group j (j = 1, 1:2, 1:3, 1:4)
%
%  NOTE: shock 1 = surprise (unanticipated government spending) = col 1 of eta.

n_pc = size(factor, 2);

%% ── Step 1: Extract OLS Cholesky shocks from macro_data ─────────────────
% chol_irf returns eta as (T-p × q) matrix of structural shocks
[~,~,~,~,~,~,~,~,~,~, eta] = chol_irf(macro_data, opt.q, opt.p, opt.c, opt.t, opt.hor);

%% ── Step 2: Build lagged factor matrices ─────────────────────────────────
T = size(factor, 1);
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

end
