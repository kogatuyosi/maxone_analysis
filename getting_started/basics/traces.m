%% LOAD TRACES
clear; clc;

% x and y in workspace will contain elecetrode spatial coordinates
% data will contain the voltage traces
%% variables

% Set path to folder containing the recordings
pathFolderData = '~/Desktop/mxwbio/data/network/popconf_1581.raw.h5';
% initial point of data extraction
load_position_frame = 1; 
% time of the data you want to extract
data_chunk_size_in_seconds = 10;


%% execute

% Create file manager
datainfo = mxw.fileManager(pathFolderData);
% Compute values for mapping
spikeCount = mxw.activityMap.computeSpikeCount(datainfo);

%% Extract Data
Fs = datainfo.fileObj.samplingFreq; % this is the sampling frequency of the MEA
[data, filesArray, electrodesArray] = datainfo.extractBPFData(load_position_frame, data_chunk_size_in_seconds*Fs);
% x y cooridnates
x = datainfo.processedMap.xpos; 
y = datainfo.processedMap.ypos;

arrayBestElectrodes = [];
minValues = min(data);
std_data = std(data);

% number of electrodes to plot
bestElectrodes = 7; 

c = 0;
while c<bestElectrodes+1
    
    [M,I] = min(minValues);
    minValues(I) = NaN;
    if std_data(I)<median(std_data)
    arrayBestElectrodes(end+1) = I;    
    c = c+1;
    end
end
arrayBestElectrodes(end) = [];


%% Plotting best electrodes
figure('color','w','position',[0 0 1500 1500]);

for i = 1:bestElectrodes
    subplot(bestElectrodes,2,(1+2*i)-2);
    plot(data(:,arrayBestElectrodes(i)));
    ylabel('\muV');
    xlabel('Time [s]');
    set(gca,'tickdir','out','xtick',[0:1:data_chunk_size_in_seconds]*20000,'xticklabel',[0:1:data_chunk_size_in_seconds]);
    legend(['Electrode = ',num2str(datainfo.rawMap.map.electrode(arrayBestElectrodes(i)))])
    box off
    ylim([round(min(data(:,arrayBestElectrodes(i)))*2) 80])
end

subplot(bestElectrodes,2,[2 4 6]);
plot(datainfo.rawMap.map.x,datainfo.rawMap.map.y,'yo');
hold on;
plot(datainfo.rawMap.map.x(arrayBestElectrodes),datainfo.rawMap.map.y(arrayBestElectrodes),'r.','markersize',15);
hold on;xlabel('\mum');ylabel('\mum');axis equal;axis ij;
xlim([min(datainfo.rawMap.map.x)-20 max(datainfo.rawMap.map.x)+20]);
ylim([[min(datainfo.rawMap.map.y)-20 max(datainfo.rawMap.map.y)+20]]);
title('Electrode Position');
for i = 1:bestElectrodes
     text(datainfo.rawMap.map.x(arrayBestElectrodes(i))+2, ...
	datainfo.rawMap.map.y(arrayBestElectrodes(i))+2, num2str(datainfo.rawMap.map.electrode(arrayBestElectrodes(i))) );
end
xlim([-200 4100]);ylim([-100 2200])

subplot(bestElectrodes,2,[8 10]);
h = histogram(std(data));box off;
h.FaceColor = 'k'; h.EdgeColor = 'k'; h.FaceAlpha = 1;
xlabel('Electrode Standard Deviation [\muV]');
ylabel('Counts')
legend(['Mean Noise = ',num2str(mean(std(data)),'%.2f'),' \muV'])

clearvars -except x y data datainfo

