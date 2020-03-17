function [alpha,b] = LSF(V)
N = size(V,1);
b = max(abs(V(:)))/255;
x = V(:,1);
y = V(:,2);
Chi = [x.^2,2*x.*y,y.^2,2*b*x,2*b*y,b^2*ones(N,1)];

opt.issym = true;
X = Chi'*Chi/N;
[alpha,~] = eigs(X,1,'sm',opt);
end