function res = american_option_pricer_octave(req)
  % Do some validation
  assert( isnumeric(req.T) && req.T > 0, ...
    'expiry time must be positive, found %s', num2str(req.T) );
  % Execute
  res = struct();
  res.fairValue = ...
    american_option_price_internal(req.S, req.E, req.T, req.r, req.sigma);
end

function [ W ] = american_option_price_internal( S, E, T, r, sigma, config )
%AMERICAN_OPTION_PRICE AMERICAN Binomial method for an American put
% S: asset starting price
% E: exercise price
% T: expiry time
% r: risk-free interest rate
% sigma: volatility
%
% Example:
%     american_option_price(9, 10, 1, 0.06, 0.3)
% 
% Desmond J. Higham, 'NineWays to Implement the Binomial Method for Option
%     Valuation in MATLAB', SIAM REVIEW ,Vol. 44, No. 4, pp. 661–677,
%     http://epubs.siam.org/doi/pdf/10.1137/S0036144501393266
%

M = 100;

dt = T/M;A = 0.5*(exp(-r*dt)+exp((r+sigma^2)*dt));
u = A + sqrt(A^2-1);d = 1/u;p = (exp(r*dt)-d)/(u-d);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Re-usable computations
dpowers = d.^(M:-1:0)';
upowers = u.^(0:M)';
scale1 = p*exp(-r*dt);
scale2 = (1-p)*exp(-r*dt);
% Option values at time T
W = max(E-S*dpowers.*upowers,0);
% Re-trace to get option value at time zero
for i = M:-1:1
  Si = S*dpowers(M-i+2:M+1).*upowers(1:i);
  W = max(max(E-Si,0),scale1*W(2:i+1) + scale2*W(1:i));
end

end
