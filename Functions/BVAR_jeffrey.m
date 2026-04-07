%%% BVAR - Diffuse (Jeffrey) priors

function [PI,BigA,Sigma,errornorm,fittednorm,vec_pi_hat]=BVAR_jeffrey(y,p,c,t,n)

    [Traw,~]=size(y);
    
    T=Traw-p;
    m=n*p+c+t;
    
    [pi_hat,Y,X,~,~,err]=VAR(y,p,c,t); %OLS estimate 
    
    S=err'*err; % SSE
    
    % Draw Sigma from IW ~ (S,v), where v = Traw-p-n*p-1
    
    Sigma=iwishrnd(S,T-n*p-1); 
    
    % Compute the Kronecker product Q x inv(X'X) and vectorize the matrix
    % pi_hat in order to obtain vec(pi_hat):
    
    XX=kron(Sigma,inv(X'*X)); 
    s=size(pi_hat)';
    vec_pi_hat = reshape(pi_hat,s(1)*s(2),1);
    
    % Draw PI from a multivariate normal distribution with mean vec(pi_hat)
    % and variance Q x inv(X'X):
    
    PI=mvnrnd1(vec_pi_hat,XX,1);
    PI=PI';
    PI=reshape(PI,[m,n]); % reshape PI such that Y=X*PI+e, i.e. PI is (K*p+c)x(K).
    
    % Create the companion form representation matrix A:
    
    BigA=[PI(1+c+t:end,:)'; eye(n*p-n) zeros(n*p-n,n)]; % (K*p)x(K*p) matrix
    
    % Store errors and fitted values:
    
    errornorm=Y-X*PI;
    fittednorm=X*PI;
    
end
    
    
    
    
    


