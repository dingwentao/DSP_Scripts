function [trace_time, Results] = arena_data_reader_batch (xml_fullpath, dat_fullpath)

%% Code last updated by Zhe Jiang on April 12
fprintf(strcat('starting ',dat_fullpath, '......\n'));

debug_mode = 0;

%% Preparation Phase
% Parse XML file and determine selected range gate to avoid issues with
% ARENA software bug.
[my_modes,my_range_gates,socket_payload_size] = arena_xml_parse(xml_fullpath);

% Define a variable for all results
Results = struct('Mode',{}, 'Chirps',{}, 'Relative_Counters',{}, ...
    'Profile_Counters',{}, 'PPS_Fractional_Counters',{}, ...
    'PPS_Time',{},'PPS_Counters',{}, 'counter',{});
for i = 1:size(my_modes,2)
    Results(i).Mode = my_modes(1,i);
    Results(i).counter = 0;
end

% Set up constant parameters.
data_block_size = socket_payload_size + 32;
sync_word = [0;0;0;128;0;0;128;127];

sync_word = 9187343241983295488;

% Find all *.dat files and *_config.xml files.
dat_file = dir(dat_fullpath);
%radar_data = [];
%pps_time = [];
rel_time = [];

%% Extracting UDP packets and save to a temporary file
% Open radar.dat temporary file.
tmp_fullpath = strcat(dat_fullpath(1:(end-3)),'tmp');
radar_id = fopen(tmp_fullpath , 'w');
if radar_id == -1
    fprintf(strcat('ERROR: count not open temp file ',tmp_fullpath, ' for Writing. Exiting.'));return;
else
    %fprintf('Temporary data file opened.\n');
end

% Reading the .dat file
%   tic
% Open *.dat file.
file_id = fopen(dat_fullpath, 'r');
if file_id == -1
        fprintf('ERROR: could not open %s. Exiting.', dat_fullpath); return;
else
    %fprintf('%s opened for processing.\n', dat_fullpath);

% Calculate the number of data blocks in the *.dat file.
num_data_blocks = dat_file.bytes / data_block_size;

  % instead of reading and writing uint8 (default) we go for writing uint64
  % this significantly speed up the routine
  % No speed up is found when defining a structure beforehand
  % and writing this to disk as one big chunk instead stepwise small of chunks

%     % Assemble radar payloads from this *.dat file.
for j = 1:num_data_blocks
    daq_packet_time_stamp_s = fread(file_id, 1, 'uint');
    daq_packet_time_stamp_us = fread(file_id, 1, 'uint');
    arena_payload_type = fread(file_id, 1, 'uint');
    arena_payload_length = fread(file_id, 1, 'uint');
    arena_id = fread(file_id, 1, 'uint16');
    mezzanine_id = fread(file_id, 1, 'uint16');
    packet_time_s = fread(file_id, 1, 'uint');
    packet_time_us = fread(file_id, 1, 'uint');
    packet_counter = fread(file_id, 1, 'uint');

    rel_time_raw = daq_packet_time_stamp_s + daq_packet_time_stamp_us*10d-7;
    rel_time = [rel_time rel_time_raw ];
%      radar_payload = fread(file_id, socket_payload_size,'uint8');
%      fwrite(radar_id, radar_payload);

% speed up 
% please not: there is a mismatch for large uint64 number when using
% typecast on uint8 and reading uint64
% the later would be faster however the exact data is not reproduced
% therefore we stick to reading unint8 data
%        radar_payload = typecast(uint64(fread(file_id, socket_payload_size/8,'uint64')),'uint64');

    radar_payload = typecast(uint8(fread(file_id, socket_payload_size,'uint8')),'uint64');
    fwrite(radar_id, radar_payload,'uint64');

    if mod(j,10000) == 1
        %fprintf('.');
    end
end

%fprintf('\n%d UDP packets processed.\n', num_data_blocks);

% Close *.dat file.
if fclose(file_id) == 0
    %fprintf('%s closed.\n', dat_fullpath);
else
    fprintf('ERROR: %s could not be closed. Exiting.', ...
        dat_fullpath);return;
end
end
%toc
   
    
    clear file_id num_data_blocks j daq_packet_time_stamp_s ...
    daq_packet_time_stamp_us arena_payload_type arena_payload_length ...
    arena_id mezzanine_id packet_time_s packet_time_us packet_counter ...
    radar_payload;

% Close temporary data file.
if fclose(radar_id) == 0
    %fprintf('Temporary data file closed.\n');
