%% Script to estimate sytem correction vector
%% The system correction function will be used for deconvoluiton
%% system deconvolution
%%
%% 5/31/2019
%% Last Edited by : Mahbub
%%
%% Inputs:  filename contains water response(pkfile), parameter list(params), 
%%          slow-time peaks index(pkind), fast-time peak index(vpk)
%% Outputs:  system correction function
%%           corresponding to the timestamp

function syscorr=system_corr(data_dir,pkfile,fs,pkind,vpk)

        % Estimate deconvolution
         indexable_name = char(pkfile);
         filename=[indexable_name(1:42) '.mat'];
        load([data_dir filename]);
        data=Results(1).Chirps;
        
        f=fs*linspace(0,1,size(data,1));
        
        
        fb=f(vpk);
        w1=2*(fb-(fb/100))/fs;
        w2=2*(fb+(fb/100))/fs;
        [b1, a1]=butter(5,[w1 w2]);
        
        
        jj=pkind;
        xxm1=zeros(size(data,1),1);
        
        for i=jj-7:jj+8 %we have done non coh. average over 8 (actually 16)pulses
                xxm1=xxm1+data(:,i);
                
        end
        
        xxmmean=mean(xxm1,1);
        xxm= double((xxm1-xxmmean)/16);
        
        % filtered or range gated reference target data
        
        xxmf=filtfilt(b1,a1,xxm);
        
        ysignalc=hilbert(xxmf);
        % Compute correction coefficients
        
        Amp= abs(ysignalc)/max(abs(ysignalc));
        
        Ampf= medfilt2( Amp,[25,1]);
        Ph=detrend(unwrap(angle(ysignalc)));
        phf= medfilt2(Ph,[25,1]);
        ii=sqrt(-1);
        syscorr=exp(-ii*phf)./Ampf;
       

end