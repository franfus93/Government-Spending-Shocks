function [candidateirf_wold, eta, errornorm, PI, BigA, Sigma] = bvar_estimate(vardata, opt)
% BVAR_ESTIMATE  Bayesian VAR estimation with Jeffreys (diffuse) priors.
%
%  Draws from the posterior, enforces stability of each draw, computes
%  Cholesky-identified IRFs, and returns structural shocks.
%
%  INPUTS
%   vardata  – (T × n) data matrix
%   opt      – structure with fields:
%               .p        number of lags
%               .c        1 = include intercept, 0 = no intercept
%               .t        1 = include linear trend, 0 = no trend
%               .drawfin  number of posterior draws to retain
%               .hor      IRF horizon (quarters)
%
%  OUTPUTS
%   candidateirf_wold – (hor × n² × drawfin) reshaped IRFs
%                       column index = shock + n*(variable-1)
%   eta               – (T-p × n × drawfin) structural shocks
%                       col 1 = surprise (govt spending), col 2 = news
%   errornorm         – (T-p × n × drawfin) reduced-form residuals
%   PI                – (n*p+c+t × n × drawfin) VAR coefficients
%   BigA              – (n*p × n*p × drawfin) companion matrices
%   Sigma             – (n × n × drawfin) residual covariance matrices

[T, n]  = size(vardata);
p       = opt.p;
c       = opt.c;
t       = opt.t;
drawfin = opt.drawfin;
hor     = opt.hor;
m       = n*p + c + t;   % number of regressors per equation

%% ── Posterior draws ──────────────────────────────────────────────────────
PI        = zeros(m, n, drawfin);
BigA      = zeros(n*p, n*p, drawfin);
Sigma     = zeros(n, n, drawfin);
errornorm = zeros(T-p, n, drawfin);

for i = 1:drawfin
    stable = -1;
    while stable < 0
        [PI(:,:,i), BigA(:,:,i), Sigma(:,:,i), errornorm(:,:,i), ~] = ...
            BVAR_niw(vardata, p, c, t, n);
        if all(abs(eig(BigA(:,:,i))) < 1)
            stable = 1;
        end
    end
    if mod(i, 500) == 0
        fprintf('  BVAR draw %d / %d\n', i, drawfin);
    end
end

%% ── Cholesky IRFs and structural shocks ──────────────────────────────────
candidateirf = zeros(n, n, hor, drawfin);
eta          = zeros(T-p, n, drawfin);

for k = 1:drawfin
    % Wold (reduced-form) IRFs via companion matrix powers
    C = zeros(n, n, hor);
    for j = 1:hor
        BigC  = BigA(:,:,k)^(j-1);
        C(:,:,j) = BigC(1:n, 1:n);
    end
    % Cholesky factor of Sigma: Sigma = S*S'
    S = chol(Sigma(:,:,k), 'lower');
    % Cholesky IRFs: D(v,s,j) = response of var v to structural shock s at horizon j
    for j = 1:hor
        candidateirf(:,:,j,k) = C(:,:,j) * S;
    end
    % Structural shocks: eps_t = S * eta_t  =>  eta_t = S \ eps_t
    eta(:,:,k) = (candidateirf(:,:,1,k) \ errornorm(:,:,k)')';
end

%% ── Reshape IRFs to (hor × n² × drawfin) ────────────────────────────────
% Column ordering: col = shock_index + n*(variable_index - 1)
candidateirf_wold = zeros(hor, n*n, drawfin);
for k = 1:drawfin
    candidateirf_wold(:,:,k) = reshape( ...
        permute(candidateirf(:,:,:,k), [3 2 1]), hor, n*n, []);
end

end
