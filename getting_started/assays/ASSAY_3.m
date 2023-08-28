%% ASSAY 3

% BURST METRICS

%% variables

% Path
[FileName,PathName,FilterIndex] = uigetfile('*.raw.h5');
fullPath = [PathName FileName];

% check for multiwell
testFileMan = mxw.fileManager(fullPath,1);
try
    wellsInfo = h5info(testFileMan.fileNameList{1},'/wells/');
end

clear networkAnalysisFile
if exist('wellsInfo')
    
    well_labels = {wellsInfo.Groups.Name};
    if length(well_labels)>1
        [indx,tf] = listdlg('ListString',well_labels);
        
        if tf == 1
            for j= 1:length(indx)
                networkAnalysisFile{j} = mxw.fileManager(fullPath,indx(j));
            end
        end
    else
        networkAnalysisFile{1} = mxw.fileManager(fullPath,1);
    end
else
    networkAnalysisFile{1} = mxw.fileManager(fullPath);
end


%%

% Bin size for spike counts
bin_size = 0.02;
% Threshold to detect bursts
thr_burst = 1.2; % in rms
% Gamma of Gaussian to convolve
gaussian_gamma = 0.3; % in seconds
% threshold to find the start and stop time of the bursts,
thr_start_stop = 0.3; % 0.3 means 30% value of the burst peak

%% execute

% Load data information

for j=1:length(networkAnalysisFile)
    
    % Compute network activity
    networkAct = mxw.networkActivity.computeNetworkAct(networkAnalysisFile{j}, 'BinSize', bin_size, 'file', 1,'GaussianSigma', gaussian_gamma);
    networkStats = mxw.networkActivity.computeNetworkStats(networkAct, 'Threshold', thr_burst);
    
    % Plotting:
    if isprop(networkAnalysisFile{j}.fileObj,'wellID')
        figName = ['Well ' num2str(networkAnalysisFile{j}.wellID)];
    else
        figName='';
    end
    
    figure('color', 'w','position',[0 100 1300 700]);
    sgtitle(figName)
    
    % Raster Plot
    ax(1)=subplot(2, 3, 1);
    mxw.plot.rasterPlot(networkAnalysisFile{j}, 'file', 1, 'Figure', false);box off;
    xlim([0 floor(max(networkAct.time))-0.5])
    ylim([0 length(networkAnalysisFile{j}.fileObj.map.channel)])
    % Histogram gaussian convolution
    ax(2)=subplot(2, 3, 4);
    mxw.plot.networkActivity(networkAct, 'Threshold', thr_burst, 'Figure', false);box off;
    hold on;plot(networkStats.maxAmplitudesTimes,networkStats.maxAmplitudesValues,'or')
    xlim([0 floor(max(networkAct.time))-0.5])
    linkaxes(ax, 'x')
    
    if length(networkStats.maxAmplitudesTimes)>2
        
        
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
        % Burst Amplitudes
        amp = networkStats.maxAmplitudesValues';
        % Burst Times
        peak_times = networkStats.maxAmplitudesTimes;
        
        edges = [];
        for i = 1:length(amp)
            % take a sizeable (±6 s) chunk of the network activity curve 
             % around each burst peak point            
            idx = networkAct.time>(peak_times(i)-6) & networkAct.time<(peak_times(i)+6);
            t1 = networkAct.time(idx);
            a1 = networkAct.firingRate(idx)';
            
            % get the amplitude at the desired peak width
            peakWidthAmp = (amp(i)-round(amp(i)*thr_start_stop));
            % get the indices of the peak edges
            idx1 = find(a1<peakWidthAmp & t1<peak_times(i));
            idx2 = find(a1<peakWidthAmp & t1>peak_times(i));
            
            %         if ~isempty(idx1) && ~isempty(idx2)
            %         t_before = [];
            %         t_after = [];
            %
            %         else
            
            if ~isempty(idx1) && ~isempty(idx2)
                t_before = t1(idx1(end));
                t_after = t1(idx2(1));
                %         end
                edges = [edges; t_before t_after];
            end
        end
        
        subplot(2, 3, 1);
        hold on;
        for i = 1:length(edges)
            line([edges(i,1),edges(i,1)],[0 length(networkAnalysisFile{j}.fileObj.map.channel)],'Color','b')
            line([edges(i,2),edges(i,2)],[0 length(networkAnalysisFile{j}.fileObj.map.channel)],'Color','r')
        end
        
        % identify spikes that fall within the bursts   
        ts = ((double(networkAnalysisFile{j}.fileObj(1).spikes.frameno) - double(networkAnalysisFile{j}.fileObj(1).firstFrameNum))/networkAnalysisFile{j}.fileObj(1).samplingFreq)';
        ch = networkAnalysisFile{j}.fileObj(1).spikes.channel;
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
    pause(3)
end

clear