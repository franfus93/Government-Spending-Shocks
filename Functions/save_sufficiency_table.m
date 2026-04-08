function save_sufficiency_table(pval_surp, n_pc, table_label, filepath)
% SAVE_SUFFICIENCY_TABLE  Format and save informational-sufficiency table.
%
%  Replicates the style of Tables B.3, E.4, and E.5 in DFT2026.
%  Reports F-test p-values for the surprise shock only (FG2016).
%
%  INPUTS
%   pval_surp   – (n_pc × 4) cell or matrix of p-values:
%                 surprise shock × lag groups Lag1, Lag1:2, Lag1:3, Lag1:4
%   n_pc        – number of principal components tested
%   table_label – string label for the table (e.g. 'B.3')
%   filepath    – full path to the output .txt file

% Convert cell array to numeric matrix if necessary
if iscell(pval_surp)
    P = zeros(n_pc, 4);
    for i = 1:n_pc
        for j = 1:4
            if i <= size(pval_surp, 1) && j <= size(pval_surp, 2)
                v = pval_surp{i,j};
                P(i,j) = v(1);
            end
        end
    end
else
    P = pval_surp(1:n_pc, 1:4);
end

hdr  = '  PC  Lag1    Lag1:2  Lag1:3  Lag1:4\n';
sep  = repmat('-', 1, 42);

% Print to console
fprintf('\nTable %s: Testing for informational sufficiency (surprise shock)\n', table_label);
fprintf('* p < 0.10, ** p < 0.05, *** p < 0.01\n\n');
fprintf(hdr);
fprintf('%s\n', sep);
for i = 1:n_pc
    row = '';
    for j = 1:4
        p = P(i,j);
        row = [row, sprintf('%-8s', [sprintf('%.2f', p), get_stars(p)])]; %#ok<AGROW>
    end
    fprintf('  %d   %s\n', i, row);
end
fprintf('\n');

% Write to file
if ~isempty(filepath)
    fid = fopen(filepath, 'w');
    if fid == -1
        warning('Could not open %s for writing.', filepath);
        return;
    end
    fprintf(fid, 'Table %s: Testing for informational sufficiency (surprise shock)\n', table_label);
    fprintf(fid, '* p < 0.10, ** p < 0.05, *** p < 0.01\n\n');
    fprintf(fid, hdr);
    fprintf(fid, '%s\n', sep);
    for i = 1:n_pc
        row = '';
        for j = 1:4
            p = P(i,j);
            row = [row, sprintf('%-8s', [sprintf('%.2f', p), get_stars(p)])]; %#ok<AGROW>
        end
        fprintf(fid, '  %d   %s\n', i, row);
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
