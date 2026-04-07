
function [mdl_suff_surprise,mdl_suff_news] = check_orthogonality(macro_data,factor,opt)


%% Shock 1

for i = 1:size(factor,2)
factor_lags(:,:,i) = lagmatrix(factor(:,i), 1:opt.p);
end

% VAR

[~,~,~,~,~,~,~,~,~,~,eta]=chol_irf(macro_data,opt.q,opt.p,opt.c,opt.t,opt.hor); % Cholesky IRFs
mdl = cell(1, size(factor,2));   % preallocate cell

for i = 1:size(factor,2)
    X = factor_lags(opt.p+1:end,:,i);   % predictors
    for j=1:4
        % Create table with j separate columns as individual variables
        tbl_data = array2table(X(:,1:j), 'VariableNames', compose('X%d',1:j)');
        tbl = [tbl_data, table(eta(:,1), 'VariableNames', {'eta'})];
        mdl_surprise{i,j}  = fitlm(tbl);
        mdl_suff_surprise{i,j} = mdl_surprise{i,j}.ModelFitVsNullModel.Pvalue;
    end
end

%% Shock 2



for i = 1:size(factor,2)
    X = factor_lags(opt.p+1:end,:,i);   % predictors
    for j=1:4
        % Create table with j separate columns as individual variables
        tbl_data = array2table(X(:,1:j), 'VariableNames', compose('X%d',1:j)');
        tbl = [tbl_data, table(eta(:,2), 'VariableNames', {'eta'})];
        mdl_news{i,j}  = fitlm(tbl);
        mdl_suff_news{i,j} = mdl_news{i,j}.ModelFitVsNullModel.Pvalue;
    end
end



end