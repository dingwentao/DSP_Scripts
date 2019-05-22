%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This script is to perform coherent averaging
% 
% Author: Stephen Yan
% Version: 1.0
% Last updated: 9-12-2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [data_out]=coh_avg(data_in,avg_length)
avg=avg_length;
if avg==0
    data_out=data_in;
else
    
    [m,n]=size(data_in);
    h = waitbar(0,'Coherent integration...');
    for ii=1:n
        %display([num2str(ii) '/' num2str(n)])
        if ii>avg && ii<n-avg
            data_out(:,ii)=mean(data_in(:,ii-avg:ii+avg),2);
        else
            data_out(:,ii)=data_in(:,ii);
        end
        waitbar(ii/n)
    end
    close(h)
end