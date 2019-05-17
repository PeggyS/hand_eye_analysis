function [square_wave_jerks square_wave_jerks2] = swjs( sacc_starts, sacc_ends, sacc_magnitudes, sacc_directions, blinks, samplerate )
%-------------------------------------------------------------------
%
%  FUNCTION swjs.m
%
%   Detects all the SWJs in a sequence of consecutive saccades
%
%   Distinctive Features of Saccadic Intrusions and Microsaccades in
%   Progressive Supranuclear Palsy. Otero-Millan, Leigh, Serra, Troncoso,
%   Macknik, Martinez-Conde. Journal of Neuroscience (under review).
%   Patent pending.
%
%-------------------------------------------------------------------
%
%  INPUT:
%
%  sacc_starts          start indices of the saccades
%  sacc_ends            end indices of the saccades
%  sacc_magnitudes      magnitude of the saccades
%  sacc_directions      direction of the saccades
%  blinks               binary vector indicating for each sample if it
%                       belons to a blink (1) or not (0)
%  samplrate            samplerate of the data to convert from index to
%                       time
%  OUTPUT:
%
%  square_wave_jerks   	indices of the first saccade of each SWJ
%  square_wave_jerks2   indices of the second saccade of each SWJ
%
%---------------------------------------------------------------------

% find possible square wave jerks

square_wave_jerks = [];
swjindexes = [];

i=0;
while( i < length(sacc_starts)-1 )
    i = i+1;
    [isswj swjindex] = is_possible_swj( i, sacc_starts, sacc_ends, sacc_magnitudes, sacc_directions, blinks, samplerate );
    if ( isswj )
        square_wave_jerks(end+1) = i;
        swjindexes(end+1) = swjindex;
    end
end

% find disjoint SWJs
swj = square_wave_jerks;
square_wave_jerks = [];


i=1;
while (i< length(swj) )
    
    % amount of consecutive square wave jerks
    s = sum( swj(i:end) == swj(i)-1+ [1:length(swj(i:end))] );
    
    % if it is an even number I can chose how to get the swjs
    if ( mod(s,2) == 0 )
        %I select the ones that are smaller in time
        %if ( sum(usacc_ends(swj(i:2:i+s-2)+1)   -   usacc_starts(swj(i:2:i+s-2) )) > sum(usacc_ends(swj(i+1:2:i+s-1)+1)   -   usacc_starts(swj(i+1:2:i+s-1) )))
        if sum((swjindexes(i:2:i+s-2))) > sum((swjindexes(i+1:2:i+s-1)))
            square_wave_jerks = [square_wave_jerks swj(i+1:2:i+s-1) ];
        else
            square_wave_jerks = [square_wave_jerks swj(i:2:i+s-2) ];
        end
        i = i+s;
        % if it is an odd number I do not have election
    elseif ( s==1)
        square_wave_jerks = [square_wave_jerks swj(i:2:i+s-1) ];
        i = i+s;
    else
        if sum((swjindexes(i:2:i+s-1))) > sum((swjindexes(i+1:2:i+s-2)))
            square_wave_jerks =  [square_wave_jerks swj(i:2:i+s-1) ];
            i = i+s;
        else
            square_wave_jerks =  [square_wave_jerks swj(i+1:2:i+s-2) ];
            i = i+s;
        end
    end
end
square_wave_jerks = square_wave_jerks';
square_wave_jerks2 = square_wave_jerks +1;


function [result swjindex] = is_possible_swj( sacc_index, sacc_starts, sacc_ends, sacc_magnitudes, sacc_directions, blinks, samplerate)
% result = is_possible_swj( sacc_index, sacc_starts, sacc_ends, sacc_magnitudes, sacc_directions, blinks)
%
% given the index of a microsaccade decide if that microsaccade and the next could form an square
% wave jerk
%


result = false;
swjindex = 0;

%% no blinks or saccades in between the two microsaccades
if ( sum( blinks( sacc_starts(sacc_index):sacc_ends(sacc_index+1) ) ) > 0 )
	return
end

relmag = (sacc_magnitudes(sacc_index+1) - sacc_magnitudes(sacc_index)) ./ (sacc_magnitudes(sacc_index+1) + sacc_magnitudes(sacc_index));
dirdif = mod(acos(cos((sacc_directions(sacc_index) - sacc_directions(sacc_index+1))*pi/180))*180/pi .* sign((sacc_directions(sacc_index) - sacc_directions(sacc_index+1)))+90,360);
isi = (sacc_starts(sacc_index+1) - sacc_ends(sacc_index)+1)*1000/samplerate;

    DM = [270 270];
    DS = [30 7];
    DR = [0.4 0.6];
    
    RM = [0 0];
    RS = [ 0.39 0.16];
    RR = [0.4 0.6];
    
    ISIP = [125 60 180];

f1 = 1-normcdf( abs(dirdif-DM(1)), 0, DS(1))*DR(1)-normcdf( abs(dirdif-DM(2)), 0, DS(2))*DR(2);
f2 = 1-normcdf( abs(relmag-RM(1)), 0, RS(1))*RR(1)-normcdf( abs(relmag-RM(2)), 0, RS(2))*RR(2);
f3 = ( double(isi>=200).*(1-exgausscdf( isi,ISIP))+double(isi<200).*(exgausscdf( isi, ISIP)));

swjindex = f1*f2*f3;

result = swjindex > 0.0014;
    

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
