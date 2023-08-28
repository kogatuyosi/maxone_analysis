
% BURST PROPAGATION ANALYSIS

%% variables

% Path
clear all
pathToNetworkAnalysis = '/share/recordings/2714/MEX-29/190605/3704/Network/000010';
% Load data information
networkAnalysisFile = mxw.fileManager(pathToNetworkAnalysis);

% pathToNetworkAnalysis = '/share/recordings/2714/MEX-29/190605/3704/Network/000016';
% pathToNetworkAnalysis = 'C:\maxOne_data\testfolder_network';



%% Params for burst detection

% Threshold to detect bursts
args.thr_burst = 3; % in rms

% Bin size for spike counts
args.binSize = 0.01;
args.gaussianBinSize = 0.01; % in seconds

% threshold to find the start and stop time of the bursts,
args.thr_start_stop = 0.3; % 0.3 means 30% value of the burst peak

% define pre- and post-time to consider before and afer burst peak
args.prePeakTime = 0.1; % in seconds
args.postPeakTime = 0.1;

% If a second burst peak occurs within "postPeakIgnore" after another, ignore the second
args.postPeakIgnore = 0.5; % in seconds

% For every electrode, the initiation time is computed by averaging the
% times of the first "numSpikesTiming" spikes in the burst
args.numSpikesTiming = 2;


% The position of How many electrodes should be averaged to derive starting point
args.numElsToAverage = 5;

[burstVals, out] = mxw.burstPropagation.computeBurstValues(networkAnalysisFile,args);

%% Plot rasterplot if necessary, re-adjust params

% Which burst to individually show on the right side
burstId = 2;


figure('color', 'w','position',[0 100 1300 700]);

% Raster Plot
ax(1)=subplot(2, 3, [1 2]);
mxw.plot.rasterPlot(networkAnalysisFile, 'Figure', false);box off;
xlim([0 floor(max(out.networkAct.time))-0.5])
% Histogram gaussian convolution
ax(2)=subplot(2, 3, [4 5]);
mxw.plot.networkActivity(out.networkAct, 'Threshold', thr_burst, 'Figure', false);box off;
% hold on;plot(networkStats.maxAmplitudesTimes,networkStats.maxAmplitudesValues,'or')
hold on;plot(out.peakSel,out.ampSel,'or')

xlim([0 floor(max(out.networkAct.time))-0.5])
linkaxes(ax, 'x')
% %% Rasterplot

% figure('color', 'w','position',[0 100 500 700]);

% Raster Plot
ax(1)=subplot(2, 3, 3);
mxw.plot.rasterPlot(networkAnalysisFile, 'Figure', false);box off;
title('Single Burst')

xlim([out.peakSel(burstId)-prePeakTime out.peakSel(burstId)+postPeakTime])
% Histogram gaussian convolution
ax(2)=subplot(2, 3, 6);
mxw.plot.networkActivity(out.networkAct, 'Threshold', thr_burst, 'Figure', false);box off;
% hold on;plot(networkStats.maxAmplitudesTimes,networkStats.maxAmplitudesValues,'or')
hold on;plot(out.peakSel,out.ampSel,'or')
title('Single Burst')
xlim([out.peakSel(burstId)-prePeakTime out.peakSel(burstId)+postPeakTime])
linkaxes(ax, 'x')

%% Plot burst Latency

% Plotting parameters
latLimitAxis = 90; % percentile for limitin colorbar axis
max_sz = 60;


