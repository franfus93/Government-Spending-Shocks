function save_sufficiency_table(pval_surp, pval_news, n_pc, table_label, filepath)
% SAVE_SUFFICIENCY_TABLE  Format and save informational-sufficiency table.
%
%  Replicates the style of Tables B.3, E.4, and E.5 in DFT2026.
%
%  INPUTS
%   pval_surp   – (n_pc × 4) p-values: surprise shock × lag groups 1..4
%   pval_news   – (n_pc × 4) p-values: news shock × lag groups 1..4
%   n_pc        – number of principal components tested
%   table_label – string label for the table (e.g. 'B.3')
%   filepath    – full path to the output .txt file
%
%  The p-value matrices are expected to be structured as:
%    pval_surp{i,j} = scalar p-value for PC i, lag group j (j=1..4)
%  They may also be plain (n_pc × 4) numeric matrices.

% Convert cell arrays to numeric if necessary
if iscell(pval_surp)
    P_surp = zeros(n_pc, 4);
    P_news = zeros(n_pc, 4);
    for i = 1:n_pc
        for j = 1:4
            if i <= size(pval_surp, 1) && j <= size(pval_surp, 2)
                v = pval_surp{i,j};
                P_surp(i,j) = v(1);
            end
            if i <= size(pval_news, 1) && j <= size(pval_news, 2)
                v = pval_news{i,j};
                P_news(i,j) = v(1);
            end
        end
    end
else
    P_surp = pval_surp(1:n_pc, 1:4);
    P_news = pval_news(1:n_pc, 1:4);
end

% Print to console
fprintf('\nTable %s: Testing for informational sufficiency\n', table_label);
fprintf('* p < 0.10, ** p < 0.05, *** p < 0.01\n\n');
hdr = '  PC  Lag1    Lag1:2  Lag1:3  Lag1:4  |  PC  Lag1    Lag1:2  Lag1:3  Lag1:4\n';
fprintf('       Surprise shock                    |       News shock\n');
fprintf(hdr);
fprintf('%s\n', repmat('-', 1, 80));

for i = 1:n_pc
    % Surprise side
    row_s = '';
    for j = 1:4
        p = P_surp(i,j);
        stars = get_stars(p);
        row_s = [row_s, sprintf('%-8s', [sprintf('%.2f', p), stars])]; %#ok<AGROW>
    end
    % News side
    row_n = '';
    for j = 1:4
        p = P_news(i,j);
        stars = get_stars(p);
        row_n = [row_n, sprintf('%-8s', [sprintf('%.2f', p), stars])]; %#ok<AGROW>
    end
    fprintf('  %d   %s| %d   %s\n', i, row_s, i, row_n);
end
fprintf('\n');

% Write to file
if ~isempty(filepath)
    fid = fopen(filepath, 'w');
    if fid == -1
        warning('Could not open %s for writing.', filepath);
        return;
    end
    fprintf(fid, 'Table %s: Testing for informational sufficiency\n', table_label);
    fprintf(fid, '* p < 0.10, ** p < 0.05, *** p < 0.01\n\n');
    fprintf(fid, '       Surprise shock                    |       News shock\n');
    fprintf(fid, hdr);
    fprintf(fid, '%s\n', repmat('-', 1, 80));
    for i = 1:n_pc
        row_s = '';
        for j = 1:4
            p = P_surp(i,j);
            stars = get_stars(p);
            row_s = [row_s, sprintf('%-8s', [sprintf('%.2f', p), stars])]; %#ok<AGROW>
        end
        row_n = '';
        for j = 1:4
            p = P_news(i,j);
            stars = get_stars(p);
            row_n = [row_n, sprintf('%-8s', [sprintf('%.2f', p), stars])]; %#ok<AGROW>
        end
        fprintf(fid, '  %d   %s| %d   %s\n', i, row_s, i, row_n);
    end
    fclose(fid);
    fprintf('Table %s saved to: %s\n', table_label, filepath);
end

end

%% ── Local helper ─────────────────────────────────────────────────────────
function s = get_stars(p)
    if p < 0.01
        s = '***';
    elseif p < 0.05
        s = '**';
    elseif p < 0.10
        s = '*';
    else
        s = '';
    end
end
