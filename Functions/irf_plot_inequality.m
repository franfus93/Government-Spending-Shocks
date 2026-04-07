function irf_plot_inequality(n,q,hor,MiddleIRF,HighIRF,LowIRF,VARnames,colorBNDS)

% Create figure with normalized units and initial wide-short size
f = figure('Units','normalized','Position',[0.1 0.2 0.8 0.4]);

% Subplot index (your variable of interest)
plot_indices = 7;

% Store data in the figure UserData for callback access
figData.n = n;
figData.q = q;
figData.hor = hor;
figData.MiddleIRF = MiddleIRF;
figData.HighIRF = HighIRF;
figData.LowIRF = LowIRF;
figData.VARnames = VARnames;
figData.colorBNDS = colorBNDS;
figData.plot_indices = plot_indices;

f.UserData = figData;

% Initial plotting
plotIRFs(f);

% Set callback for resizing
f.SizeChangedFcn = @(src,evt) plotIRFs(src);

end

% ------------------- Callback function -------------------
function plotIRFs(f)
    % Clear previous axes (except the figure itself)
    clf(f);

    data = f.UserData;
    n = data.n; q = data.q; hor = data.hor;
    MiddleIRF = data.MiddleIRF;
    HighIRF = data.HighIRF;
    LowIRF = data.LowIRF;
    VARnames = data.VARnames;
    colorBNDS = data.colorBNDS;
    plot_indices = data.plot_indices;

    k = plot_indices(1);

    % Adjust subplot positions relative to figure
    left = 0.05; bottom = 0.15; width = 0.40; height = 0.7; % width slightly smaller
    gap = 0.1; % horizontal gap between subplots

    % -------- Shock 2 (left subplot) --------
    ax1 = subplot('Position',[left bottom width height]);
    fill([0:hor-1 fliplr(0:hor-1)]' ,[HighIRF(:,1+n*k-n); flipud(LowIRF(:,1+n*k-n))],...
        colorBNDS,'EdgeColor','k'); hold on;
    alpha(0.2)
    plot(0:hor-1,MiddleIRF(:,1+n*k-n),'k-.','LineWidth',1.5);
    line([0 hor-1],[0 0],'Color',[1 0 0],'LineWidth',1)
    ax1.XAxis.FontSize = 32; ax1.YAxis.FontSize = 32; ytickformat('%.1f');
    axis tight; hold off;

    % -------- Shock 1 (right subplot) --------
    ax2 = subplot('Position',[left+width+gap bottom width height]);
    fill([0:hor-1 fliplr(0:hor-1)]' ,[HighIRF(:,2+n*k-n); flipud(LowIRF(:,2+n*k-n))],...
        colorBNDS,'EdgeColor','k'); hold on;
    alpha(0.2)
    plot(0:hor-1,MiddleIRF(:,2+n*k-n),'k-.','LineWidth',1.5);
    line([0 hor-1],[0 0],'Color',[1 0 0],'LineWidth',1)
    ax2.XAxis.FontSize = 32; ax2.YAxis.FontSize = 32; ytickformat('%.1f');
    axis tight; hold off;

    % -------- Titles above subplots --------
    axes('Position',[0 0.85 0.5 0.15],'Visible','off');
    text(0.5,0.5,'(a) Surprise shock','HorizontalAlignment','center','FontSize',32,'FontWeight','bold');

    axes('Position',[0.5 0.85 0.5 0.15],'Visible','off');
    text(0.5,0.5,'(b) News shock','HorizontalAlignment','center','FontSize',32,'FontWeight','bold');
end