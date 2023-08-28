%% Manual Spike Sorting
clear ;clc;

%% variables

pathFolderData = '/home/djaeckel/Sample_Data/MicheleForShowcase/Trace_20180709_10_28_49.raw.h5';

load_position_frame = 1; % initial point of data extraction
time_load = 100; % in seconds
thr_spikes = 5; % threshold for spike detection


%% execute 

% Create file manager
datainfo = mxw.fileManager(pathFolderData);
% Compute values for mapping
spikeCount = mxw.activityMap.computeSpikeCount(datainfo);

% Extract Data
Fs = datainfo.fileObj.samplingFreq; % this is the sampling frequency of the MEA
data_chunk_size_in_seconds = time_load; % time of the data you want to extract
[data, filesArray, electrodesArray] = datainfo.extractBPFData(load_position_frame, data_chunk_size_in_seconds*Fs);
disp([num2str(datainfo.fileObj.dataLenSamples/Fs),' seconds recorded'])

%% find best electrodes
bestElectrodes = 5;

arrayBestElectrodes = [];
minValues = min(data);
std_data = std(data);

c = 0;
while c<bestElectrodes+1
    
    [M,I] = min(minValues);
    minValues(I) = NaN;
    if std_data(I)<20 
    arrayBestElectrodes(end+1) = I;    
    c = c+1;
    end
end
arrayBestElectrodes(end) = [];

% Plotting best electrodes

figure('color','w','position',[0 100 1000 600]);

for i = 1:bestElectrodes
    subplot(bestElectrodes,2,(1+2*i)-2);
    plot(data(:,arrayBestElectrodes(i)));
    ylabel('\muV');
    xlabel('Time [s]');
    set(gca,'tickdir','out','xtick',[0:1:data_chunk_size_in_seconds]*20000,'xticklabel',[0:1:data_chunk_size_in_seconds]);
    legend(['electrode = ',num2str(datainfo.rawMap.map.electrode(arrayBestElectrodes(i)))])
    box off
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

subplot(bestElectrodes,2,[8 10]);
h = histogram(std(data));box off;
h.FaceColor = 'k'; h.EdgeColor = 'k'; h.FaceAlpha = 1;
xlabel('Electrode Noise [s.d. \muV]');
ylabel('Counts')
legend(['Mean Noise = ',num2str(mean(std(data)),'%.2f'),' \muV'])

%% manual spike sorting

% variables
% chose the electrode to sort among the best electrodes
n_el = 932;
% chose how many electrodes around the chose one to proceed with spike sorting 
n = 7;

% execute
x = datainfo.rawMap.map.x;
y = datainfo.rawMap.map.y;
d = [];

for i = 1:length(x)
    d(i) = sqrt( (x((datainfo.fileObj.map.electrode==n_el)) - x(i))^2 + (y((datainfo.fileObj.map.electrode==n_el)) - y(i))^2 );
end
[val, ind] = sort(d);

BPFdataChannels = data(:,ind(1:n));

spikes = ss_default_params(20000);
spikes.params.display.isi_bin_size = 0.2;
spikes.params.refractory_period = 1.5;
spikes.params.display.default_waveformmode = 2;
spikes.params.thresh = thr_spikes; % spike detection threshold
spikes.params.display.show_isi = 1;
spikes = ss_detect({BPFdataChannels},spikes);
spikes = ss_align(spikes);
spikes = ss_kmeans(spikes);
spikes = ss_energy(spikes);
spikes = ss_aggregate(spikes);

splitmerge_tool(spikes)

%% plot sorted neurons

% variables
% decide which cluster to plot
cluster_id = 1;
% waveform cut range, in samples
pretime_spike_cut = 20;
posttime_spike_cut = 49;

% execute
ts = round(spikes.spiketimes(spikes.assigns==cluster_id)*20000);
ts2 = sort(ts);
ts2(find(diff(ts2)<20)) = [];
ts2(ts2<150) =[];% remove ts to close to beginning of Y
ts2(ts2>length(data)-200) = [];% remove ts to close to end of Y
W = [];
for i = 1:length(ts2)
    w_c = (data(ts2(i)-pretime_spike_cut:ts2(i)+posttime_spike_cut,:));
    W(:,:,end+1) = w_c;
end


% plot neuron
waveforms = mean(W,3);
[val,ind] = min(min(waveforms));
figure('color','w','position',[200 200 1000 300]);subplot(1,3,1)
mxw.plot.axonTraces(x,y,waveforms,'PlotWaveforms', true,'Figure',false,'PlotHeatMap',false,'Title',['EAP ','#',num2str(n_el),'-',num2str(datainfo.fileObj.map.electrode(ind))],'WaveformColor','k')%,'CaxisLim', [min(min(min(squeeze(W)))) 0],'ylabel','/muV')
axis equal;[val, ind] = min(min(waveforms));
xlim([x(ind) - 150 x(ind) + 150]);ylim([y(ind) - 150 y(ind) + 150]);
xlabel('\mum');ylabel('\mum');


subplot(1,3,2);
[N,edges] = histcounts(ts/Fs,0:0.1:max(ts)/Fs);
plot(edges(1:end-1),N,'color','k');
xlabel('time [s]');
ylabel('# spikes');
box off;ylim([0 20]);
title('Firing Rate')

subplot(1,3,3)
plot_isi( spikes, cluster_id, 1 )


