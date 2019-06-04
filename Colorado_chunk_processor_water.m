%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PARALLELIZABLE SNOW DATA PROCESSOR
% This script is to process snow radar data block-wise in slow time
% Author: Shashank Wattal
% Version: 7
% Last updated: 06-01-2019
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% data_dir    -   full directory path where the data's stored
% save_dir    -   full directory path where echograms will be saved     
% code_dir    -   full directory path where code is stored
% file0       -   full .mat filename to be processed
% chunk_size  -   no. of slow time columns in each chunk

% data_dir =  'K:\Colorado_1';  
% save_dir =  data_dir;       
% code_dir =  'J:\RSC\Colorado processing\';
% file0    =  '20190323_145711_MicrowaveRadar2019_CO_0000';
% chunk_size  =  64;         

% Multiple modes supported - processed and saved separately
% Error handling is specific to GrandJunction 2019 filename format
% Run single files only
% In most exception cases, the entire set is processed as a single chunk
% Params are hard-coded for Grand Junction 2019
% Calls ColoradoProcessorF1_water.m to process each chunk

function [] = Colorado_chunk_processor(data_dir, save_dir, code_dir, file0, chunk_size)

% error handling 
if (exist(data_dir)~=7 || exist(save_dir)~=7 || exist(code_dir)~=7)    
    fprintf("\nDirectory not found (data_dir, save_dir, or code_dir) \n");
    return
elseif (length(file0)~=42&&length(file0)~=46)
    fprintf("\nUnexpected filename format; expected length 42 or 46\n");
    return
end
if ~strcmp(data_dir(end), '/') 
    data_dir = [data_dir '/'];
end
if ~strcmp(save_dir(end), '/') 
    save_dir = [save_dir '/'];
end
if ~strcmp(file0(end-3:end), '.mat') 
    file0 = [file0 '.mat'];
end
if exist([data_dir file0])~=2
    fprintf("\nNon-existent input file\n");
    return
end
if (floor(chunk_size)~=chunk_size) || chunk_size<2
    fprintf("\nExpected chunk_size to be an integer >= 2 \n");
    return
end

path(path,code_dir)
% parameters 
params.hN = 8 ;                            % num of Pulses integrated over
params.adc_sampFreq = 1200*10^6;
params.dec = 4*4;                        %Decimation
params.coh_avg_size = 4;           % coherent averaging
params.incoh_avg_size = 4;
params.NumPoints = 432000;
params.dac_sampFreq = 2400e6;
params.pulse_width = params.NumPoints/params.dac_sampFreq;
params.BW = 8e9; 
params.chirp_rate = params.BW/params.pulse_width;
params.gps_path = [data_dir file0(1:15) '_ARENA__CTU-CTU-gps.txt'];
params.Fs = params.adc_sampFreq/params.dec;
params.eps_r = 1.53; % permittivity of snow 
c = 3e8;  % speed of light m/s


if chunk_size <= params.coh_avg_size*params.incoh_avg_size
    fprintf('\nExpected chunk size larger than %d \n', params.coh_avg_size*params.incoh_avg_size); 
    return
end

% load files    
load([data_dir file0]);
load([data_dir file0(1:end-4) '_counters.mat']);

% pad
D = 2*params.coh_avg_size;

%%
% mode number jj
for jj=1:size(Results, 2)
    if size(Results(jj).Chirps, 2)==0||size(Results(jj).Chirps, 1)==0
        continue
    else
        rows = size(Results(jj).Chirps, 1);
        cols = size(Results(jj).Chirps, 2);
        if (cols < chunk_size)            chunk_size = cols;         end
    end    
    % range axis
    f = params.Fs/2 * linspace(-1,1,rows);
    f = f+148e6;        % hardware delay from loopback test
    range1 = f .* (params.pulse_width)/params.BW * c/sqrt(params.eps_r)/2;
    
    % insert deconvolution vector product here?
    % raw data.*syscorr in time domain
    
    for ii = 1 : ceil(cols/chunk_size)
        % indices to subset in slow time
        first(ii) = (ii-1)*chunk_size+1;
        last(ii)  = ii*chunk_size; 
        if last(ii)>cols   last(ii)=cols;         end        
%         display([num2str(first(ii)) '  ' num2str(last(ii))])
        % pad zeros
        if length(num2str(ii))==1        ii_str(ii, :)=['00000' num2str(ii)];
        elseif length(num2str(ii))==2    ii_str(ii, :)=['0000' num2str(ii)];
        elseif length(num2str(ii))==3    ii_str(ii, :)=['000' num2str(ii)];
        elseif length(num2str(ii))==4    ii_str(ii, :)=['00' num2str(ii)];
        elseif length(num2str(ii))==5    ii_str(ii, :)=['0' num2str(ii)];    
        elseif length(num2str(ii))>6     error('Expected number of chunks < 999,999');     
        end
        
        if first(ii)>D && last(ii)<cols-D
            temp = ColoradoProcessorF1_water(Results(jj).Chirps(:, first(ii)-D:last(ii)+D), params);                        
            [echogram0(:, first(ii):last(ii))] = temp(:,1+D:end-D);
        else
            [echogram0(:, first(ii):last(ii))] = ColoradoProcessorF1_water(Results(jj).Chirps(:, first(ii):last(ii)), params);
        end
    end
    
    % Normalize
    echogram0 = echogram0 - max(echogram0(:));

    % Elevation compensation
    %dist=[];
    %[range1, dist, echogram0] = gps_corr(data_dir, file0, 1, echogram0, range1);
              
    % save full echogram    
    if size(echogram0, 1)==0 || size(echogram0, 2)==0 
        return; 
    end 
    %save_path_fig  = [save_dir file0(1:end-4) '__mode' num2str(jj-1) '.fig']; % '_chunk' ii_str(ii, :)];
    %save_path_jpg  = [save_dir file0(1:end-4) '__mode' num2str(jj-1) '.jpg']; % '_chunk' ii_str(ii, :)];
    save_path_data = [save_dir file0(1:end-4) '__mode' num2str(jj-1) '.mat']; % '_chunk' ii_str(ii, :)];
    %f1 = figure('visible', 'on');
    %if length(dist)==size(echogram0, 2)    
    %    imagesc(dist,range1,echogram0);
    %    xlabel('Along-track distance (km)');
    %else
    %    imagesc(dist,range1,echogram0);
    %    xlabel('Along-track index');
    %end
    %colormap(1-gray)
    %title([ file0(1:8) '-' file0(10:15) '-' file0(39:42) ])
    %ylabel('Range (m) [\epsilon_r=1]')
     
    %saveas(f1, save_path_fig)
    %saveas(f1, save_path_jpg)
    save(save_path_data, 'echogram0', 'range1'); 
end


end