else
    fprintf('ERROR: Temporary data file could not be closed for %s. Exiting.',dat_fullpath); return;
end

%fprintf('Radar payload extracted from all *.dat files.\n');


%% Parsing the temporary file to extract chirps and variables
%% Phase 1: counter the number of chirps in each mode to preallocate memory
% Unpack radar payload from temporary file.
% Open radar.dat file.
radar_id = fopen(tmp_fullpath, 'r');
if radar_id == -1
    fprintf(strcat('ERROR: count not open temp file ',tmp_fullpath, ' for reading. Exiting.')); return;
else
    %fprintf('Temporary data file opened for processing.\n');
end

% Cycle through all the radar payload packets.
%fprintf('Extracting raw data. This may take a while.\n');
%tic
counter = 0;
start_pointer =0;
unsync_times=0;
while true
    % Read in sync word and error check.
%    sync = fread(radar_id, 8);
    sync = fread(radar_id, 1,'uint64');
    if feof(radar_id)
        break;
    end
    if ~isequal(sync,sync_word)
	unsync_times=unsync_times+1;
	%fprintf('unsync %d times now!\n',unsync_times);
        % check the whole file for the first sync
        status = fseek(radar_id,-7,'cof');
        if status == -1
          fprintf('Failed to resync file pointer. Exiting.'); return;
        end
	continue;

	frewind(radar_id);
        sync = fread(radar_id, 'uint64');
        ind = find(sync == sync_word )-1;

        if length(ind) == 0 
          fprintf('Unexpected data found instead of sync. Exiting.'); return;
        end
        
        start_pointer = ind(1)*8;
        fseek(radar_id, start_pointer, 'bof');
        sync = fread(radar_id, 1,'uint64');

    end

        if ~isequal(sync,sync_word)
              fprintf('Unexpected data found instead of sync. Exiting.'); return;
        end

    % Read in radar header type and length together.
    radar_header_type = fread(radar_id, 8);
    if feof(radar_id)
        break;
    end
    
    % Read in mode;
    mode = fread(radar_id, 1);
    mode_index = find(my_modes==mode);
    if feof(radar_id)
        break;
    end
    
    % Trash all remaining profile header data
    dummy_bytes = fread(radar_id, 48-1);
    if feof(radar_id)
        break;
    end

    % Read in radar profile data format.
    radar_profile_data_format = fread(radar_id, 4);
    if feof(radar_id)
        break;
    end
    
    % Read in radar profile length.
    radar_profile_length = fread(radar_id, 1,'uint');
    if feof(radar_id)
        break;
    end
    
    % Calculate actual radar profile length in bytes to account for ARENA 
    % software bug.
    num_samples_per_profile = my_range_gates(2,mode_index)-my_range_gates(1,mode_index)+1;

       % Read in radar profile data.
    clear i;
    bounced = 0;
    radar_data_raw = [];

    
    if isequal(radar_profile_data_format, [0;0;0;0])
        sample_size = 2;
        radar_data_raw = fread(radar_id,num_samples_per_profile, 'int16');
    elseif isequal(radar_profile_data_format, [0;0;1;0])
        sample_size = 2;
        radar_data_raw = fread(radar_id,num_samples_per_profile, 'uint16');
    elseif isequal(radar_profile_data_format, [0;0;2;0])
        sample_size = 8;
        
        % slight speed up when reading int64 in combination with typecast instead reading int32
 %       new_trace = fread(radar_id,2*num_samples_per_profile, 'int32');
        new_trace = (typecast(int64(fread(radar_id,num_samples_per_profile, 'int64')), 'int32'));
    
    	if feof(radar_id)
       		 break;
    	end
    
        radar_data_raw=complex(new_trace(1:2:end,:),new_trace(2:2:end,:));
    elseif isequal(radar_profile_data_format, [0;0;3;0])
        sample_size = 8;
        new_trace = fread(radar_id,2*num_samples_per_profile, 'double');
    	if feof(radar_id)
       		 break;
    	end
        radar_data_raw=complex(new_trace(1:2:end,:),new_trace(2:2:end,:));
    else
        fprintf('ERROR: unknown radar profile data format in %s. Exiting.',dat_fullpath); return;
    end
    
        if feof(radar_id)
             bounced = 1;
             break;
         end

    %pps_time_raw = pps_counter + pps_fractional_counter*10d-8;
    %pps_time = [pps_time pps_time_raw];

   counter = counter +1;
    Results(mode_index).counter = Results(mode_index).counter +1;

     if bounced
         break;
     end
 %     
    % Store all necessary information (currently only storing the profile
    % data).
    %radar_data = [radar_data radar_data_raw];
