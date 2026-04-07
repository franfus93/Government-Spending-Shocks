function [LowD, MiddleD, HighD, LowD90, HighD90] = ...
        compute_conf_bands(candidateirf_wold, n, hor, conf_narrow, conf_large)
% COMPUTE_CONF_BANDS  Pointwise posterior quantiles from BVAR IRF draws.
%
%  INPUTS
%   candidateirf_wold – (hor × n² × drawfin) IRF draws
%                       column = shock_index + n*(variable_index-1)
%   n                 – number of VAR variables
%   hor               – IRF horizon
%   conf_narrow       – narrow band coverage (e.g. 68 for 68%)
%   conf_large        – wide band coverage   (e.g. 90 for 90%)
%
%  OUTPUTS (each hor × n²)
%   LowD    – lower bound, narrow band
%   MiddleD – posterior median
%   HighD   – upper bound, narrow band
%   LowD90  – lower bound, wide band
%   HighD90 – upper bound, wide band

LowD    = zeros(hor, n*n);
LowD90  = zeros(hor, n*n);
MiddleD = zeros(hor, n*n);
HighD   = zeros(hor, n*n);
HighD90 = zeros(hor, n*n);

for v = 1:n          % variable index
    for s = 1:n      % shock index
        col = s + n*(v-1);
        LowD(:,col)    = prctile(candidateirf_wold(:,col,:), (100-conf_narrow)/2, 3);
        LowD90(:,col)  = prctile(candidateirf_wold(:,col,:), (100-conf_large)/2,  3);
        MiddleD(:,col) = prctile(candidateirf_wold(:,col,:), 50, 3);
        HighD(:,col)   = prctile(candidateirf_wold(:,col,:), (100+conf_narrow)/2, 3);
        HighD90(:,col) = prctile(candidateirf_wold(:,col,:), (100+conf_large)/2,  3);
    end
end

end
