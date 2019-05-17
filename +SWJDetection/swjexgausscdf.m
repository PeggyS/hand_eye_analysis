function k=exgausscdf(t,p)
% EXGAUSSCDF The ex-Gaussian cdf
mu=p(1);
sigma=p(2);
tau=p(3);
part1=-exp(-t./tau + mu./tau + sigma.^2./2./tau.^2).*normcdf((t-mu-sigma.^2./tau)./sigma);
part1(part1==Inf)=zeros(length(part1(part1==Inf)),1);
part1(isnan(part1))=zeros(length(part1(isnan(part1))),1);
part2=normcdf((t-mu)/sigma);
%part3=exp(mu/tau + sigma^2/2/tau^2)*normcdf((-mu-sigma^2/tau)/sigma)';
%part3(part3==Inf)=zeros(length(part3(part3==Inf)),1);
%part3(isnan(part3))=zeros(length(part3(isnan(part3))),1);
%part4=-normcdf(-mu/sigma);
%k= part1 + part2 + part3 +part4;
k= part1 + part2;