end
%toc



% Pre allocate array for Chirps
for j = 1:size(my_modes,2)
    tmp = zeros(my_range_gates(2,j)-my_range_gates(1,j)+1, Results(j).counter);
    Results(j).Chirps = complex(tmp,0);
    Results(j).Relative_Counters = zeros(1, Results(j).counter);
    Results(j).Profile_Counters = zeros(1, Results(j).counter);
    Results(j).PPS_Fractional_Counters = zeros(1, Results(j).counter);
    Results(j).PPS_Time = zeros(1, Results(j).counter);
    Results(j).PPS_Counters = zeros(1, Results(j).counter);
    
    %now all result memory are allocated
    %we can clean up counters to use incremental counter for assigning chirp to the right column
    Results(j).counter = 0; 
end


%% Parsing the temporary file to extract chirps and variables
%% Phase 2: read profile chirps to assign chirp to the right memory column

frewind(radar_id);
counter = 0;
start_pointer =0;

%tic
while true
    % Read in sync word and error check.
%    sync = fread(radar_id, 8);
    sync = fread(radar_id, 1,'uint64');
    if feof(radar_id)
        break;
    end
    if ~isequal(sync,sync_word)
	unsync_times=unsync_times+1;
	%fprintf('unsync %d times now!\n',unsync_times);
        % check the whole file for the first sync
        status = fseek(radar_id,-7,'cof');
        if status == -1
          fprintf('Failed to resync file pointer. Exiting.'); return;
        end
	continue;
    end

        if ~isequal(sync,sync_word)
              fprintf('Unexpected data found instead of sync. Exiting.'); return;
        end

    % Read in radar header type.
    radar_header_type = fread(radar_id, 4);
    if feof(radar_id)
        break;
    end
    
    % Read in radar header length.
    radar_header_length = fread(radar_id, 4);
    if feof(radar_id)
        break;
    end
    
    % Read in mode;
    mode = fread(radar_id, 1);
    mode_index = find(my_modes==mode);
    % Increase counter for mode, but be careful for last incomplete chirp!
    Results(mode_index).counter = Results(mode_index).counter +1;

    if feof(radar_id)
        break;
    end
    
    % Read in subchannel and data source.
    new_byte = fread(radar_id, 1);
    if feof(radar_id)
        break;
    end
    subchannel = mod(new_byte, 16);
    data_source = floor(new_byte / 16);
    
    % Trash reserved section.
    reserved_6 = fread(radar_id, 6);
    if feof(radar_id)
        break;
    end
    
    % Read in encoder.
    encoder = fread(radar_id, 4);
    if feof(radar_id)
        break;
    end
    
    % Trash reserved section.
    reserved_4 = fread(radar_id, 4);
    if feof(radar_id)
        break;
    end
    
    % Read in relative counter.
    relative_counter = fread(radar_id, 1,'uint64');
    if feof(radar_id)
	 Results(mode_index).counter = Results(mode_index).counter - 1;
   	 break;
    end
    
    % Read in profile counter;
    profile_counter = fread(radar_id,1,'uint64');
    if feof(radar_id)
	 Results(mode_index).counter = Results(mode_index).counter - 1;
   	 break;
    end
    
    % Read in pps fractional counter.
    pps_fractional_counter = fread(radar_id, 1,'uint64');
    if feof(radar_id)
	 Results(mode_index).counter = Results(mode_index).counter - 1;
   	 break;
    end
    
    % Read in pps counter.
    pps_counter = fread(radar_id, 1,'uint64');
    if feof(radar_id)
	 Results(mode_index).counter = Results(mode_index).counter - 1;
   	 break;
    end
	
    
    % Read in radar profile data format.
    radar_profile_data_format = fread(radar_id, 4);
    if feof(radar_id)
	Results(mode_index).counter = Results(mode_index).counter - 1;
        break;
    end
    
    % Read in radar profile length.
    radar_profile_length = fread(radar_id, 1,'uint');
    if feof(radar_id)
	Results(mode_index).counter = Results(mode_index).counter - 1;
        break;
    end
    
    % Calculate actual radar profile length in bytes to account for ARENA 
    % software bug.
    num_samples_per_profile = my_range_gates(2,mode_index)-my_range_gates(1,mode_index)+1;

       % Read in radar profile data.
    clear i;
    bounced = 0;
    radar_data_raw = [];

    
    if isequal(radar_profile_data_format, [0;0;0;0])
        sample_size = 2;
        radar_data_raw = fread(radar_id,num_samples_per_profile, 'int16');
    elseif isequal(radar_profile_data_format, [0;0;1;0])
        sample_size = 2;
        radar_data_raw = fread(radar_id,num_samples_per_profile, 'uint16');
    elseif isequal(radar_profile_data_format, [0;0;2;0])
        sample_size = 8;
        
        % slight speed up when reading int64 in combination with typecast instead reading int32
 %       new_trace = fread(radar_id,2*num_samples_per_profile, 'int32');
        new_trace = (typecast(int64(fread(radar_id,num_samples_per_profile, 'int64')), 'int32'));

	 if feof(radar_id)
		 Results(mode_index).counter = Results(mode_index).counter - 1;
   		 break;
   	 end
        
        radar_data_raw=complex(new_trace(1:2:end,:),new_trace(2:2:end,:));
    elseif isequal(radar_profile_data_format, [0;0;3;0])
        sample_size = 8;
        new_trace = fread(radar_id,2*num_samples_per_profile, 'double');
	 if feof(radar_id)
		 Results(mode_index).counter = Results(mode_index).counter - 1;
   		 break;
   	 end

            radar_data_raw=complex(new_trace(1:2:end,:),new_trace(2:2:end,:));
    else
        fprintf('ERROR: unknown radar profile data format in %s. Exiting.',dat_fullpath); return;
    end
    
        if feof(radar_id)
             Results(mode_index).counter = Results(mode_index).counter - 1;
             bounced = 1;
             break;
         end

    pps_time_raw = pps_counter + pps_fractional_counter*10d-8;
    %pps_time = [pps_time pps_time_raw];
    Results(mode_index).PPS_Time(1,Results(mode_index).counter) = pps_time_raw;
    Results(mode_index).Relative_Counters(1, Results(mode_index).counter) = relative_counter;
    Results(mode_index).Profile_Counters(1, Results(mode_index).counter) = profile_counter;
    Results(mode_index).PPS_Fractional_Counters(1,Results(mode_index).counter) = pps_fractional_counter;
    Results(mode_index).PPS_Counters(1,Results(mode_index).counter) = pps_counter;
    
    col_id = Results(mode_index).counter;
    Results(mode_index).Chirps(:,col_id) = radar_data_raw;
    


    counter = counter +1;
     if bounced
         break;
     end
