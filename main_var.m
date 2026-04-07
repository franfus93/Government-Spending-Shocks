%% Importing the data:

clc; 
clear;

data=readtable('data.xlsx');

start_sample = datetime('01-Dec-1981','InputFormat','dd-MMM-yyyy');
end_sample   = datetime('01-Dec-2019','InputFormat','dd-MMM-yyyy');

idx_start = find(data.TIME == start_sample);
idx_end   = find(data.TIME == end_sample);

F = data(idx_start:idx_end,2); % Measure 1 in FG2016
N = data(idx_start:idx_end,3); % Measure 2 in FG2016
FEDGOV = data(idx_start:idx_end,4); % Real government consumption expenditures and gross investment
GDP = data(idx_start:idx_end,5); % Real GDP
CONS = data(idx_start:idx_end,6); % Real consumption
SUR = data(idx_start:idx_end,7); % Federal surplus
NX = data(idx_start:idx_end,8); % Net exports
BONDY = data(idx_start:idx_end,9); % Market yield on US Treasury securities at 10-year constant maturity
RER = data(idx_start:idx_end,10); % Real exchange rate
C_SD_LNCONS_SA = data(idx_start:idx_end,11); % Cross-sectional standard deviation of real consumption across US households
C_9010_LNCONS_SA = data(idx_start:idx_end,12); % Interpercentile range 90 - 10
C_9050_LNCONS_SA  = data(idx_start:idx_end,13); % Interpercentile range 90 - 50
C_5010_LNCONS_SA  = data(idx_start:idx_end,14); % Interpercentile range 50 - 10
GINI_COEFFICIENT = data(idx_start:idx_end,15); % Gini coefficient
FED_FUNDS = data(idx_start:idx_end,16); % Federal funds rate
SHADOW_RATE = data(idx_start:idx_end,17); % Shadow rate
SP500 = data(idx_start:idx_end,18); % Stock prices
GDP_DEFLATOR = log(data(idx_start:idx_end,19)); % GDP deflator
CPI = log(data(idx_start:idx_end,20)); % CPI
CPI_INFLATION = data(idx_start:idx_end,21); % CPI Inflation
BCI = data(idx_start:idx_end,22); % BCI
CCI = data(idx_start:idx_end,23); % CCI
REALEARNINGS= data(idx_start:idx_end,24); % CCI
RAMEY= data(idx_start:idx_end,25); % CCI
INVESTMENT= data(idx_start:idx_end,26); % CCI
NBIG= data(idx_start:idx_end,27); % CCI
FP= data(idx_start:idx_end,28); % CCI
UNRATE= data(idx_start:idx_end,29); % CCI
CP = data(idx_start:idx_end,30); % CCI
CP_before = data(idx_start:idx_end,31); % CCI
CP_corp = data(idx_start:idx_end,32); % CCI
DURABLE= data(idx_start:idx_end,33); % CCI
NONDURABLE = data(idx_start:idx_end,34); % CCI
CP_REAL = data(idx_start:idx_end,35); % CCI
F2 = data(idx_start:idx_end,36); % CCI
COONS = data(idx_start:idx_end,37); % CCI

%% Estimating the factors

opt.r=9; % setting the maximum number of factors to be estimated
opt.p=4; % # of lags
opt.c=1; % include constant
opt.t=0; % include deterministic trend
opt.drawfin=5000;
opt.hor=17; %number of horizons for the impulse responses

factor = get_factors(opt.r,start_sample,end_sample); % estimating r factors from McCracken and Ng dataset

%% Cleaning N or F

p_factor = 0;
% factor_lag = lagmatrix( factor(:,1:7), 1:p_factor);
% auxiliary = [(factor_lag(p_factor+1:end,:)),table2array(N(p_factor+1:end,:))];
% auxiliary_table = array2table(auxiliary);
% mdl  = fitlm(auxiliary_table);
% N_clean = mdl.Residuals.Raw;

%% Defining the FAVAR model,
% F_clean =array2table(F_clean);
macro_data=([FEDGOV.FEDGOV(p_factor+1:end),F.F(p_factor+1:end), COONS.DPCERA3M086SBEA(p_factor+1:end), SUR.SUR(p_factor+1:end), BONDY.x10YBOND(p_factor+1:end),RER.RER(p_factor+1:end),CP_REAL.CP_REAL(p_factor+1:end) ,FED_FUNDS.FED_FUNDS(p_factor+1:end),CCI.CSCICP03USM665S(p_factor+1:end), C_9010_LNCONS_SA.C_9010_LNCONS_SA(p_factor+1:end)]); 
VARnames={'Government Spending';'$F_t(1,4)$';'Real GDP';'Federal Surplus';'Bond Yield';   'Real Exchange Rate';'Corporate Profits';'Fed Funds Rate';'Consumer Confidence';'Consumption inequality'};
% 
% macro_orthogonality=([FEDGOV.FEDGOV(p_factor+1:end), GDP.GDP(p_factor+1:end), BONDY.x10YBOND(p_factor+1:end),SUR.SUR(p_factor+1:end),RER.RER(p_factor+1:end),CP_REAL.CP_REAL(p_factor+1:end) ,FED_FUNDS.FED_FUNDS(p_factor+1:end),CCI.CSCICP03USM665S(p_factor+1:end), C_SD_LNCONS_SA.C_SD_LNCONS_SA(p_factor+1:end)]); 
% opt.q=size(macro_orthogonality,2); %number of variables excluding the factors
% [mdl_suff_surprise,mdl_suff_news] = check_orthogonality(macro_orthogonality,factor,opt);
opt.q=size(macro_data,2);
vardata = [macro_data];
%vardata = macro_data;


