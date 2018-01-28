function v = vecvel(x,SAMPLING,TYPE)
%--------------------------------------------------------------------
%  FUNCTION vecvel.m
%  (Version 1.1, 25 FEB 01)
%--------------------------------------------------------------------
% INPUT
%   x(1:N,1)     raw data, x-component of the time series
%   x(1:N,2)     raw data, y-component of the time series
%   SAMPLING     sampling rate (e.g., 250 Hz)
%   TYPE         velocity type (1 or 2)
% OUTPUT
%   v(1:N,1)     x-component
%   v(1:N,2)     y-component
%-------------------------------------------------------------
N = length(x);      % length of the time series
v = zeros(N,2);
for k=2:N-1
    switch TYPE
        case 1
            % fast velocity
            v(k,1:2) = SAMPLING/2*[x(k+1,1)-x(k-1,1) x(k+1,2)-x(k-1,2)];    
        case 2
            % slow velocity
            if k>=3 & k<=N-2
                v(k,1:2) = SAMPLING/6*[x(k+2,1)+x(k+1,1)-x(k-1,1)-x(k-2,1) x(k+2,2)+x(k+1,2)-x(k-1,2)-x(k-2,2)];       
            end
    end
end
