%%% Historical decomposition plots:

positive=totdec>=0;
negative=totdec<0;
histdecpos=zeros(size(totdec,1),size(totdec,2));
histdecneg=zeros(size(totdec,1),size(totdec,2));

for t=1:size(totdec,1)
    
    for k=1:size(totdec,2)
    
    if positive(t,k)==1
        
        histdecpos(t,k)=totdec(t,k); 
        
    else, histdecpos(t,k)=NaN;
        
    end
    
    end
    
end

for t=1:size(totdec,1)
    
    for k=1:size(totdec,2)
    
    if positive(t,k)==0
        
        histdecneg(t,k)=totdec(t,k); 
        
    else, histdecneg(t,k)=NaN;
        
    end
    
    end
    
end

figure;

for i=1:n
    
subplot(2,1,i)
b1=bar(dates,histdecpos(:,[i i+n]),'stack');
set(b1(1),'FaceColor',[0 0.4470 0.7410],'EdgeColor','none')
set(b1(2),'FaceColor',[0.8500 0.3250 0.0980],'EdgeColor','none')
hold on;
b2=bar(dates,histdecneg(:,[i i+n]),'stack');
set(b2(1),'FaceColor',[0 0.4470 0.7410],'EdgeColor','none')
set(b2(2),'FaceColor',[0.8500 0.3250 0.0980],'EdgeColor','none')
hold on;
plot(dates,shock_contr(:,i),'-','LineWidth',1.5,'Color',[0.1 0.1 0.1]);hold on;
title(VARnames{i})
set(gca,'FontSize',16)

end

legend(b1,Shocknames,'Interpreter','Latex','Orientation','Horizontal','FontSize',16)


