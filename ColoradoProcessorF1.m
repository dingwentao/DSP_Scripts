%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SNOW DATA CHUNK PROCESSOR
% This script is to process each slow-time chunk of snow data
% Author: Shashank Wattal
% Version: 2
% Last updated: 04-27-2019
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [data_incoh_f2] = ColoradoProcessorF1(data_t, p)
    
    [r0, c0] = size(data_t); 
   
    % Convert to frequency domain
    win0 = hanning(r0);
    for ii=1:c0
           data_f(:,ii) = fftshift(fft(data_t(:,ii).*win0, [], 1), 1);

    end
    
    % Coherent noise removal and averaging
    coh_noise = mean(data_f,2);
    data_f    = data_f - 1.*coh_noise;
    if p.coh_avg_size==0
        data_coh_f = data_f;
    else    
        for ii=1:c0                    
            if (ii > p.coh_avg_size) && (ii < c0 - p.coh_avg_size)
                data_coh_f(:,ii) = mean(data_f(:,ii-p.coh_avg_size:ii+p.coh_avg_size),2);
            else
                data_coh_f(:,ii) = data_f(:,ii);
            end
        end    
    end

    data_coh_fN = 20*log10(abs(data_coh_f));
    data_incoh_f1 = data_coh_fN;
    % Incoherent averaging
    if p.incoh_avg_size==0
        data_incoh_f1 = data_coh_fN;
    else    
        for ii=1:c0
            if (ii > p.incoh_avg_size) && (ii < c0 - p.incoh_avg_size)
                data_incoh_f1(:,ii) = mean(data_coh_fN(:,ii-p.incoh_avg_size:ii+p.incoh_avg_size),2);
            else
                data_incoh_f1(:,ii) = data_coh_fN(:,ii);
            end
        end    
    end

    % Median filter
    data_incoh_f2 = data_incoh_f1;
    data_incoh_f2 = medfilt2(data_incoh_f1,[4,4]);
    data_incoh_f2 = data_incoh_f2 - max(data_incoh_f2);
end


