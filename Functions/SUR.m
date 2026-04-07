function [Y,X,Y_initial]=SUR(data,p,c,t)
% Function that computes Y and X of the SUR representation 
% Author: Nicolo' Maffei Faccioli
%
% Y = X*PI + e
%
% INPUTS: 
% Data: T x n dataset 
% p: number of lags 
% 
% OUTPUTS:
% Y: T x n matrix of the SUR representation
% X: T x (n*p) matrix of the SUR representation

Y=(data(p+1:end,:));

dt=zeros(length(lagmatrix(data,1:p)),1);
dt(:,1)=uint32(1):uint32(length(lagmatrix(data,1:p)));


if c==0 && t==0
 X =[lagmatrix(data,1:p)]; 
elseif c==1 && t==0
    X =[ones(length(lagmatrix(data,1:p)),1) lagmatrix(data,1:p)]; 
elseif c==0 && t==1
    X =[dt lagmatrix(data,1:p)]; 
else
    X =[ones(length(lagmatrix(data,1:p)),1) dt lagmatrix(data,1:p)]; 
end 
    
X(1:p,:)=[];   

% Discarded observations:

Y_initial=data(1:p,:);

end
