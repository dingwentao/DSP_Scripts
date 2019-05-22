%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This script is to parse raw GPS data
% 
% Author: Christopher Simpson
% Last Modified by: Mahbub
% Version: 2.0
% Last updated: 05-03-2019
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function gps_data = parse_gps_data( file_path )



file_lines = fileread( file_path );
lines = strsplit(file_lines, '\n');

% parse ppsCntr and relTimeCntr
key2= 'ppsCntr';
pps_match = strncmp(lines, key2, length(key2));
ppsCn_lines= lines(pps_match);
num_ppsCn_lines = length(ppsCn_lines);

key3= 'relTimeCntr';
realTime_match = strncmp(lines, key3, length(key3));
realTime_lines= lines(realTime_match);                                              
num_realTime_lines = length(realTime_lines);

for i = 1:num_ppsCn_lines
    line_pps = char(ppsCn_lines{i});
    split_line_pps = strsplit(line_pps, ':');
    gps_data.ppsCntr(i) = (str2double(split_line_pps{2}));
    
    %RealTime
     line_realTime = char(realTime_lines{i});
    split_line_realTime = strsplit(line_realTime, ':');
    gps_data.relTimeCntr(i) = (str2double(split_line_realTime{2}));
end
% parsing ppsCntr and relTimeCntr completed


key = 'nmea:$GPGGA';
match = strncmp(lines, key, length(key));

nmea_gpgga_lines = lines(match);

num_lines = length(nmea_gpgga_lines);

for i = 1:num_lines
    line = nmea_gpgga_lines{i};
    split_line = strsplit(line, ',');
    gps_data.utc_time(i) = str2double(split_line{2});
    gps_data.seconds_since_start(i) = utc2sec(gps_data.utc_time(i))-utc2sec(gps_data.utc_time(1));
    
    gps_data.latitude(i) = degmin2deg(str2double(split_line{3}));
    if split_line{4} == 'S'
        gps_data.latitude(i) = -gps_data.latitude(i);
    end
    
    gps_data.longitude(i) = degmin2deg(str2double(split_line{5}));
    if split_line{6} == 'W'
        gps_data.longitude(i) = -gps_data.longitude(i);
    end
    
    gps_data.fix_quality(i) = str2double(split_line{7});
    gps_data.num_satellites(i) = str2double(split_line{8});
    gps_data.position_dilution(i) = str2double(split_line{9});
    gps_data.altitude(i) = str2double(split_line{10});
    gps_data.geoid_height(i) = str2double(split_line{12});
end

% gps_data = nmea_lines;

end

function sec = utc2sec( t )
    hour = floor(t/10000);
    minute = floor((t-hour*10000)/100);
    second = floor((t-hour*10000-minute*100));
    sec = second + minute*60 + hour*3600;
end

function deg = degmin2deg( c )
    d = floor(c/100);
    m = c - (d*100);
    deg = d+m/60;
end