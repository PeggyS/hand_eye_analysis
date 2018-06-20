function sac = microsacc(x,vel,VFAC,MINDUR)
%--------------------------------------------------------------------
%  FUNCTION microsacc.m
%  (Version 2.0, 30 NOV 03)
%--------------------------------------------------------------------
%  PLEASE CITE THIS REFERENCE:
%  Engbert, R. & Kliegl, R. (2002) 
%  Microsaccade uncover the orientation of covert attention.
%  Vision Research 43, 1035-1045.
%--------------------------------------------------------------------
% INPUT
%   x(:,1:2)         position vector
%   vel(:,1:2)       velocity vector
%   VFAC             relative velocity threshold
%   MINDUR           minimal saccade duration (number of samples)
% OUTPUT
%   sac(1:num,1)   onset of saccade
%   sac(1:num,2)   end of saccade
%   sac(1:num,3)   peak velocity of saccade
%   sac(1:num,4)   saccade amplitude
%   sac(1:num,5)   angular orientation 
%   sac(1:num,6)   horizontal component (delta x)
%   sac(1:num,7)   vertical component (delta y)
% added by PS
%   sac(1:num,8)   peak velocity horizontal component 
%   sac(1:num,9)   peak velocity vertical component 
%---------------------------------------------------------------------

% 1. Computing thresholds
msdx = sqrt( nanmedian(vel(:,1).^2) - (nanmedian(vel(:,1)))^2 ); % changed to nanmedian - ps
msdy = sqrt( nanmedian(vel(:,2).^2) - (nanmedian(vel(:,2)))^2 ); % changed to nanmedian - ps
radiusx = VFAC*msdx;
radiusy = VFAC*msdy;

% 2. Detecting microsaccades
test = (vel(:,1)/radiusx).^2 + (vel(:,2)/radiusy).^2;
indx = find(test>1);

% 3. Building sequence
N = length(indx); 
sac = [];
nsac = 0;
dur = 1;
a = 1;
k = 1;
while k<N
    if indx(k+1)-indx(k)==1
        dur = dur + 1;
    else
        % duration > MINDUR?
        if dur>=MINDUR
            nsac = nsac + 1;
            b = k;
            sac(nsac,:) = [indx(a) indx(b)];
        end
        a = k+1;
        dur = 1;
    end
    k = k + 1;
end
% last saccade: duration > MINDUR?
if dur>=MINDUR
    nsac = nsac + 1;
    b = k;
    sac(nsac,:) = [indx(a) indx(b)];
end

% 4. Computing saccade parameters
vabs = sqrt( vel(:,1).^2 + vel(:,2).^2 );
for s=1:nsac
    a = sac(s,1);   % begin
    b = sac(s,2);   % end
    [vpeak, indvpeak] = max(vabs(a:b));  % peak velocity ; indvpeak added by PS
	horizvpeak = vel(a+indvpeak-1, 1);		% added by PS
	vertvpeak = vel(a+indvpeak-1, 2);		% added by PS
    ampl = sqrt( (x(a,1)-x(b,1))^2 + (x(a,2)-x(b,2))^2 );  % amplitude
    sac(s,3) = vpeak;
    sac(s,4) = ampl;
    delx = x(b,1)-x(a,1);   % horizontal component
    dely = x(a,2)-x(b,2);   % vertical component
    phi = 180/pi*atan2(dely,delx);   % angular orientation
    sac(s,5) = phi;
    sac(s,6) = delx;
    sac(s,7) = dely;
	% added by PS:
	sac(s,8) = horizvpeak;
	sac(s,9) = vertvpeak;
	
end
