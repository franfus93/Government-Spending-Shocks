 
function [median_ant_shock, median_unant_shock] = get_shocks(vardata,eta,p)

median_ant_shock = zeros(size(vardata,1)-p,1);
median_unant_shock = zeros(size(vardata,1)-p,1);

for i=1:size(vardata,1)-p
median_ant_shock(i,1) = prctile(eta(i,1,:),50);
median_unant_shock(i,1) = prctile(eta(i,2,:),50);
end

h=1982.75:0.25:2019.75;

figure;
plot(h,median_ant_shock)
title('Anticipated government spending shock')
set(gca,'FontSize',24)
axis tight

figure;
plot(h,median_unant_shock)
title('Unanticipated government spending shock')
set(gca,'FontSize',24)
axis tight

end