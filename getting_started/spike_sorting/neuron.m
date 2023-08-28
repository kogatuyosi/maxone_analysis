%% Simple Spike Sorting for Single Recording File
clear all;close all;clc;

%% variables

% Set path to folder containing the recordings
path = '~/Desktop/mxwbio/data/neuron/Trace_20180709_10_28_49.raw.h5';

% percentage of active electrode to sort
activityThreshold = 10; % in percentage

% threshold for spike detection, in std 
thr_spikes = 10;

% electrode clustering radius
radius_in_um = 50;

% threshold to select sorted units, minimum number of spikes
min_numb_spikes = 20;

%% execute

recording = mxw.fileManager(path);
spikeCount = mxw.activityMap.computeSpikeCount(recording);
meanAmp = mxw.activityMap.computeMeanAmplitude(recording);
spikeRate = mxw.activityMap.computeSpikeRate(recording);
figure('color','w');subplot(1,2,1)
mxw.plot.activityMap(recording, spikeRate, 'Ylabel', 'Spike Rate (Hz)', 'CaxisLim', [0 max(spikeRate/2)],'Figure',false,'Title','Spike Frequency');
xlabel('\mum');ylabel('\mum');%xlim([-200 4100]);ylim([-100 2200])


% Identifying neruons

activityThrValue = mxw.util.percentile(spikeCount, 100 - activityThreshold);
selectedElectrodes = (spikeCount > activityThrValue);
subplot(1,2,2)
mxw.plot.activityMap(recording, selectedElectrodes, 'RevertColorMap', false, 'Interpolate', false, 'CaxisLim', [0 1], 'PointSize', 100,'Title', 'Selected Electrodes','Figure',false, 'Ylabel', 'Selected Electrodes');
xlabel('\mum');ylabel('\mum');%xlim([-200 4100]);ylim([-100 2200])


fixedElectrodes.electrodes = recording.processedMap.electrode(selectedElectrodes);
fixedElectrodes.xpos = recording.processedMap.xpos(selectedElectrodes);
fixedElectrodes.ypos = recording.processedMap.ypos(selectedElectrodes);

tic
[axonTraces, electrodeGroups, timestamps, waveforms, baseline_noise] = mxw.axonalTracking.computeAxonTraces(recording, fixedElectrodes, 'SecondsToLoadPerIteration', 10, 'TotalSecondsToLoad', 'full', 'SpikeDetThreshold', thr_spikes, 'MaxDistClustering', 100);
toc

% filter units
for i = 1:length(timestamps{1})
    
    if length(timestamps{1}{i})<min_numb_spikes
        
        axonTraces.traces{i} = [];
        electrodeGroups{i} = [];
        
        
        for ii = 1:length(timestamps)
            timestamps{ii}{i} = [];
            waveforms{ii}{i} = [];
            baseline_noise{ii}{i} = [];
            
        end
            
        
    end
    
end


%% plot single neurons

close all;
for i = 1:length(electrodeGroups)
    
    if ~isempty(electrodeGroups{i})
    
    figure('color','w','position',[0 50 1400 600]);
    subplot(2,3,[1 2]);
    mxw.plot.axonTraces(axonTraces.map.x, axonTraces.map.y, axonTraces.traces{i}, 'PlotFullArea', false, 'PointSize', 150, 'PlotHeatMap', true, 'PlotWaveforms', true,'Figure', false,'Title',['Neuron Footprint #',num2str(i)],'Ylabel', '\muV');
    xlabel('\mum');ylabel('\mum');axis equal;
    [val1, ind] = min(axonTraces.traces{i},[],1);
    subplot(2,3,4);plot(axonTraces.traces{i}(:, ((val1<-6))),'k');ylabel('\muV');xlabel('Time [ms]')
    set(gca,'xtick',[0:10:size(axonTraces.traces{i},1)],'xticklabel',[(0:10:size(axonTraces.traces{i},1))/20])
    box off; title(['Averaged Waveforms Neuron #',num2str(i)]) 
    ylim([min(val1)*3 150])

    subplot(2,3,3);
    for j = 1:length(timestamps{1}{i})
    line([timestamps{1}{i}(j), timestamps{1}{i}(j)],[0.3 0.7],'color','k')    
    end
    xlabel('Time [s]');title('Single Neuron Time Stamps');box off;ylim([-3 4])
    set(gca,'ytick',[])
    
    % isi
    isi = [];
    for ii = 1:length(timestamps)
        isi = [isi diff(round(timestamps{ii}{i}*20000))/20];
        
    end
        
    subplot(2,3,5);   h = histogram(isi,0:1:30);    xlim([0 25]);    box off
    h.FaceColor = 'k'; h.EdgeColor = 'k'; h.FaceAlpha = 1;
    xlabel(['ISI [ms]']);ylabel('Counts')
    
    % waveform
    m = [];
    for j = 1:size(waveforms{1}{i},3)
        m = [m mean(min(waveforms{1}{i}(:,:,j)'))];
    end
    [val, ind] = min(m);
    
    subplot(2,3,6);
    plot(waveforms{1}{i}(:,:,ind)','k');hold on;plot(mean(waveforms{1}{i}(:,:,ind)),'r')
    ylabel('\muV'); set(gca,'xtick',[0:10:size(axonTraces.traces{i},1)],'xticklabel',[(0:10:size(axonTraces.traces{i},1))/20])
    box off;xlabel(['Time, [ms]'])
    title('Extracted Waveforms at Electrode with Larget Amplitude');hold on
    line([0 size(waveforms{1}{i}(:,:,ind),2)],[mean(baseline_noise{1}{i}(:,ind)) mean(baseline_noise{1}{i}(:,ind))],'color','r')
    ylim([min(val1)*3 150])

    end
    
end


%% make axon movie

close all;
neuron_id = 1;
firstSample = 1;
lastSample = 51;
str = date;
%adjust minimum and maximum values of the colorbar (in uV)
mini = 20; 
maxi = 20;

for p = neuron_id

   load('cmap_bluered.mat')
    

    xx = 0;
    dirName = sprintf(['/home/michelef/Desktop/axon_scans/',str,'/Cell_id', num2str(p)]);

    mkdir(dirName)
    for j=firstSample:lastSample
        
        xx=xx+1;
        
        clims=[-mini,maxi];
        colormap(mycmap./256)
        plot_2D_map_clean(axonTraces.map.x, axonTraces.map.y, axonTraces.traces{p,1}(j,:), clims, 'nearest');
        colorbar
        
        set(gca,'XTickLabel', '')
        set(gca,'YTickLabel', '')
        hold all
        
        
        xline = [max(axonTraces.map.x)-200,max(axonTraces.map.x)-100]; % 0.2 mm scale bar
        yline = [max(axonTraces.map.y)-10,max(axonTraces.map.y)-10];
     
        pl = line (xline,yline,'Color','w','LineWidth',5); % show scale bar
        txt = sprintf('%d ms', round((j-firstSample)/20)); 
        text(min(axonTraces.map.x)+50,max(axonTraces.map.y)-10,txt,'Color','w','FontSize',14); %show time
        hold off
        
        pictureName = [sprintf('%03d',xx)];
        
        savepng( 'Directory', dirName , 'FileName' , pictureName );
        
        
    end
    
    close(gcf)
end
  
