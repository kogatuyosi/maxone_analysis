%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% clear all %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close all; clear; clc;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% path & filename %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

datapath = 'C:\Users\tlab\Documents\勉強\竹内研\データ\maxone\20230719\';  % datapath has to be adapted
filename = 'data.raw.h5';                                   % the filename is default (unless intentionally changed)

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% assign %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

mydata = [datapath filename];

%% %%%%%%%%%%%%%%%%%%%%%%%% extract unfiltered traces and downsample traces %%%%%%%%%%%%%%%%%%%%%%%%%%%%

wellID   = 1;
myfile   = mxw.fileManager(mydata,wellID);
sampRate = myfile.fileObj.samplingFreq;
dataSize = myfile.fileObj.dataLenSamples;
downSize = sampRate/10;
traces1 = [];

for time = downSize:downSize:dataSize
    tmp_trace = double(myfile.extractRawData(time,1));
    traces1 = cat(1,traces1,tmp_trace);
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% offset %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

myoffset = mean(traces1(1:100,:)); % first 100 samples (10 seconds) are used to re-align traces
traces2 = traces1-myoffset;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% convert microvolts to milivolts %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

traces3 = traces2/1000;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% make movie %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%電極の位置を生成

