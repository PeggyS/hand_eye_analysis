function sac = binsacc(sacl,sacr);
%--------------------------------------------------------------------
%  FUNCTION binsacc.m
%  (Version 2.2, 30 NOV 03)
%--------------------------------------------------------------------
%  PLEASE CITE THIS REFERENCE:
%  Engbert, R. & Kliegl, R. (2002) 
%  Microsaccade uncover the orientation of covert attention.
%  Vision Research 43, 1035-1045.
%--------------------------------------------------------------------
NL = size(sacl,1);   % number of microsaccades (left eye)
NR = size(sacr,1);   % number of microsaccades (right eye)
sac = [];            % define microsaccade matrix
for i=1:NL              % loop over left-eye saccades                  
    l1 = sacl(i,1);     % begin saccade left eye
    l2 = sacl(i,2);     % end saccade left eye
    if NR>0
        R1 = sacr(:,1);    % begin saccade right eye
        R2 = sacr(:,2);    % end saccade right eye
        %==================================================
        % testing for temporal overlap with right eye
        %==================================================
        overlap = find( R2>=l1 & R1<=l2 );    
        if length(overlap)>0
            % define parameters for binocular saccades
            r1 = R1(overlap(1));            
            r2 = R2(overlap(1));  
            vl = sacl(i,3); 
            vr = sacr(overlap(1),3);    
            ampl = sacl(i,4);    
            ampr = sacr(overlap(1),4);    
            dxl = sacl(i,6);
            dyl = sacl(i,7);
            dxr = sacr(overlap(1),6);
            dyr = sacr(overlap(1),7);
            dx = dxl + dxr;
            dy = dyl + dyr;
            phi = 180/pi*atan2(dy,dx);
            s = [min([l1 r1]) max([l2 r2]) ...
                mean([vl vr]) mean([ampl ampr]) ...
                phi mean([dxl dxr]) mean([dyl dyr])];
            % store all binocular saccades 
            sac = [sac; s];   
        end
    end
end

% check, if all saccades are separated by >= 3 samples
nsac = size(sac,1);
k = 1;
while k<nsac
    if sac(k,2)+3<=sac(k+1,1) 
        k = k + 1;;
    else
        sac(k,2) = sac(k+1,2);
        sac(k,3) = max([sac(k,3) sac(k+1,3)]);
        dx1 = sac(k,6);
        dy1 = sac(k,7);
        dx2 = sac(k+1,6);
        dy2 = sac(k+1,7);
        dx = dx1 + dx2;
        dy = dy1 + dy2;
        amp = sqrt( dx^2+dy^2 );
        phi = 180/pi*atan2(dy,dx);
        sac(k,4) = amp;
        sac(k,5) = phi;
        sac(k,6) = dx;
        sac(k,7) = dy;
        sac(k+1,:) = [];
        nsac = nsac - 1;
    end
end

       
        




