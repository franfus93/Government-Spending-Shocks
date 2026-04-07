function irf_plot_var_full(n,q,hor,MiddleIRF,HighIRF,LowIRF,HighIRF_large,LowIRF_large,VARnames,colorBNDS)

plot_indices = [1, 2:q]; % Skip variable 2, include variables 1, 3, 4, 5, 6

figure;
for i = 1:q % Now we have 5 plots per row
    
    
    k = plot_indices(i); % Get the actual variable index


     % -------- Shock 2 (first row - News shock) --------
    subplot(4,3,i) % first row of plots, 5 columns
    set(gca,'FontSize',8,'FontName','Times')  
    fill([0:hor-1 fliplr(0:hor-1)]' ,[HighIRF(:,1+n*k-n); flipud(LowIRF(:,1+n*k-n))],...
    colorBNDS,'EdgeColor','k'); hold on;
    % fill([0:hor-1 fliplr(0:hor-1)]' ,[HighIRF_large(:,1+n*k-n); flipud(LowIRF_large(:,1+n*k-n))],...
    % colorBNDS,'EdgeColor','k'); hold on;
    alpha(.20)
    plot(0:hor-1,MiddleIRF(:,1+n*k-n),'LineWidth',1.5,'Color','k','LineStyle','-.'); hold on;
    xlim([0 hor-1]);
    line(get(gca,'xlim'),[0 0],'Color',[1 0 0],'LineStyle','-','LineWidth',1); hold off;
    ax = gca;
    xlabel(ax, VARnames{k}, 'FontSize', 20,'FontName','Times', 'Interpreter', 'latex');  % bigger label
    ax.XAxis.FontSize = 20;  
    axis tight
    ytickformat('%.1f')   % <<< NEW: format y-axis labels to 1 decimal
% -------- Titles above subplots --------
    axes('Position',[0.265 0.9 0.5 0.15],'Visible','off');
    % text(0.5,0.5,'(a) Surprise shock','HorizontalAlignment','center','FontSize',26,'FontWeight','bold');

end
     
 figure;
for i = 1:q% Now we have 5 plots per row

     k = plot_indices(i); % Get the actual variable index

      % -------- Shock 1 (second row - Surprise shock) --------
    subplot(4,3,i) % second row of plots, 5 columns
    set(gca,'FontSize',8,'FontName','Times') 
    fill([0:hor-1 fliplr(0:hor-1)]' ,[HighIRF(:,2+n*k-n); flipud(LowIRF(:,2+n*k-n))],...
    colorBNDS,'EdgeColor','k'); hold on;
    % fill([0:hor-1 fliplr(0:hor-1)]' ,[HighIRF_large(:,2+n*k-n); flipud(LowIRF_large(:,2+n*k-n))],...
    % colorBNDS,'EdgeColor','k'); hold on;
     alpha(.20)
    plot(0:hor-1,MiddleIRF(:,2+n*k-n),'LineWidth',1.5,'Color','k','LineStyle','-.'); hold on;
    xlim([0 hor-1]);
    line(get(gca,'xlim'),[0 0],'Color',[1 0 0],'LineStyle','-','LineWidth',1); hold off;
    ax = gca;
    xlabel(ax, VARnames{k}, 'FontSize', 20,'FontName','Times', 'Interpreter', 'latex');  % bigger label
    ax.XAxis.FontSize = 20;  
    ax.YAxis.FontSize = 20;  % tick labels bigger
    ytickformat('%.1f')   % <<< NEW: format y-axis labels to 1 decimal


    axes('Position',[0.265 0.9 0.5 0.15],'Visible','off');
    % text(0.5,0.5,'(b) News shock','HorizontalAlignment','center','FontSize',26,'FontWeight','bold');

end 
  