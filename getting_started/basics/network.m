%% BURST ANALYSIS
clear; clc;

%% variables

% Set path to folder containing the recording
pathToNetworkAnalysis = '~/Desktop/mxwbio/data/network/popconf_1581.raw.h5';
% Hello

% set threshold to detect bursts
thr_burst = 1.1; % in rms
% set bin size
gaussian_bin_size = .1; % in seconds

% threshold to find the start and stop time of the bursts, 0.3 means 30% value of the burst peak
thr_start_stop = 0.3; 


%% execute

% Load data information
networkAnalysisFile = mxw.fileManager(pathToNetworkAnalysis);

% Compute network activity
networkAct = mxw.networkActivity.computeNetworkAct(networkAnalysisFile, 'BinSize', 0.02, 'file', 5,'GaussianSigma', gaussian_bin_size);
networkStats = mxw.networkActivity.computeNetworkStats(networkAct, 'Threshold', thr_burst);

% Plotting:
figure('color', 'w','position',[0 100 1300 700]);

% Raster Plot
ax(1)=subplot(2, 3, 1);
mxw.plot.rasterPlot(networkAnalysisFile, 'file', 6, 'Figure', false);box off;
xlim([0 floor(max(networkAct.time))-0.5])
% Histogram gaussian convolution
ax(2)=subplot(2, 3, 4);
mxw.plot.networkActivity(networkAct, 'Threshold', thr_burst, 'Figure', false);box off;
hold on;plot(networkStats.maxAmplitudesTimes,networkStats.maxAmplitudesValues,'or')
xlim([0 floor(max(networkAct.time))-0.5])
linkaxes(ax, 'x')

if length(networkStats.maxAmplitudesTimes)>3

% Burst Peak
subplot(2, 3, 2);
mxw.plot.networkStats(networkStats, 'Option', 'maxAmplitude',  'Figure', false, ...
    'Ylabel', 'Counts', 'Xlabel', 'Burst Peak [Hz]', 'Title', 'Burst Peak Distribution','Bins',20,'Color','b'); box off;
legend(['Mean Burst Peak = ',num2str(mean(networkStats.maxAmplitudesValues),'%.2f'), ' sd = ',num2str(std(networkStats.maxAmplitudesValues),'%.2f')])

% IBI
subplot(2, 3, 3);
mxw.plot.networkStats(networkStats, 'Option', 'maxAmplitudeTimeDiff',  'Figure', false,...
    'Ylabel', 'Counts', 'Xlabel', 'Interburst Interval [s]', 'Title', 'Interburst Interval Distribution','Bins',20,'Color','b'); box off;
legend(['Mean Interburst Interval = ',num2str(mean(networkStats.maxAmplitudeTimeDiff),'%.2f'),' sd = ',num2str(std(networkStats.maxAmplitudeTimeDiff),'%.2f')])


% Synchrony, Percentage Spikes within burst
subplot(2, 3, 5);
amp = networkStats.maxAmplitudesValues';
t = networkStats.maxAmplitudesTimes;
edges = [];
for i = 1:length(amp)

   idx = networkAct.time>(t(i)-6) & networkAct.time<(t(i)+6);
   t1 = networkAct.time(idx);
   a1 = networkAct.firingRate(idx)';
   hw = (amp(i)-round(amp(i)*thr_start_stop));
   
   idx1 = find(a1<hw & t1<t(i));
   idx2 = find(a1<hw & t1>t(i));
   
   t_before = t1(idx1(end));
   t_after = t1(idx2(1));

   edges = [edges; t_before t_after];

end

subplot(2, 3, 1);hold on;
for i = 1:length(edges)
    line([edges(i,1),edges(i,1)],[0 1024],'Color','b')
    line([edges(i,2),edges(i,2)],[0 1024],'Color','r')
end

ts = ((double(networkAnalysisFile.fileObj.spikes.frameno) - double(networkAnalysisFile.fileObj.firstFrameNum))/20000)';
ch = networkAnalysisFile.fileObj.spikes.channel;
spikes_per_burst = [];
ts_within_burst = [];
ch_within_burst = [];

for i = 1:length(edges)
   
   idx = (ts>edges(i,1) & ts<edges(i,2));
   spikes_per_burst = [spikes_per_burst sum(idx)];
   
   ts_within_burst = [ts_within_burst ts(idx)];
   ch_within_burst = [ch_within_burst ch(idx)'];
   
  
end

% Synchrony, Percentage Spikes within burst
subplot(2, 3, 5);
h = histogram(spikes_per_burst,20);
h.FaceColor = 'b'; h.EdgeColor = 'b'; h.FaceAlpha = 1;
box off;ylabel('Counts');xlabel('Number of Spikes Per Burst')
title(['Spikes Within Burst = ', num2str(sum(spikes_per_burst/length(ts))*100,'%.1f'),' %'])
legend(['Mean Spikes Per Burst = ',num2str(mean(spikes_per_burst),'%.2f'), ' sd = ',num2str(std(spikes_per_burst),'%.2f')])


% Burst Duration
subplot(2, 3, 6);
h = histogram(abs(edges(:,1) - edges(:,2)),20);
h.FaceColor = 'b'; h.EdgeColor = 'b'; h.FaceAlpha = 1;
box off;ylabel('Counts');xlabel('Time [s]')
title(['Burst Duration'])
legend(['Mean Burst Duration = ',num2str(mean(abs(edges(:,1) - edges(:,2))),'%.2f'), ' s sd = ',num2str(std(abs(edges(:,1) - edges(:,2))),'%.2f')])

end