%% Estimating a Bayesian VAR(4):
[opt.T,opt.n]=size(vardata);


% Set up the loop for each draw :

PI=zeros(opt.n*opt.p+opt.c+opt.t,opt.n,opt.drawfin);
BigA=zeros(opt.n*opt.p,opt.n*opt.p,opt.drawfin);
Sigma=zeros(opt.n,opt.n,opt.drawfin);
errornorm=zeros(opt.T-opt.p,opt.n,opt.drawfin);
fittednorm=zeros(opt.T-opt.p,opt.n,opt.drawfin);



for i=1:opt.drawfin
    
    stable=-1;
    
    while stable<0
    
    % Selecting the priors for the reduced-form estimation    
    [PI(:,:,i),BigA(:,:,i),Sigma(:,:,i),errornorm(:,:,i),fittednorm(:,:,i)]=BVAR_niw(vardata,opt.p,opt.c,opt.t,opt.n);
    %[PI(:,:,i),BigA(:,:,i),Sigma(:,:,i),errornorm(:,:,i),fittednorm(:,:,i)]=BVAR_jeffrey(vardata,opt.p,opt.c,opt.t,opt.n);    
    if abs(eig(BigA(:,:,i)))<1
        stable=1; % keep only stable draws
    end
    
    end
    
end

%% SVAR


candidateirf=zeros(opt.n,opt.n,opt.hor,opt.drawfin); %candidate impulse response

% Set up 4-D matrices for IRFs to be filled in the loop:

C=zeros(opt.n,opt.n,opt.hor,opt.drawfin); 
D=zeros(opt.n,opt.n,opt.hor,opt.drawfin);

% Structural shocks:

eta=zeros(opt.T-opt.p,opt.n,opt.drawfin);

opt.h = waitbar(0,'Wait...');

for k=1:opt.drawfin

for j=1:opt.hor
    BigC=BigA(:,:,k)^(j-1);
    C(:,:,j,k)=BigC(1:opt.n,1:opt.n); % IRFs of the Wold representation
end

% Cholesky factorization:

S=chol(Sigma(:,:,k),'lower'); % lower triangular matrix

for i=1:opt.hor
    D(:,:,i,k)=C(:,:,i,k)*S; % Cholesky IRFs
