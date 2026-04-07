function irf_plot_percentiles(n,q,hor,MiddleIRF,HighIRF,LowIRF,VARnames,colorBNDS)

% Plot IRFs of VAR(p)

set(0,'defaultAxesFontName', 'Times');
set(0,'defaultAxesLineStyleOrder','-|--|:', 'defaultLineLineWidth',1.5)

figure;

idx = [1 3 5 2 4 6]';

for k=1:9 % variable k
 for j=1 % shock j
    subplot(3,2,idx(k-6))
        %fill([0:hor-1 fliplr(0:hor-1)]' ,[HighIRF90(:,j+n*k-n); flipud(LowIRF90(:,j+n*k-n))],...
        %colorBNDS90,'EdgeColor','None'); hold on;
        %alpha(.35)    
    fill([0:hor-1 fliplr(0:hor-1)]' ,[HighIRF(:,j+n*k-n); flipud(LowIRF(:,j+n*k-n))],...
        colorBNDS,'EdgeColor','k'); hold on;
        alpha(.20)
    plot(0:hor-1,MiddleIRF(:,j+n*k-n),'LineWidth',1.5,'Color','k','LineStyle','-.'); hold on;
    xlim([0 hor-1]);
    line(get(gca,'xlim'),[0 0],'Color',[1 0 0],'LineStyle','-','LineWidth',1); hold off;
    xlabel(strcat(VARnames{k}), 'FontSize', 16);
     axis tight
    set(gca,'FontSize',16)
    set(gcf, 'Position', get(0, 'Screensize'))
 end
 if k==7
 text(5.0,1,'(a) Surprise Shock','FontSize',24,'FontName','Times');
 end
end

for k=7:9
 for j=2 % shock j
     subplot(3,2,idx(k-6)+1)
       % fill([0:hor-1 fliplr(0:hor-1)]' ,[HighIRF90(:,j+n*k-n); flipud(LowIRF90(:,j+n*k-n))],...
        %colorBNDS90,'EdgeColor','None'); hold on;
        %alpha(.35)
    fill([0:hor-1 fliplr(0:hor-1)]' ,[HighIRF(:,j+n*k-n); flipud(LowIRF(:,j+n*k-n))],...
        colorBNDS,'EdgeColor','k'); hold on;
        alpha(.20)
    plot(0:hor-1,MiddleIRF(:,j+n*k-n),'LineWidth',1.5,'Color','k','LineStyle','-.'); hold on;
    xlim([0 hor-1]);
    line(get(gca,'xlim'),[0 0],'Color',[1 0 0],'LineStyle','-','LineWidth',1); hold off;
    xlabel(strcat(VARnames{k}), 'FontSize', 16);
    axis tight
    set(gca,'FontSize',16)
    set(gcf, 'Position', get(0, 'Screensize'))
 end
if k==7
 text(5.3,1.65,'(b) News Shock','FontSize',24,'FontName','Times');
 end
end
end