close all
% for i= [2 9]
for i= 1:5% 1:length(peakSel)
    
    numSpikes2 = burstVals{i}.numSpikes2;
    delValCon2 = burstVals{i}.delValCon2;
    
    scaleF = max_sz/max(numSpikes2);
    
    figure('color','w','Position',[680 200 660 698]);
    %     figure
    subplot(2,2,[1 2])
    % scatter(x2,y2,[],sz)
    scatter(burstVals{i}.x2,burstVals{i}.y2,round(numSpikes2*scaleF),delValCon2*1000,'filled')%,'MarkerEdgeColor','k')
    hold on
    plot(burstVals{i}.xCenter,burstVals{i}.yCenter,'kx','Markersize',10,'Linewidth',2)
    plot(burstVals{i}.xCenter,burstVals{i}.yCenter,'ko','Markersize',10,'Linewidth',2)
    
    colorbar
    axis ij
    axis equal
    xlim([-50 4000])
    ylim([-50 2050])
    box on
    xlabel('X-coordinate')
    ylabel('Y-coordinate')
    %     zlabel('Latency [ms]')
    title(['Burst Time ' num2str(peakSel(i)) ' s'])
    colormap jet
    h = colorbar;
    ylabel(h, 'Latency [ms]')
    minDel = mxw.util.percentile(delValCon2*1000,0.5);
    maxDel = mxw.util.percentile(delValCon2*1000,latLimitAxis);
    caxis([minDel maxDel])
    
    
    % Raster-Plot
    
    %     tsBurst = burstVals{i}.ts(chsConnected);
    %     tsBurst2 = tsBurst(keep);
    
    
    subplot(223)
    plot(burstVals{i}.tsPerCh(:,2),burstVals{i}.tsPerCh(:,3),'k.')
    xlabel('Time [s]')
    ylabel('X-coordinate')
    
    subplot(224)
    plot(burstVals{i}.tsPerCh(:,2),burstVals{i}.tsPerCh(:,4),'k.')
    xlabel('Time [s]')
    ylabel('Y-coordinate')
    
end



%% New metric: Burst velocity

do_plot = 0;

percentileMin = 10;
percentileMax = 90;
% close all

for i= 1:length(peakSel)
    
    
    numSpikes2 = burstVals{i}.numSpikes2;
    delValCon2 = burstVals{i}.delValCon2;
    
    
    
    minDel = mxw.util.percentile(delValCon2,percentileMin);
    maxDel = mxw.util.percentile(delValCon2,percentileMax);
    
    indSubset = find(delValCon2 > minDel & delValCon2 < maxDel);
    
    % recalc burst center:
    [delSorted, indSorting] = sort(delValCon2(indSubset));
    
    x3=burstVals{i}.x2(indSubset);
    y3=burstVals{i}.y2(indSubset);
    
    xCenter2 = mean(x3(indSorting(1:10)));
    yCenter2 = mean(y3(indSorting(1:10)));
    
        
    % Compute distances between burst center and all els
%      d = mxw.util.pdist2([burstVals{i}.xCenter burstVals{i}.yCenter],[burstVals{i}.x2 burstVals{i}.y2],'euclidean');
     d = mxw.util.pdist2([xCenter2 yCenter2],[burstVals{i}.x2 burstVals{i}.y2],'euclidean');
        
    x = delValCon2(indSubset)';
    y = d(indSubset)';
    
    % include intercept
    X = [ones(length(x),1) x];
    b=X\y; % regression coefficioent (velocity)
    
    
    yCalc1 = b(1)+b(2)*x; % slope
    
    Rsq1 = 1 - sum((y - yCalc1).^2)/sum((y - mean(y)).^2);
    
    % vel(i)=round(b1);
    Rs(i)=Rsq1;
    
    if do_plot
        figure('color','w')
        scatter(delValCon2,d,'x')
        hold on
        scatter(x,y,'o')
        xlabel('Latency [ms]')
        ylabel('Distance [\mum]')
        hold on
        plot(x,yCalc1,'k')
        title({['Velocity = ' num2str(round(b(2)/1000,2)) 'm/s'], ['R = ' num2str(round(Rsq1,2))]})
        box on
    end
    
    vel(i)=b(2)/1000;
    R(i) = Rsq1;
    
    burstVals{i}.v=b(2);
    burstVals{i}.R=Rsq1;
    
end

figure;plot(R,vel,'x')
xlabel('R')
ylabel('Burst velocity')


%%

xCenter = out.xCenter;
yCenter = out.yCenter;
peakSel = out.peakSel;
figure('color','white');
scatter(xCenter, yCenter,[],peakSel,'filled')
% scatter(xCenter, yCenter,[],numSpikesCon,'filled')

% colorbar
axis ij
axis equal
xlim([-50 4000])
ylim([-50 2050])
box on
xlabel('X-coordinate')
ylabel('Y-coordinate')

title('BIC')
% colormap jet
h = colorbar;
ylabel(h, 'Burst Time [s]')
% maxDel = mxw.util.percentile(delValCon2*1000,latLimitAxis);
% caxis([0 maxDel])
