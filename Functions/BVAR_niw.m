%%% BVAR - Normal-inverse-Wishart priors

function [PI,BigA,Sigma,errornorm,fittednorm]=BVAR_niw(y,p,c,t,n)

    [Traw,~]=size(y);
    
    T=Traw-p;
    m=n*p+c+t;
    
    [~,Y,X,~,~,~]=VAR(y,p,c,t); %OLS estimate 
       
    % Prior for reduced-form parameters
    nnuBar              = 0;
    OomegaBarInverse    = zeros(m);
    PpsiBar             = zeros(m,n);
    PphiBar             = zeros(n);
    
    % Posterior for reduced-form parameters
    nnuTilde            = T +nnuBar;
    OomegaTilde         = (X'*X  + OomegaBarInverse)\eye(m); % Computing the inverse of (X'*X  + OomegaBarInverse) --> A\eye(n)=A^(-1)
    OomegaTildeInverse  =  X'*X  + OomegaBarInverse; 
    PpsiTilde           = OomegaTilde*(X'*Y + OomegaBarInverse*PpsiBar);
    PphiTilde           = Y'*Y + PphiBar + PpsiBar'*OomegaBarInverse*PpsiBar - PpsiTilde'*OomegaTildeInverse*PpsiTilde;
    PphiTilde           = (PphiTilde'+PphiTilde)*0.5;
    
    cholOomegaTilde = chol(OomegaTilde)';
    
    Sigma = iwishrnd(PphiTilde,nnuTilde);
    cholSigmadraw = chol(Sigma)';
    PI_aux   = kron(cholSigmadraw,cholOomegaTilde)*randn(m*n,1) + reshape(PpsiTilde,n*m,1);
    PI  = reshape(PI_aux,m,n);
    
    
    % Create the companion form representation matrix A:
    
    BigA=[PI(1+c+t:end,:)'; eye(n*p-n) zeros(n*p-n,n)]; % (K*p)x(K*p) matrix
    
    % Store errors and fitted values:
    
    errornorm=Y-X*PI;
    fittednorm=X*PI;
    
end
    
    
    
    
    


