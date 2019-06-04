



 function []= system_deconv(data_dir,save_dir,xlsdir,xlsfilename)
         % read xlsx file
         
         [idx,raw]=xlsread([xlsdir xlsfilename]);
         
         %estimation parameter initiallization
         
         updtcntr = 0;
         delta = 35; %Initial threshold (power diference beteen main peak and end highest peak)
         maxpk = -inf; 
         rangeline = 0;
         pkind = 0;
         vpk = 0;
         
         % create echogram filename
         
         total_tstamp= size(idx,1);
         data_dir_0 = data_dir;
	 for ii=1:total_tstamp
                
                 start_index=num2str(idx(ii,1));
                 if length(start_index)==1
                         start_index=['000' start_index];
                 elseif length(start_index)==2
                         start_index=['00' start_index];
                 elseif length(start_index)==3
                         start_index=['0' start_index];
                 end
                 
                 end_index=num2str(idx(ii,2));
                 
                 if length(end_index)==1
                         end_index=['000' end_index];
                 elseif length(end_index)==2
                         end_index=['00' end_index];
                 elseif length(end_index)==3
                         end_index=['0' end_index];
                 end
                 
                 total_file=str2num(end_index)-str2num(start_index);
                 folder=char(raw(ii));
                 data_dir=[data_dir_0 folder '/'];
                 for kk=1: total_file
                         fileindex=num2str(str2num(start_index)+1, '%04d')
                         filename=[char(raw(ii)) '_MicrowaveRadar2019_CO_' fileindex '__mode0.mat'];
                         start_index=fileindex;
                         
                         
                         
                         [rl,delta,maxpk,loc,index,updtcntr]=water_search(data_dir,filename,delta,maxpk);
                         if updtcntr == 1,  % if true, rangeline updated, store filename of peak
                                 pkfile = filename; % file with water response
                                 pkind = index;
                                 rangeline = rl;
                                 vpk = loc;
                         end
                         
                 end
                 fs=1200e6/16;
                 if vpk ~=0
                    syscorr=system_corr(data_dir,pkfile,fs,pkind,vpk);
                 
                    save_path_data=[save_dir folder '/' 'syscorr.mat'];
		    save(save_path_data, 'syscorr');
                 else
                     return;
                 end
         end
end









