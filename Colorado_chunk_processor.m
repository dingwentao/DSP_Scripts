%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PARALLELIZABLE SNOW DATA PROCESSOR
% This script is to process snow radar data block-wise in slow time
% Author: Shashank Wattal
% Version: 2
% Last updated: 04-27-2019
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% data_dir    -   full directory path where the data's stored
% save_dir    -   full directory path where echograms will be saved     
% code_dir    -   full directory path where code is stored
% file0       -   full .mat filename to be processed
% chunk_size  -   no. of slow time columns in each chunk

% Multiple modes supported
% Run single files only
% In most exception cases, the entire set is processes as a single chunk
% Params are hard-coded for Grand Junction 2019
% Calls ColoradoProcessorF1.m to process each chunk

function [] = Colorado_chunk_processor(data_dir, save_dir, code_dir, file0, chunk_size)
% data_dir =  'K:\Colorado_1';  % full path to data directory
% save_dir =  data_dir;       % full path to save echograms
% code_dir =  'J:\RSC\Colorado processing\'; % full path to script/functions directory
% file0    =  '20190323_145711_MicrowaveRadar2019_CO_0000';
% numFiles =  1; 
% chunk_size  =  64;           % no. of slow time columns in a chunk

path(path,code_dir)
if ~strcmp(data_dir(end), '/') 
    data_dir = [data_dir '/'];
end
if ~strcmp(save_dir(end), '/') 
    save_dir = [save_dir '/'];
end
if ~strcmp(file0(end-3:end), '.mat') 
    file0 = [file0 '.mat'];
end

% parameters 
params.hN = 8 ;                            % num of Pulses integrated over
params.adc_sampFreq = 1200*10^6;
params.dec = 4*4;                        %Decimation
params.coh_avg_size = 4;           % coherent averaging
params.incoh_avg_size = 4;
params.NumPoints = 60000;
params.dac_sampFreq = 2400e6;
params.pulse_width = params.NumPoints/params.dac_sampFreq;
params.chirp_rate = 4e9/params.pulse_width;
params.gps_path = [data_dir file0(1:15) '_ARENA__CTU-CTU-gps.txt'];
params.Fs = 1200e6/4/4;

if chunk_size <= params.coh_avg_size*params.incoh_avg_size
    error('Expected chunk size larger than product of coherent average size and incoherent average size!'); 
end
    
load([data_dir file0]);
load([data_dir file0(1:end-4) '_counters.mat']);
chunk_size = floor(chunk_size);
r = size(Results(1).Chirps, 1);
c = size(Results(1).Chirps, 2);
if (c < chunk_size || chunk_size <= 0)
    chunk_size = c; 
end
% range axis
f = params.Fs/2 * linspace(-1,1,r);
f = f+148e6;
range1 = f .* 180e-6/8e9 * 3e8/sqrt(1)/2;
% pad
D = 2*params.coh_avg_size;

%%
% mode number jj
for jj=1:size(Results, 2)
    if size(Results(jj).Chirps, 2)==0
        continue
    end    
    for ii = 1 : ceil(c/chunk_size)
        % indices to subset in slow time
        first(ii) = (ii-1)*chunk_size+1;
        last(ii) = ii*chunk_size; 
        if last(ii)>c
            last(ii)=c; 
        end        
        % pad zeros
        if length(num2str(ii))==1        ii_str(ii, :)=['00000' num2str(ii)];
        elseif length(num2str(ii))==2    ii_str(ii, :)=['0000' num2str(ii)];
        elseif length(num2str(ii))==3    ii_str(ii, :)=['000' num2str(ii)];
        elseif length(num2str(ii))==4    ii_str(ii, :)=['00' num2str(ii)];
        elseif length(num2str(ii))==5    ii_str(ii, :)=['0' num2str(ii)];    
        elseif length(num2str(ii))>6     error('Expected number of chunks < 999,999');     
        end
        if first(ii)>D && last(ii)<c-D
            temp = ColoradoProcessorF1(Results(jj).Chirps(:, first(ii)-D:last(ii)+D), params);
            [echogram(:, first(ii):last(ii))] = temp(:,1+D:end-D);
        else
            [echogram(:, first(ii):last(ii))] = ColoradoProcessorF1(Results(jj).Chirps(:, first(ii):last(ii)), params);
        end
    end
    % save full echogram    
    save_path_fig  = [save_dir file0(1:end-4) '__mode' num2str(jj-1) '.fig']; % '_chunk' ii_str(ii, :)];
    save_path_jpg  = [save_dir file0(1:end-4) '__mode' num2str(jj-1) '.jpg']; % '_chunk' ii_str(ii, :)];
    save_path_data = [save_dir file0(1:end-4) '__mode' num2str(jj-1) '.mat']; % '_chunk' ii_str(ii, :)];
    f1 = figure('visible', 'off');
    imagesc([],range1,echogram)
    colormap(1-gray)
    title([ file0(1:8) '-' file0(10:15) '-' file0(39:42) ])
    ylabel('Range (m) [\epsilon_r=1]')
    xlabel('Along-track index')
    saveas(f1, save_path_fig)
    saveas(f1, save_path_jpg)
    save(save_path_data, 'echogram', 'range1'); 
end


end
