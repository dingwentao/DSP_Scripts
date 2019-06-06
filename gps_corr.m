%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% GPS Correction
% Inputs
% 1. data_dir: Data Directory (assuming each data directory contains it's own gps file (as in icebox))
% 2. first_filename: First Data File Name 
% 3. num_files: Number of Files to be concatenated to generate one Echogram
% 4. data: The Processed Echogram (without elev correction) data variable 
% 5. range: Range Vector
% Output:
% 1.range_axis (Adjusted range vector (m))
% 2.dist (Along Track Distance (km))
% 3.elev_corr (Elevation compensated Echogram Data matrix)
% 
% This code assumes "data.mat" and "counters.mat" are in the same directory
% Written By: Mahbub
% Date: May 18, 2019
%
% Example Inputs:
%
% data_dir = data directory 
% first_filename = '20190320_112538_MicrowaveRadar2019_CO_0000.mat'
% num_files = 10; 
% data = echogram_data;
% range = range_vector;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [range_axis,dist0,elev_corr,lat,lon] = gps_corr(data_dir,first_filename,num_files,data,range)

% Finding gps file in the 'data_dir'
filePattern = fullfile(data_dir, '*.txt'); 
files = dir(filePattern);
% Search for ':' and if exist, show error message

 k = strfind(files(1).name,':');
 if ~isempty(k)       
       fprintf("\nGPS file name contains colon, Rename it with underscore'\n");
       return
 end

  fName = files(1).name;
  fFolder =files.folder;
  fullname = fullfile(fFolder,fName);
  
% Parse gps file

gps = parse_gps_data(fullname);


% Generate 'counters.mat' file names associate with start and ending ...
% ... 'data.mat' file

indexed_name = char(first_filename);
counter = '_counters';
first_counter_file = [indexed_name(1:end-4) counter indexed_name(end-3:end)];
last_index=num2str(str2num(indexed_name(end-7:end-4)) + num_files-1, '%04d');
last_counter_file = [indexed_name(1:end-8) last_index counter indexed_name(end-3:end)];

% find start and ending Lattitude,Longitude and Altitude indices corresponding to this echogram.
% load first counter.mat file 

load([data_dir first_counter_file]);
m=min(find(gps.ppsCntr==Counters.PPS_Counters(1))); 
clear Counters;

% load last counter.mat file 
load([data_dir last_counter_file]);
n=min(find(gps.ppsCntr==Counters.PPS_Counters(end))); 
 
% For each latitude/longitude value there are 3 same ppsCntr value
% This info should be checked in each deployment

idx1=ceil(m/3); 
idx2=floor(n/3); %using floor to ensure not jumping into other files's gps coord.

% Crop in latitude,Longitude & Altitude Vector 
if idx2> idx1
        if (idx1 && idx2)~=0
                gps_lat=gps.latitude(idx1:idx2);
                gps_lon=gps.longitude(idx1:idx2);
                gps_alt=gps.altitude(idx1:idx2);
                
                % Interpolation                
                elev = spline(linspace(1,size(data,2),idx2-idx1+1),gps_alt,...
                        linspace(1,size(data,2),size(data,2)));
                
                lat = spline(linspace(1,size(data,2),idx2-idx1+1),gps_lat,...
                        linspace(1,size(data,2),size(data,2)));
                
                
                lon = spline(linspace(1,size(data,2),idx2-idx1+1),gps_lon,...
                        linspace(1,size(data,2),size(data,2)));
                
                % shift data in fast time
                
                shift_direction = -1;       % MUST BE +1 OR -1! --  changes whether data is shifted up or down
                dr = range(2) - range(1); % Size of each range bin
                
                % Echogram with gps correction
                % Remove white line
                data_in = data;
                
                % Find how many range cell need to be added on top and bottom
                max_elev=max(elev);
                min_elev=min(elev);
                diff_elev=max_elev-min_elev;
                max_range_cell=ceil(diff_elev/dr);
                
                % zero padd the echogram before elev compansation
                data_inP = [ -Inf.*ones(max_range_cell, size(data_in, 2)); data_in; -Inf.*ones(max_range_cell, size(data_in, 2))];
                
                % New range vector
                dR = (range(end)-range(1))/length(range);
                t1=[range(1)-dR   : -dR : range(1)-dR*(max_range_cell-1)];
                t2=[range(end)+dR : dR  : range(end)+dR*(max_range_cell-1)];
                range_axis = [fliplr(t1) range t2];
                
                for ii=1:size(data_in,2)
                        shift_idx(ii)   = round(1*(1/dr)*(elev(ii)-elev(1)));
                        elev_corr(:,ii) = circshift(data_inP(:,ii),shift_direction*shift_idx(ii));
                end
                
                % Convert Along Track indices (slow time) into Distance
                dist0=0;
                for ii=1:length(lat)-1
                        dist0(ii+1) = dist0(ii)+sw_dist([lat(ii) lat(ii+1)],[lon(ii) lon(ii+1)],'km')+0*1e-6;
                end
        end
else
        elev_corr=data;
        range_axis= range;
        dist0=[]; lat=[]; lon=[]; 
end

