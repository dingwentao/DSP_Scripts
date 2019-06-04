%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SNOW DATA CHUNK PROCESSOR
% This script is to process each slow-time chunk of time domain FMCW data
% Author: Shashank Wattal
% Version: 7
% Last updated: 06-01-2019
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% data_t : chunk of time domain data (fast time x slow time)
% p      : parameters stored in a struct
% p.hN   : num of Pulses integrated over
% p.adc_sampFreq : Hz 
% p.dec          : Decimation factor
% p.coh_avg_size : no. of slow time pulses for coherent averaging
% p.incoh_avg_size : slow time pulses for incoherent averaging
% p.NumPoints : no. of fast time samples per pulse
% p.dac_sampFreq : DAC sampling freq Hz
% p.pulse_width = p.NumPoints/p.dac_sampFreq;
% p.chirp_rate = Bandwidth/p.pulse_width;
% p.gps_path = full path to GPS file
% p.Fs = sampling freq for fast time

function [data_f] = ColoradoProcessorF1_water(data_t, p)
   
    [r0, c0] = size(data_t); 
    %    figure(); imagesc(db(fftshift(fft(data_t, [], 1), 1))); colormap(1-gray)
    % Convert to frequency domain
    win0 = hanning(r0);
    data_f = fft(data_t.*win0, [], 1);
    % data_f = fftshift(fft(data_t.*win0, [], 1), 1);
    %     figure(); imagesc(db(data_f)); colormap(1-gray)

    % Coherent noise removal and averaging
    coh_noise = mean(data_f,2);
    data_f    = data_f - 1.*coh_noise;
%     data_coh_f = data_f;
%     figure(); imagesc(db(data_coh_f)); colormap(1-gray)
    if p.coh_avg_size>=1
        for ii=1:c0                    
            if (ii > p.coh_avg_size) && (ii < c0 - p.coh_avg_size)
                data_f(:,ii) = mean(data_f(:,ii-p.coh_avg_size:ii+p.coh_avg_size),2);
            else
                data_f(:,ii) = data_f(:,ii);
            end
        end    
    end
    %     figure(); imagesc(db(data_coh_f)); colormap(1-gray)
    
    % Incoherent averaging
    data_f = 20*log10(abs(data_f));
    if p.incoh_avg_size>=1
        for ii=1:c0
            if (ii > p.incoh_avg_size) && (ii < c0 - p.incoh_avg_size)
                data_f(:,ii) = mean(data_f(:,ii-p.incoh_avg_size:ii+p.incoh_avg_size),2);
            else
                data_f(:,ii) = data_f(:,ii);
            end
        end    
    end
%         figure(); imagesc((data_incoh_f1)); colormap(1-gray)

    % Median filter
    data_f = medfilt2(data_f,[4,4]);
    %     figure(); imagesc((data_incoh_f2)); colormap(1-gray)
%     data_f = data_f - max(data_f(:));
    %     figure(); imagesc((data_incoh_f2)); colormap(1-gray)
       
end


