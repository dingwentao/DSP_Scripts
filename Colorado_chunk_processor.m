%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PARALLELIZABLE SNOW RADAR PROCESSOR
% This script is to process snow radar data block-wise in slow time
% Author: Shashank Wattal
% Version: 9
% Last updated: 06-05-2019
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% data_dir    -   full directory path where the data's stored
% save_dir    -   full directory path where echograms will be saved     
% code_dir    -   full directory path where code is stored
% file0       -   full .mat filename to be processed
% chunk_size  -   no. of slow time columns in each chunk
% saveFig     -   save .fig, off by default
% saveJpg     -   save .jpg, off by default

% data_dir =  'K:\Colorado_1';  
% save_dir =  data_dir;       
% code_dir =  'J:\RSC\Colorado processing\';
% file0    =  '20190323_145711_MicrowaveRadar2019_CO_0000';
% chunk_size  =  64;         

% Multiple modes supported - processed and saved separately
% Error handling is specific to GrandJunction 2019 filename format
% Params are hard-coded for Grand Junction 2019
% Run single files only
% chunk_size defaults to # cols, for most cases
% render_on defaults to 0
% Calls ColoradoProcessorF1.m to process each chunk
% File path parser assumes Windows or Linux OS
% Saved results consist of echogram only; phase information isn't preserved
% Overwrites, if an output file is already present
% Assumes deconvolution vector (syscorr) is the same for all modes
% Assumes syscorr's length is equal to number of rows in data matrix

function [] = Colorado_chunk_processor(data_dir, save_dir, code_dir, file0, chunk_size, saveFig, saveJpg)

% error handling 
if (exist(data_dir)~=7 || exist(save_dir)~=7 || exist(code_dir)~=7)    
%     fprintf("\nDirectory not found (data_dir, save_dir, or code_dir) \n");
    return
elseif (length(file0)~=42&&length(file0)~=46)
%     fprintf("\nUnexpected filename format; expected length 42 or 46\n");
    return
end
% operating system 
if isunix      separator = '/';
elseif ispc    separator = '\';
else           return;      end %error('\nExpected OS to be Linux/Windows.'); end
% path
if ~strcmp(data_dir(end), separator) 
    data_dir = [data_dir separator];
end
if ~strcmp(save_dir(end), separator) 
    save_dir = [save_dir separator];
end
if ~strcmp(file0(end-3:end), '.mat') 
    file0 = [file0 '.mat'];
end
if exist([data_dir file0])~=2
%     fprintf("\nNon-existent input file\n");
    return
end
if (floor(chunk_size)~=chunk_size) || chunk_size<2
%     fprintf("\nExpected chunk_size to be an integer >= 2 \n");
    return
end

path(path,code_dir)
% parameters 
params.hN = 8 ;                            % num of Pulses integrated over
params.adc_sampFreq = 1200e6;
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
%     fprintf('\nExpected chunk size larger than %d \n', params.coh_avg_size*params.incoh_avg_size); 
    return
end

% load files    
load([data_dir file0]);
load([data_dir file0(1:end-4) '_counters.mat']);

% pad (to "borrow" columns for averaging at the edges of each chunk)
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
    range0 = f .* (params.pulse_width)/params.BW * c/sqrt(params.eps_r)/2;
    
    % Deconvolution product
    if exist([data_dir 'syscorr.mat'])==2        
        load([data_dir 'syscorr.mat']);
        if (size(Results(jj).Chirps, 1)==length(syscorr))
            Results(jj).Chirps = Results(jj).Chirps.*syscorr;
        end
    end
    
    for ii = 1 : ceil(cols/chunk_size)
        % indices to subset in slow time
        first(ii) = (ii-1)*chunk_size+1;
        last(ii)  = ii*chunk_size; 
        if last(ii)>cols   last(ii)=cols;         end        
        % pad zeros
        if length(num2str(ii))==1        ii_str(ii, :)=['00000' num2str(ii)];
        elseif length(num2str(ii))==2    ii_str(ii, :)=['0000' num2str(ii)];
        elseif length(num2str(ii))==3    ii_str(ii, :)=['000' num2str(ii)];
        elseif length(num2str(ii))==4    ii_str(ii, :)=['00' num2str(ii)];
        elseif length(num2str(ii))==5    ii_str(ii, :)=['0' num2str(ii)];    
        elseif length(num2str(ii))>6     error('Expected number of chunks < 999,999');     
        end
        if first(ii)>D && last(ii)<cols-D
            temp = ColoradoProcessorF1(Results(jj).Chirps(:, first(ii)-D:last(ii)+D), params);                        
            [echogram0(:, first(ii):last(ii))] = temp(:,1+D:end-D);
        else
            [echogram0(:, first(ii):last(ii))] = ColoradoProcessorF1(Results(jj).Chirps(:, first(ii):last(ii)), params);
        end
    end
    
    % Normalize
    echogram0 = echogram0 - max(echogram0(:));

    % Elevation compensation
%     dist0=[];
    [range0, dist0, echogram0, lat0, lon0] = gps_corr(data_dir, file0, 1, echogram0, range0);
              
    % Save echogram matrix
    if size(echogram0, 1)==0 || size(echogram0, 2)==0 
        return; 
    end   
    save_file = [file0(1:end-4) '__mode' num2str(jj-1) '.mat'];
    save_path_data = [save_dir file0(1:end-4) '__mode' num2str(jj-1) '.mat']; % '_chunk' ii_str(ii, :)];
    save(save_path_data, 'echogram0', 'range0', 'dist0', 'params', 'lat0', 'lon0'); 
    
    % Save echogram figures  
    if (saveFig==1 || saveJpg==1)
        Echogram(save_dir, save_file, save_dir, saveFig, saveJpg);
    end        
end


end
