function vardec = vdec(D,hor,n)

MiddleDsquare=D.^2;

denom=zeros(hor,n);

for k=[1:n;1:n:n*n]
    
    denom(:,k(1))=cumsum(sum(MiddleDsquare(:,k(2):k(2)+n-1),2));
    
end

denomtot=zeros(hor,n*n);

for k=[1:n;1:n:n*n]
    
    denomtot(:,k(2):k(2)+n-1)=denom(:,k(1)).*ones(hor,n);
    
end

vardec=zeros(hor,n*n);

for j=1:n*n
    
    vardec(:,j)=cumsum(MiddleDsquare(:,j))./denomtot(:,j);
    
end
