       
clc; clear all; close all;

 data_dir =  '/data/Grand_Junction_2019/';  % Directory of all the timestamp
 save_dir =  data_dir;       % syscorr.mat will be saved in this directory
 xlsdir='/data/RSC_HPC/scripts/';       % xlsx file containig info on calibartion target
 xlsfilename='Timestamp_with_water_response_9.xlsx'; % xlsx file name
 
system_deconv(data_dir,save_dir,xlsdir,xlsfilename); 
