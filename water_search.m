%% Script to search for a specular response in a group of files
%% The specular rangeline found will be subsequently used for
%% system deconvolution
%%
%% 5/31/2019
%% Last Edited by : S.Z. Gurbuz
%%
%% Inputs:  filename to be searched, parameter list, 
%%          minimum desired value of difference between top two peaks
%% Outputs:  best rangeline meeting criteria, and corresponding
%%           delta, max value, location of peak, and index value
%%           corresponding to that selection

function [rangeline,delta,maxpk,vpk,index,updtcntr]=water_search(data_dir,filename,initdelta,initmaxpk)

load([data_dir filename]);
%aa1=double(Results(1).Chirps);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FIND MOST SPECULAR RESPONSE IN FILE %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[M1,N1]=size(echogram0);
pxx=echogram0;
rangeline=pxx(:,1);
index=1;
vpk = 0;
updtcntr = 0;
delta = initdelta;   % we initially used 20
maxpk = initmaxpk;   % we initially used -inf 
for ii=2:N1;  % find the spectrecular range line
     [pks,loc]=findpeaks(pxx(:,ii),'MinPeakDistance',150,'SortStr','descend');
     % check if possibly a water response
     if pks(1)-pks(2) >= delta,  
          delta = pks(1)-pks(2);  
          if pks(1)>=maxpk          % select rangeline with max peak
                  maxpk = pks(1); 
                  vpk=loc(1);
                  rangeline = pxx(:,ii); 
                  index = ii;
                  updtcntr = 1;
          end;
     end;
%     max1= max(rangeline2);
%     max2=max(pxx(1:M1,ii));
%     if max2>max1
%         rangeline2=pxx(:,ii);
%       [y v]=max(rangeline2); % v is the index in frequency(Range/fast-time) axis
%       index2=ii; % index=ii finds the index of spectrecular rangeline index in slow time axis
end;

end
% end of water_search function