%     
    % Store all necessary information (currently only storing the profile
    % data).
    
    %radar_data = [radar_data radar_data_raw];
    
    
end
%toc


%% Remaining Cleanups

clear sync sync_word radar_header_type radar_header_length mode ...
    new_byte subchannel data_source reserved_6 encoder reserved_4 ...
    relative_counter profile_counter pps_fractional_counter pps_counter ...
    radar_profile_length sample_size num_samples_per_profile ...
    radar_profile_data;
% Print out data format message.
%fprintf('Data format: ');
if isequal(radar_profile_data_format, [0;0;0;0])
    %fprintf('16-bit signed data (2 bytes ');
elseif isequal(radar_profile_data_format, [0;0;1;0])
    %fprintf('16-bit unsigned data (2 bytes ');
elseif isequal(radar_profile_data_format, [0;0;2;0])
    %fprintf('32-bit signed complex data pairs (8 bytes ');
elseif isequal(radar_profile_data_format, [0;0;3;0])
    %fprintf('32-bit floating point complex pairs (8 bytes ');
end
%fprintf('per sample).\n');
clear radar_profile_data_format;



% now interpolate the rel_time to a time for each trace as we observed some
% time steps in the pps_time
 trace_time = (1:counter) * ((max(rel_time) - min(rel_time)) / (counter-1)) + min(rel_time);

delete(tmp_fullpath);

% Delete radar.dat file.
fclose(radar_id);
mat_fullpath = strcat(dat_fullpath(1:(end-3)),'mat');
mat_counter_fullpath = strcat(dat_fullpath(1:(end-4)),'_counters.mat');
Counters = Results;
for i = 1:size(my_modes,2)
    Counters(i).Chirps = [];
end
 
save(mat_fullpath, 'Results','trace_time','-v7.3','-nocompression');
fprintf(strcat('finishing ',mat_fullpath, '......\n'));
save(mat_counter_fullpath, 'Counters','trace_time','-v7.3','-nocompression');
fprintf(strcat('finishing ',mat_counter_fullpath, '......\n'));
%toc
