%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SNOW RADAR ECHOGRAM RENDERER
% This script is to plot and save an echogram rendered from saved data
% Author: Shashank Wattal
% Version: 1
% Last updated: 06-04-2019
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% data_dir    -   full directory path where the data's stored
% data_file   -   full name of the data file
% save_dir    -   full directory path where echograms will be saved     
% saveFig     -   save .fig, off by default
% saveJpg     -   save .jpg, off by default

% Assumes the saved .mat data file has the following variables:
% echogram0   -   echogram data matrix (dB)
% range0      -   fast-time range vector (m)
% dist0       -   along-track distance vector (km)
% lat0        -   along-track latitude vector
% lon0        -   along-track longitude vector
% params      -   struct containing parameters (at least params.eps_r)

% caxis hardcoded to [-35 -10], assumes echogram's normalized to a 0 max

function [] = Echogram(data_dir, data_file, save_dir, saveFig, saveJpg)
   
%% error handling 
if (exist(data_dir)~=7 || exist(save_dir)~=7)    
    fprintf("\nEchogram.m directory not found (data_dir or save_dir) \n");
    return
elseif (length(data_file)~=49&&length(data_file)~=53)
    fprintf("\nUnexpected filename format; expected length 49 or 53\n");
    return
end
% operating system 
if isunix      separator = '/';
elseif ispc    separator = '\';
else           error('\nExpected OS to be Linux/Windows.'); end
% paths
if ~strcmp(data_dir(end), separator) 
    data_dir = [data_dir separator];
end
if ~strcmp(save_dir(end), separator) 
    save_dir = [save_dir separator];
end
if ~strcmp(data_file(end-3:end), '.mat') 
    data_file = [data_file '.mat'];
end
if exist([data_dir data_file])~=2
    fprintf("\nNon-existent input file\n");
    return
end

%% save

load([data_dir data_file])

% Adjust vertical axis
[m, i] = max(echogram0, [], 1);
rangeCenter = mean(range0(i));
range0 = range0 - rangeCenter;    

% Debug:
% max(max(echogram0, [], 1))
% max(echogram0(:))
% 
% mean(echogram0(i))
% max(echogram0(i))
% length(find(echogram0>-4.9423))
% figure(); 
%     imagesc(dist0,range0,echogram0); colormap(1-gray); hold on; 
%     plot(dist0, range0(i), 'r.')
%     ylim([-5, 10]);
%     caxis([-35 -10])
    
% mode(range0(i))
% median(range0(i))
% std(range0(i))
% var(range0(i))
% min(range0(i))
% max(range0(i))

% The horizontal axis needs to include lat/lon in addition to along-track distance.


save_path_fig  = [save_dir data_file(1:end-4) '.fig']; 
save_path_jpg  = [save_dir data_file(1:end-4) '.jpg']; 

f1 = figure('visible', 'off');
if length(dist0)==size(echogram0, 2)    
    imagesc(dist0,range0,echogram0);
    xlabel('Along-track distance (km)');
else
    imagesc(dist0,range0,echogram0);
    xlabel('Along-track index');
end
colormap(1-gray);
title([ data_file(1:8) '-' data_file(10:15) '-' data_file(39:42) ]);
ylabel(['Range (m) [\epsilon_r=' num2str(params.eps_r) ']']);
if (range0(1)<=-5) && (range0(end)>=10)
    ylim([-5 10]);
end
caxis([-35 -10]);

if (saveFig==1)     saveas(f1, save_path_fig);   end;
if (saveJpg==1)     saveas(f1, save_path_jpg);   end

end


