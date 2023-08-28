%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%                                                                %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%                 Data analysis script                           %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%                 Data ID: 000435                                %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%                 By MaxWell Biosystems AG                        %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%                                                                %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% clear all %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close all; clear; clc;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% path & filename %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

datapath = 'C:\Users\tlab\Documents\勉強\竹内研\データ\maxone\20230719\';  % datapath has to be adapted
filename = 'data.raw.h5';                                   % the filename is default (unless intentionally changed)

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% assign %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

mydata = [datapath filename];

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% extract unfiltered traces %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
wellID   = 1;
myfile   = mxw.fileManager(mydata,wellID);
sampRate = myfile.fileObj.samplingFreq;
dataSize = myfile.fileObj.dataLenSamples;
traces   = double(myfile.extractRawData(1,dataSize/10));

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% downsample traces %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

dsrate  = sampRate/10; % resulting sampling rate will be 10 samples per second
traces1 = downsample(traces, dsrate);
%}

%% %%%%%%%%%%%%%%%%%%%%%%%% extract unfiltered traces and downsample traces %%%%%%%%%%%%%%%%%%%%%%%%%%%% %fixed

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

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% plot traces %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% figure
% close all; 
figure('name','extracted traces','NumberTitle','off', 'color', 'w');
set(gcf,'Position',[40 400 1600 400]);

% panels
ax1 = subplot(1,3,1); ax1.Box = 'on'; grid(ax1, 'on');
ax2 = subplot(1,3,2); ax2.Box = 'on'; grid(ax2, 'on');
ax3 = subplot(1,3,3); ax3.Box = 'on'; grid(ax3, 'on');

% downsampled traces
hold on; plot(ax1, traces1, 'linewidth', .1);
ax1.Title.String = 'downsampled traces';
ax1.XLim = [1 size(traces1,1)];
ax1.YLim = [min(min(traces1)) max(max(traces1))];
ax1.XLabel.String = 'Time [ s ]';
ax1.XTickLabel = ax1.XTick/10;
grid(ax1, 'on');

% traces after the offecet (microvolts)
hold on; plot(ax2, traces2, 'linewidth', .1);
ax2.Title.String = 'offset compensation';
ax2.XLim = [1 size(traces2,1)];
ax2.YLim = [min(min(traces2)) max(max(traces2))];
ax2.XLabel.String = 'Time [ s ]';
ax2.XTickLabel = ax2.XTick/10;
ax2.YLabel.String = 'Voltage [ µV ]';
grid(ax2, 'on');

% traces after th eoffecet (microvolts)
hold on; plot(ax3, traces3, 'linewidth', .1);
ax3.Title.String = 'voltage traces';
ax3.XLim = [1 size(traces3,1)];
ax3.YLim = [min(min(traces3)) max(max(traces3))];
ax3.XLabel.String = 'Time [ s ]';
ax3.XTickLabel = ax3.XTick/10;
ax3.YLabel.String = 'Voltage [ mV ]';
grid(ax3, 'on');

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% amplitude distributions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% extract signal peaks and amplitudes
negativePeaks = min(traces3);
positivePeaks = max(traces3);
amplitudes    = abs(negativePeaks)+positivePeaks;

% figure
% close all; 
figure('name','signal amplitude distributions','NumberTitle','off', 'color', 'w');
set(gcf,'Position',[40 400 1600 400]);

% panels
ax1 = subplot(1,3,1); ax1.Box = 'on'; grid(ax1, 'on');
ax2 = subplot(1,3,2); ax2.Box = 'on'; grid(ax2, 'on');
ax3 = subplot(1,3,3); ax3.Box = 'on'; grid(ax3, 'on');

% positive peaks
hold on; h1 = histogram(ax1, positivePeaks, 10);
ax1.Title.String = 'positive peaks';
ax1.XLabel.String = 'Voltage [ mV ]';
ax1.YLabel.String = 'Count [ # ] ';
h1.FaceColor = '#135ba3';
h1.EdgeColor = [1 1 1]*.4;
grid(ax1, 'on');

% negative peaks
hold on; h2 = histogram(ax2, negativePeaks, 10);
ax2.Title.String = 'negative peaks';
ax2.XLabel.String = 'Voltage [ mV ]';
ax2.YLabel.String = 'Count [ # ] ';
h2.FaceColor = '#135ba3';
h2.EdgeColor = [1 1 1]*.4;
grid(ax2, 'on');

% signal amplitudes
hold on; h3 = histogram(ax3, amplitudes, 10);
ax3.Title.String = 'peak-to-peak amplitudes';
ax3.XLabel.String = 'Voltage [ mV ]';
ax3.YLabel.String = 'Count [ # ] ';
h3.FaceColor = '#135ba3';
h3.EdgeColor = [1 1 1]*.4;
grid(ax3, 'on');

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% color-coding %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[minPeaks, absTimes] = min(traces3);
peakTimes     = absTimes/10; % seconds

% get peaks colors
cmap1.map = hot;
cmap1.lim = [min(minPeaks) max(minPeaks)];
[peakInd, ~] = sort(peakTimes);
nvals = (peakInd-min(peakInd));
rescalf = max(nvals)/size(cmap1.map,1);
rvals = round(nvals/rescalf)+1;
rvals(rvals>size(cmap1.map,1)) = size(cmap1.map,1);
mycolors1 = cmap1.map(rvals,:);