end


    for i=1:opt.hor
            candidateirf(:,:,i,k)=D(:,:,i,k);
    end
    
    eta(:,:,k)=(squeeze(candidateirf(:,:,1,k))\errornorm(:,:,k)')';

    news_shocks(:,k)=eta(:,2,k);
    gov_spending_shocks(:,k)=eta(:,1,k);
    
    waitbar(k/opt.drawfin,opt.h,sprintf('Percentage completed %2.2f',(k/opt.drawfin)*100))

end

%% Reshape the matrices into a 3D object:

% For each draw, compute a matrix with the IRFs for each variable and each
% shock for the entire horizon considered, i.e. hor x n*n for the # of
% draws:

candidateirf_wold=zeros(opt.hor,opt.n*opt.n,opt.drawfin); 

for k=1:opt.drawfin
    
candidateirf_wold(:,:,k)=(reshape(permute(candidateirf(:,:,:,k),[3 2 1]),opt.hor,opt.n*opt.n,[]));

end

% Create Probability Bands (confidence sets):

conf_narrow=68;
conf_large=90;

LowD=zeros(opt.hor,opt.n*opt.n);
LowD90=zeros(opt.hor,opt.n*opt.n);
MiddleD=zeros(opt.hor,opt.n*opt.n);
HighD=zeros(opt.hor,opt.n*opt.n);
HighD90=zeros(opt.hor,opt.n*opt.n);

for k=1:opt.n
 for j=1:opt.n
        Dmin = prctile(candidateirf_wold(:,j+opt.n*k-opt.n,:),(100-conf_narrow)/2,3); %16th percentile
        LowD(:,j+opt.n*k-opt.n) = Dmin; %lower band
        Dmin90 = prctile(candidateirf_wold(:,j+opt.n*k-opt.n,:),(100-conf_large)/2,3); %16th percentile
        LowD90(:,j+opt.n*k-opt.n) = Dmin90; %lower band
        Dmiddle=prctile(candidateirf_wold(:,j+opt.n*k-opt.n,:),50,3); %50th percentile
        MiddleD(:,j+opt.n*k-opt.n) = Dmiddle; %lower band
        Dmax = prctile(candidateirf_wold(:,j+opt.n*k-opt.n,:),(100+conf_narrow)/2,3); %84th percentile
        HighD(:,j+opt.n*k-opt.n) = Dmax; %upper band
        Dmax90 = prctile(candidateirf_wold(:,j+opt.n*k-opt.n,:),(100+conf_large)/2,3); %84th percentile
        HighD90(:,j+opt.n*k-opt.n) = Dmax90; %upper band
 end
end

% % Create Cumulative Probability Bands (confidence sets):
% 
% LowDlvl=zeros(opt.hor,opt.n*opt.n);
% LowD90lvl=zeros(opt.hor,opt.n*opt.n);
% MiddleDlvl=zeros(opt.hor,opt.n*opt.n);
% HighDlvl=zeros(opt.hor,opt.n*opt.n);
% HighD90lvl=zeros(opt.hor,opt.n*opt.n);
% 
% for k=1:opt.n
%  for j=1:opt.n
%         Dmin = prctile(cumsum(candidateirf_wold(:,j+opt.n*k-opt.n,:),1),(100-conf_narrow)/2,3); %16th percentile
%         LowDlvl(:,j+opt.n*k-opt.n) = Dmin; %lower band
%         Dmin90 = prctile(cumsum(candidateirf_wold(:,j+opt.n*k-opt.n,:),1),(100-conf_large)/2,3); %16th percentile
%         LowD90lvl(:,j+opt.n*k-opt.n) = Dmin90; %lower band
%         Dmiddle=prctile(cumsum(candidateirf_wold(:,j+opt.n*k-opt.n,:),1),50,3); %50th percentile
%         MiddleDlvl(:,j+opt.n*k-opt.n) = Dmiddle; %lower band
%         Dmax = prctile(cumsum(candidateirf_wold(:,j+opt.n*k-opt.n,:),1),(100+conf_narrow)/2,3); %84th percentile
%         HighDlvl(:,j+opt.n*k-opt.n) = Dmax; %upper band
%         Dmax90 = prctile(cumsum(candidateirf_wold(:,j+opt.n*k-opt.n,:),1),(100+conf_large)/2,3); %84th percentile
%         HighD90lvl(:,j+opt.n*k-opt.n) = Dmax90; %upper band
%  end
% end

% Plot the IRFs:


%VARnames_var={'Government Spending';'News Variable';'GDP';'10-year Treasury Yield';'Federal Surplus';'Real Exchange Rate';'Stock Prices';'Fed Funds Rate';'CPI Inflation';'Consumption Inequality'};

% Shocknames={'Anticipated government spending shock';'Unanticipated government spending shock'};
% 
colorBNDS90=[0 0 1];
colorBNDS=[0 0 1];
% 
% % Plotting the IRFs for all the variables to anticipated and unanticipated government spending shocks
% %irf_plot(opt.n,opt.q,opt.hor,MiddleD,HighD,LowD,VARnames,colorBNDS)
% %irf_plot_inequality(opt.n,opt.q,opt.hor,MiddleD,HighD,LowD,VARnames,colorBNDS)
irf_plot_var_full(opt.n,opt.q,opt.hor,MiddleD,HighD,LowD,HighD90,LowD90,VARnames,colorBNDS)
% 
% 
% % names_percentiles={'Government Spending';'News';'GDP'};
% % irf_plot_percentiles(n,q,hor,MiddleD,HighD,LowD,names_percentiles,colorBNDS)
% 
% % %% median_news_shock = zeros(149,1);
% % 
% % for i=1:149 
% %     median_news_shock(i) = prctile(eta(i,2,:),50); 
% % end
% % 
% % h=transpose(1982.75:0.25:2019.75);
% % 
% % figure; 
% % plot(h,median_news_shock,'k'); 
% % hold on 
% % xline(1986)
% % text(1986,-3,'(1)','Color','red',FontSize=30) 
% % hold on 
% % xline(1989.75)
% % text(1989.75,-2,'(2)','Color','red',FontSize=30) 
% % hold on 
% % xline(2001.75)
% % text(2001.75,2,'(3)','Color','blue',FontSize=30) 
% % hold on 
% % xline(2009)
% text(2009,2,'(4)','Color','blue',FontSize=30) 
% set(gca,'FontSize',42) 
% axis tight
% 
% for i=1:149 
%     surprise_news_shock(i) = prctile(eta(i,1,:),50); 
% end
% 
% h=transpose(1982.75:0.25:2019.75);
% 
% figure; 
% plot(h,surprise_news_shock,'k'); 
% hold on 
% % xline(1986)
% % text(1986,-3,'(1)','Color','red',FontSize=30) 
% % hold on 
% xline(1983.75)
% text(1983.75,-2.5,'(1)','Color','red',FontSize=30) 
% hold on 
% xline(1994.5)
% text(1994.5,2.5,'(2)','Color','blue',FontSize=30) 
% hold on 
% xline(1999.75)
% text(1999.75,2,'(2)','Color','blue',FontSize=30) 
% set(gca,'FontSize',42) 
% axis tight