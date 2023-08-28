%% Simple Spike Sorting for Axon Scan Folder
clear all;close all;clc;

%% variables

% Set path to folder containing the recordings
path = '/net/bs-filesvr02/export/group/hierlemann/recordings/Mea1k/nleary/170714/1404/axon';
% percentage of active electrode to sort
activityThreshold = 5;

% threshold to select sorted units, minimum number of spikes
min_numb_spikes = 20;

% threshold for spike detection, in std 
thr_spikes = 15;

% electrode clustering radius
radius_in_um = 50;

% path where to save output
path_save = '/home/michelef/';
file_name = 'axonscan';

%% execute

% Load data information
fullScanFolder = mxw.fileManager(path);

% find common electrodes between first 2 configs, it assumes fixed
% electrodes will be identical for the remaining ~ 30 folders
a = [];
for i = 1:fullScanFolder.nFiles-1
    if i==1
        a{i} = intersect(fullScanFolder.rawMap(i).map.electrode, fullScanFolder.rawMap(i+1).map.electrode);
    else
        a{i} = intersect(a{i-1}, fullScanFolder.rawMap(i+1).map.electrode);
    end
end
c = a{end};


axonTrackElec.xpos = [];
axonTrackElec.ypos = [];
axonTrackElec.electrodes = [];
for i = 1:length(c)
   
    axonTrackElec.xpos = [axonTrackElec.xpos; fullScanFolder.processedMap.xpos(fullScanFolder.processedMap.electrode==c(i))];
    axonTrackElec.ypos = [axonTrackElec.ypos; fullScanFolder.processedMap.ypos(fullScanFolder.processedMap.electrode==c(i))];
    axonTrackElec.electrodes = [axonTrackElec.electrodes; c(i)];
   
end

figure('color','w');plot(axonTrackElec.xpos , axonTrackElec.ypos, '.r');axis ij;axis equal
xlabel('\mum');ylabel('\mum');xlim([-200 4100]);ylim([-100 2200])

tic
[axonTraces, electrodeGroups, timestamps, waveforms, baseline_noise] = mxw.axonalTracking.computeAxonTraces(fullScanFolder, axonTrackElec, 'SecondsToLoadPerIteration', 20, 'TotalSecondsToLoad', 'full', 'SpikeDetThreshold', thr_spikes, 'MaxDistClustering', radius_in_um);
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

cd(path_save)
save(file_name,'axonTraces', 'electrodeGroups', 'timestamps', 'waveforms', 'baseline_noise')

%% plot single neurons

close all;
for i = 1:length(electrodeGroups)
    
    if ~isempty(electrodeGroups{i})
    
    figure('color','w','position',[0 50 1500 700]);
    subplot(2,3,[1 2]);
    mxw.plot.axonTraces(axonTraces.map.x, axonTraces.map.y, axonTraces.traces{i}, 'PlotFullArea', false, 'PointSize', 150, 'PlotHeatMap', true, 'PlotWaveforms', false,'Figure', false,'Title',['Neuron Footprint #',num2str(i)],'Ylabel', '\muV');
    xlabel('\mum');ylabel('\mum');axis equal;
    [val1, ind] = min(axonTraces.traces{i},[],1);
    [val2, ind] = max(axonTraces.traces{i},[],1);

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
    
    w = [];
    for ii = 1:length(timestamps) - 1
        w = [w; waveforms{ii}{i}(:,:,ind)];
        
    end
    
    subplot(2,3,6);
    plot(w','k');hold on;plot(mean(w),'r')
    ylabel('\muV'); set(gca,'xtick',[0:10:size(axonTraces.traces{i},1)],'xticklabel',[(0:10:size(axonTraces.traces{i},1))/20])
    box off;xlabel(['Time, [ms]'])
    title('Extracted Waveforms at Electrode with Larget Amplitude');hold on
    line([0 size(waveforms{1}{i}(:,:,ind),2)],[mean(baseline_noise{1}{i}(:,ind)) mean(baseline_noise{1}{i}(:,ind))],'color','r')
    ylim([min(val1)*3 150])

    end
    
end


%% make axon movie

close all;
neuron_id = 40;
firstSample = 1;
lastSample = 51;
str = date;
mini = 10;
maxi = 10;

for p = neuron_id

   load('cmap_bluered.mat')
    
    %adjust minimum and maximum values of the colorbar (in uV)

    xx = 0;
    dirName = sprintf(['/home/michelef/Desktop/axon_scans/',str,'/Cell_id', num2str(p)]);

    mkdir(dirName)
    for j=firstSample:lastSample
        
        xx=xx+1;
        
        clims=[-mini,maxi];
        colormap(mycmap./256)
        plot_2D_map_clean(axonTraces.map.x, axonTraces.map.y, axonTraces.traces{p,1}(j,:), clims, 'nearest');
        
        set(gca,'XTickLabel', '')
        set(gca,'YTickLabel', '')
        hold all
        
        xline = [max(axonTraces.map.x)-500,max(axonTraces.map.x)-100]; % 1 mm scale bar
        yline = [max(axonTraces.map.y)-100,max(axonTraces.map.y)-100];
     
        pl = line (xline,yline,'Color','w','LineWidth',5); % show scale bar
        txt = sprintf('%d ms', round((j-firstSample)/20)); 
        text(min(axonTraces.map.x)+50,max(axonTraces.map.y)-100,txt,'Color','w','FontSize',14); %show time
        hold off
        
        pictureName = [sprintf('%03d',xx)];
        
        savepng( 'Directory', dirName , 'FileName' , pictureName );
        
        
    end
    
    close(gcf)
end
  