% get time colors
cmap2.map = winter;
cmap2.lim = [min(peakTimes) max(peakTimes)];
[timeInd, ~] = sort(peakTimes);
nvals = (timeInd-min(timeInd));
rescalf = max(nvals)/size(cmap2.map,1);
rvals = round(nvals/rescalf)+1;
rvals(rvals>size(cmap2.map,1)) = size(cmap2.map,1);
mycolors2 = cmap2.map(rvals,:);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% plot traces %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% figure
% close all; 
figure('name','signal amplitude distributions','NumberTitle','off', 'color', 'w');
set(gcf,'Position',[40 400 1600 400]);

% panels
ax1 = subplot(1,2,1); ax1.Box = 'on'; grid(ax1, 'on');
ax2 = subplot(1,2,2); ax2.Box = 'on'; grid(ax2, 'on');

% Negative peak voltages
for i = 1:size(traces3,2) %fixed
    hold(ax1, 'on'); plot(ax1, traces3(:,i), 'color', mycolors1(i,:), 'LineWidth',1)
end
ax1.XLim = [1 size(traces3,1)];
ax1.YLim = [min(min(traces3)) max(max(traces3))];
ax1.Title.String = 'negative peak voltages';
ax1.XLabel.String = 'Time [ s ]';
ax1.YLabel.String = 'Voltage [ mV ] ';
ax1.XTickLabel = ax1.XTick/10;
grid(ax1, 'on');

% colorbar 1
colormap(ax1, cmap1.map);
caxis(ax1, cmap1.lim);
cbar1 = colorbar(ax1);
cbar1.Location = 'eastoutside';
cbar1.Label.String = 'Voltage [ mV ]';

% Arrival times of negative peaks
for i = 1:size(traces3,2) %fixed
    hold(ax2, 'on'); plot(ax2, traces3(:,i), 'color', mycolors2(i,:), 'LineWidth',1)
end
ax2.XLim = [1 size(traces3,1)];
ax2.YLim = [min(min(traces3)) max(max(traces3))];
ax2.Title.String = 'peak times';
ax2.XLabel.String = 'Time [ s ]';
ax2.YLabel.String = 'Voltage [ mV ] ';
ax2.XTickLabel = ax2.XTick/10;
grid(ax2, 'on');

% colorbar 2
colormap(ax2, cmap2.map);
caxis(ax2, cmap2.lim);
cbar = colorbar(ax2);
cbar.Location = 'eastoutside';
cbar.Label.String = 'Time [ s ]';

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% histograms %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% figure
% close all; 
figure('name','signal distributions','NumberTitle','off', 'color', 'w');
set(gcf,'Position',[40 400 1600 400]);

% panels
ax1 = subplot(1,2,1); ax1.Box = 'on'; grid(ax1, 'on');
ax2 = subplot(1,2,2); ax2.Box = 'on'; grid(ax2, 'on');

% Negative peak voltages
hold on; h1 = histogram(ax1, minPeaks, 20);
ax1.Title.String = 'positive peaks';
ax1.XLabel.String = 'Voltage [ mV ]';
ax1.YLabel.String = 'Count [ # ] ';
h1.FaceColor = '#135ba3';
h1.EdgeColor = [1 1 1]*.4;
grid(ax1, 'on');

% Arrival times of negative peaks
hold on; h2 = histogram(ax2, peakTimes, 20);
ax2.Title.String = 'negative peaks';
ax2.XLabel.String = 'Time [ s ]';
ax2.YLabel.String = 'Count [ # ] ';
h2.FaceColor = '#135ba3';
h2.EdgeColor = [1 1 1]*.4;
grid(ax2, 'on');

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% activity map %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%close all; 
% get peak-to-peak amplitude
negativePeaks = min(traces3);
positivePeaks = max(traces3);
amplitudes    = abs(negativePeaks)+positivePeaks;

% raw map
map.x = myfile.fileObj.map.x;
map.y = myfile.fileObj.map.y;
map.amp = amplitudes;

% grid map
xlin = linspace( min( map.x ), max( map.x ), 220 );
ylin = linspace( min( map.y ), max( map.y ), 120 );
[X,Y] = meshgrid(xlin,ylin);
mymap.XData = xlin;
mymap.YData = ylin;
mymap.CData = griddata(map.x, map.y, map.amp, X, Y, 'natural');

% figure
fig = figure('name','Activity map','NumberTitle','off', 'color', [1 1 1]*1);
set(gcf,'Position',[500 400 630 1155]);

% panel
ax1 = subplot(5,6,1);
ax1.Position = [.14 .06 .7250 .9125];
ax1.YLim = [-20 2102.5];
ax1.XLim = [-20 3852.5];
ax1.YTick = [];
ax1.XTick = [];
ax1.Box = 'on';
camroll(ax1,90)

% colorbar
cbar1 = colorbar(ax1);
cbar1.Location = 'southoutside';
cbar1.Position = [0.175 0.04 0.66 0.015];
cbar1.Label.String =  'Voltage   [ mV ]';
cbar1.Label.Rotation = 0;

% Activity map
mcmap = hot;
mcmap = flipud(mcmap);
hold(ax1,'on'); plot(ax1, map.x, map.y, 'sk', 'color', 'k', 'markersize', 5);
hold(ax1,'on'); contourf(ax1, mymap.XData, mymap.YData, mymap.CData, 10, 'linewidth', 1, 'FaceAlpha', 0.7); %fixed
hold(ax1,'on'); contour(ax1, mymap.XData, mymap.YData, mymap.CData, 10, 'linewidth',2);
colormap(ax1, mcmap);

% scalebar
hold(ax1,'on'); plot(ax1,[150; 150], [100; 300], '-', 'linewidth', 3, 'color','k');
hold(ax1, 'on'); text(ax1, 100, 300, '200 μm','fontsize',12, 'HorizontalAlignment', 'left', 'color', 'k');

%%