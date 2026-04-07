function [factor] = get_factors(kmax,start_sample,end_sample)

DEMEAN=2;
jj=2;

% Path: Data/FRED-QD.csv relative to the Functions folder parent directory
func_dir = fileparts(mfilename('fullpath'));
csv_in   = fullfile(func_dir, '..', 'Data', 'FRED-QD.csv');
% uploading McCracken and Ng dataset

dum=importdata(csv_in,',');
tcode=dum.data(2,:);
rawdata=dum.data(2:end,:);

final_datevec=datevec(end_sample);
final_month=final_datevec(2);

initial_datevec = datevec(start_sample);
initial_month=initial_datevec(2);

if final_month == 3
final_quarter=1;
elseif final_month == 6
final_quarter=2;  
elseif final_month == 9
final_quarter=3;
elseif final_month == 12
final_quarter=4;  
end

if initial_month == 3
initial_quarter=1;
elseif initial_month == 6
initial_quarter=2;  
elseif initial_month == 9
initial_quarter=3;
elseif initial_month == 12
initial_quarter=4;  
end

final_year=final_datevec(1);
initial_year =initial_datevec(1);
dates = (initial_year+(initial_quarter-2)/4:1/4:final_year+final_quarter/4)';
T=size(dates,1);
rawdata=rawdata(1:T,:);
yt=prepare_missing(rawdata,tcode);
yt=yt(3:T,:);
[data_factor,~]=remove_outliers(yt);
[~,Fhat,~,~,~] = factors_em(data_factor,kmax,jj,DEMEAN);

factor=Fhat;

end