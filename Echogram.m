%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SNOW RADAR ECHOGRAM RENDERER
% This script is to plot and save an echogram rendered from processed snow radar data
% Author: Shashank Wattal
% Version: 3
% Last updated: 06-06-2019
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% data_dir    -   full directory path where the data's stored
% data_file   -   full name of the data file
% save_dir    -   full directory path where echograms will be saved     
% saveFig     -   save .fig, off by default (1 = on, 0 = off)
% saveJpg     -   save .jpg, off by default (1 = on, 0 = off)

% Assumes the saved .mat data file has the following variables:
% echogram0   -   echogram data matrix (dB)
% range0      -   fast-time range vector (m)
% dist0       -   along-track distance vector (km)
% lat0        -   along-track latitude vector
% lon0        -   along-track longitude vector
% params      -   struct containing parame[ters (at least params.eps_r)

% caxis hardcoded to [-35 -10], assumes echogram's normalized to a 0 max
% built for filename format and data hierarchy specific to GrandJunction2019 on IceBox

function [] = Echogram(data_dir, data_file, save_dir, saveFig, saveJpg)
   
%% error handling 
if (exist(data_dir)~=7 || exist(save_dir)~=7)    
%     fprintf("\nEchogram.m directory not found (data_dir or save_dir) \n");
    return
elseif (length(data_file)~=49&&length(data_file)~=53)
%     fprintf("\nUnexpected filename format; expected length 49 or 53\n");
    return
end
% operating system 
if isunix      separator = '/';
elseif ispc    separator = '\';
else           return;          end %error('\nExpected OS to be Linux/Windows.');
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
%     fprintf("\nNon-existent input file\n");
    return
end

%% Render and Save

load([data_dir data_file])
if size(echogram0, 1)<1 || size(echogram0, 2)<1 
    return
end

% Adjust vertical axis
% use highest points of the most significant layer as range center
[m, i]      = max(echogram0, [], 1);
layerTop    = mean(mink(range0(i), ceil(size(echogram0, 2)/10)));
layerBottom = mean(maxk(range0(i), ceil(size(echogram0, 2)/10)));
layerDiff = layerBottom - layerTop;
range0 = range0 - layerTop;  

% add 5 meters above and below range center
YTop    =  -5;
YBottom =  10 + layerDiff; 

save_path_fig  = [save_dir data_file(1:end-4) '.fig']; 
save_path_jpg  = [save_dir data_file(1:end-4) '.jpg']; 

f1 = figure('visible', 'off');
% ST distance axis
stLabel = 'Along-track distance (km)';
if length(dist0)~=size(echogram0, 2)        
    dist0 =[]; 
    stLabel = 'Along-track index';
end
% lat lon axes
if length(lat0)==size(echogram0, 2) && length(lon0)==size(echogram0, 2)
    ax2 = axes('Position',[0.1 .2 .8 0]);
    ax2.XLabel.String = 'Latitude';
    ax2.XTickLabel = round(lat0, 4);
    ax3 = axes('Position',[0.1 .1 .8 0]);
    ax3.XLabel.String = 'Longitude';
    ax3.XTickLabel = round(lon0, 4);
end
% plot
ax1 = axes('Position',[0.1 .3 .8 0.65 ]);
imagesc(ax1, dist0, range0, echogram0);        
caxis([-35 -10]);
colormap(1-gray);
% labels
ax1.XLabel.String = stLabel;
ax1.YLabel.String = ['Range (m) [\epsilon_r=' num2str(params.eps_r) ']'];
title([ data_file(1:8) '-' data_file(10:15) '-' data_file(39:42) ]);
ax1.PlotBoxAspectRatio = [16 9 1];
% scale vertically 
if (range0(1)<=YTop) && (range0(end)>=YBottom)
    ax1.YLim = [YTop YBottom];
end
% save
if (saveFig==1)     saveas(f1, save_path_fig);   end;
if (saveJpg==1)     saveas(f1, save_path_jpg);   end

end


