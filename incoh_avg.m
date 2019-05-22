%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This script is to perform incoherent averaging
% 
% Author: Stephen Yan
% Version: 1.0
% Last updated: 9-12-2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [data_out]=incoh_avg(data_in,avg_length)
avg=avg_length;
if avg==0
    data_out=data_in;
else
    [m,n]=size(data_in);
    h = waitbar(0,'Incoherent integration...');
    for ii=1:n
        if ii>avg && ii<n-avg
            data_out(:,ii)=mean(abs(data_in(:,ii-avg:ii+avg)),2);
        else
            data_out(:,ii)=data_in(:,ii);
        end
        waitbar(ii/n)
    end
    close(h)
end