%% SCAN MEA ANALYSIS
clear; clc;

%% variables

% Set path to folder containing the recordings
pathFolderFullScan = '~/Desktop/mxwbio/data/scan/';

thr_spike_rate = 0.1; % Hz

% Load data information
fullScanFolder = mxw.fileManager(pathFolderFullScan);

%% execute

% Compute spikes features
spikeRate = mxw.activityMap.computeSpikeRate(fullScanFolder);
amplitude90perc = (mxw.activityMap.computeAmplitude90percentile(fullScanFolder));

% Plot results
figure('color','w','position',[0 100 600 600]);
subplot(2,1,1);
mxw.plot.activityMap(fullScanFolder, spikeRate, 'Ylabel', 'Spike Rate (Hz)', 'CaxisLim', [0 max(spikeRate/2)],'Figure',false,'Title','Spike Rate');
xlabel('\mum');ylabel('\mum');xlim([-200 4100]);ylim([-100 2200])
subplot(2,1,2);h = histogram(spikeRate(spikeRate>thr_spike_rate),0:.1:ceil(max(spikeRate)));ylabel('Counts');xlabel('Spike Rate (Hz)');box off;
h.FaceColor = 'k'; h.EdgeColor = 'k'; h.FaceAlpha = 1;
legend(['Mean SR = ',num2str(mean(spikeRate(spikeRate>thr_spike_rate)),'%.2f'),' Hz,  sd = ',num2str(std(spikeRate(spikeRate>thr_spike_rate)),'%.2f')])

figure('color','w','position',[700 100 600 600]);
subplot(2,1,1);
mxw.plot.activityMap(fullScanFolder, amplitude90perc,  'CaxisLim', [-60 0], 'Ylabel', 'Amplitude \muV','Figure',false,'Title','Spike Amplitudes','RevertColorMap', true );
xlabel('\mum');ylabel('\mum');xlim([-200 4100]);ylim([-100 2200])
subplot(2,1,2);h = histogram(amplitude90perc(amplitude90perc<-1),ceil(min(amplitude90perc)):1:0);ylabel('counts');xlabel('Amplitude \muV');box off;
h.FaceColor = 'k'; h.EdgeColor = 'k'; h.FaceAlpha = 1;
legend(['Mean SA = ',num2str(mean(amplitude90perc(amplitude90perc<-1)),'%.2f'),' \muV,  sd = ',num2str(std(amplitude90perc(amplitude90perc<-1)),'%.2f')])

