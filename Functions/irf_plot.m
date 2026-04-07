function irf_plot(n,q,hor,MiddleIRF,HighIRF,LowIRF,VARnames,colorBNDS)
% Plot IRFs of VAR(p) in one figure with two rows and 5 columns (excluding second variable)
set(0,'defaultAxesFontName', 'Times');
set(0,'defaultAxesLineStyleOrder','-|--|:', 'defaultLineLineWidth',1.5)

% Create figure with optimized settings for minimal margins
figure('PaperOrientation', 'portrait', 'PaperPositionMode', 'manual', 'PaperPosition', [0 0 8.5 11]);

% Key addition: Use tight_layout equivalent and adjust subplot spacing
set(gcf, 'Units', 'normalized', 'Position', [0.1 0.1 0.8 0.8]); % Adjust figure position on screen

% Create subplot indices for 5 variables (excluding the second variable)
plot_indices = [1, 3:q]; % Skip variable 2, include variables 1, 3, 4, 5, 6

for i = 1:6 % Now we have 5 plots per row
    
    
    k = plot_indices(i); % Get the actual variable index


     % -------- Shock 2 (first row - News shock) --------
    subplot(2,6,i) % first row of plots, 5 columns
    set(gca,'FontSize',8)  
    fill([0:hor-1 fliplr(0:hor-1)]' ,[HighIRF(:,2+n*k-n); flipud(LowIRF(:,2+n*k-n))],...
    colorBNDS,'EdgeColor','k'); hold on;
    alpha(.20)
    plot(0:hor-1,MiddleIRF(:,2+n*k-n),'LineWidth',1.5,'Color','k','LineStyle','-.'); hold on;
    xlim([0 hor-1]);
    line(get(gca,'xlim'),[0 0],'Color',[1 0 0],'LineStyle','-','LineWidth',1); hold off;
    ax = gca;
    xlabel(ax, VARnames{k}, 'FontSize', 14);  % bigger label
    ax.XAxis.FontSize = 14;  
    ax.YAxis.FontSize = 14;  % tick labels bigger
    axis tight
    ytickformat('%.1f')   % <<< NEW: format y-axis labels to 1 decimal

     
    
      % -------- Shock 1 (second row - Surprise shock) --------
    subplot(2,6,i+6) % second row of plots, 5 columns
    set(gca,'FontSize',8) 
    fill([0:hor-1 fliplr(0:hor-1)]' ,[HighIRF(:,1+n*k-n); flipud(LowIRF(:,1+n*k-n))],...
        colorBNDS,'EdgeColor','k'); hold on;
    alpha(.20)
    plot(0:hor-1,MiddleIRF(:,1+n*k-n),'LineWidth',1.5,'Color','k','LineStyle','-.'); hold on;
    xlim([0 hor-1]);
    line(get(gca,'xlim'),[0 0],'Color',[1 0 0],'LineStyle','-','LineWidth',1); hold off;
    ax = gca;
    xlabel(ax, VARnames{k}, 'FontSize', 14);  % bigger label
    ax.XAxis.FontSize = 14;  
    ax.YAxis.FontSize = 14;  % tick labels bigger
    ytickformat('%.1f')   % <<< NEW: format y-axis labels to 1 decimal
   
  
end

% Adjust subplot spacing to reduce gaps
% This is the key improvement - manually adjust all subplot positions
h = get(gcf, 'Children');
subplots = h(strcmp(get(h, 'Type'), 'axes'));

% Sort subplots by position to identify rows and columns
positions = cell2mat(get(subplots, 'Position'));
[~, idx] = sortrows(positions, [2, 1]); % Sort by y-position first, then x-position
subplots = subplots(idx);

% Adjust margins and spacing for 5 columns instead of 6
left_margin = 0.04; % Reduced from default ~0.13
right_margin = 0.01; % Reduced from default ~0.05
top_margin = 0.08; % Space for title
bottom_margin = 0.08; % Space for x-labels
horizontal_gap = 0.03; % Gap between subplots (slightly larger for 5 plots)
vertical_gap = 0.16; % Gap between rows (for titles)

% Calculate subplot dimensions for 5 columns
subplot_width = (1 - left_margin - right_margin - 4*horizontal_gap) / 6; % 4 gaps for 5 plots
subplot_height = (1 - top_margin - bottom_margin - vertical_gap) / 2;

% Reposition all subplots
for i = 1:length(subplots)
    if i <= 6 % First row
        row = 1;
        col = i;
        y_pos = 1 - top_margin - subplot_height;
    else % Second row
        row = 2;
        col = i - 6;
        y_pos = bottom_margin;
    end
    
    x_pos = left_margin + (col-1) * (subplot_width + horizontal_gap);
    
    set(subplots(i), 'Position', [x_pos, y_pos, subplot_width, subplot_height]);
end

% Add titles with adjusted positions for reduced margins - INVERTED LABELS
axes('position', [0.06 0.49 0.92 0.5], 'visible', 'off');
text(0.5, 0.96, '(a) Surprise shock', 'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold');

axes('position', [0.06 -0.005 0.92 0.5], 'visible', 'off');
text(0.5, 0.96, ' (b) News shock', 'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold');

% For high-quality PNG (recommended)
print(gcf, 'your_filename.png', '-dpng', '-r300');

% For PDF (vector graphics, good for publications)
print(gcf, 'your_filename.pdf', '-dpdf', '-fillpage');

% For EPS (vector graphics)
print(gcf, 'your_filename.eps', '-depsc2');

% Alternative: use exportgraphics (MATLAB R2020a+)
exportgraphics(gcf, 'your_filename.png', 'Resolution', 300);
end