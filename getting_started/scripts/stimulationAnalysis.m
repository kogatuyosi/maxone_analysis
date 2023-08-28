% Script to visualize and analyze stimulation triggered data

%% Load Stimulation File

% load recording containing electrical stimulation pulses
filenameStim = '/share/recordings/2591/MEX-44/Trace_20190605_12_10_44.raw.h5';
datainfoStim = mxw.fileManager(filenameStim);

% detect stimulation times
dac=datainfoStim.extractDAC;
stimTimes=find(diff(double(dac))>1);

% plot stimulation sequence08
fs=datainfoStim.fileObj.samplingFreq;
figure;plot((1:length(dac))/fs,dac);
hold on; plot(stimTimes/fs,dac(stimTimes),'rx')
xlabel('Time [s]')
ylabel('Stimulation pulse [bit]')

%% create neuron structure based on stimulation timings

% define pre/post time
pre = -10;
post = 80;
% by setting e.g. pre = -10, the signals are considered 10 samples after
% the stimulus. This way, the artifact can be omitted from the traces.


clear n_inputStim
n_inputStim.ts = stimTimes;
n_inputStim.fileObj=datainfoStim.fileObj;
n_inputStim.frame_no=n_inputStim.fileObj.firstFrameNum+n_inputStim.ts;
n_inputStim.sortEls=1;

stimNeur=mxw.neuronManager(n_inputStim);
stimNeur=stimNeur.extractTemplate('pre', pre, 'post',post);
stimNeur=stimNeur.extractTraces('pre', pre, 'post',post);

%% Plot Footprint

mxw.plot.axonTraces(stimNeur.x,stimNeur.y,stimNeur.template,...
    'PlotWaveforms',true,'WaveformWidth',1.5,'WaveformColor','k','Ylabel','Peak-to-peak Amplitude')
title(['']);

%% Optional: manually select some electrodes

% Run the following command
% Manually click on electrodes with axonal signals
% Start with electrode close to AIS
% When finished, press <Enter>

clear selEls

selEls = mxw.util.clickElectrodes(datainfoStim);

%% Plot Footprint & Traces

% set offset
yOffset=-150;

figure('color','w')
hold on

subplot(1,3,[1 2])
mxw.plot.axonTraces(stimNeur.x,stimNeur.y,stimNeur.template,...
    'PlotWaveforms',true,'WaveformWidth',1.5,'WaveformColor','k','Ylabel','Peak-to-peak Amplitude',...
    'Figure',false)
title(['Stimulus Triggered Average']);
box on
hold on

for i=1:length(selEls)
    
    ind = find(stimNeur.electrode==selEls(i));
    inds(i)=ind;
    plot(stimNeur.x(ind),stimNeur.y(ind),'rs','Linewidth',2)
    
end


subplot(1,3,3)

for i=1:length(selEls)
    
    ind = find(stimNeur.electrode==selEls(i));
    
    sig = stimNeur.traces{ind};
    plot((1:length(sig))/20, sig+ones(size(sig))*(i-1)*yOffset,'color', [0.6 0.6 0.6])
    hold on
    plot((1:length(sig))/20, mean(sig,2)+(i-1)*yOffset,'color', 'k','Linewidth',2)
    title('Traces')
end


%% Optional generate movie
map=datainfoStim.processedMap;

xlm=min(map.xpos);
xlma=max(map.xpos);
ylm=min(map.ypos);
ylma=max(map.ypos);

close all;

firstSample = 1;
lastSample = size(stimNeur.template,1);

str = date;
%adjust minimum and maximum values of the colorbar (in uV)
mini = 20;
maxi = 50;

load('cmap_bluered.mat')
xx = 0;

for j=firstSample:lastSample
    
    xx=xx+1;
    
    clims=[-mini,maxi];
    colormap(mycmap./256)
    plot_2D_map_clean(stimNeur.x, stimNeur.y, stimNeur.template(j,:), clims, 'nearest');
    xlabel('\mum');ylabel('\mum');axis equal;
    
    colorbar
    
    %         set(gca,'XTickLabel', '')
    %         set(gca,'YTickLabel', '')
    hold all
    
    
    xline = [max(stimNeur.x)-200,max(stimNeur.x)-100]; % 0.2 mm scale bar
    yline = [max(stimNeur.y)-10,max(stimNeur.y)-10];
    
%     pl = line (xline,yline,'Color','w','LineWidth',5); % show scale bar
%     txt = sprintf('%3.3f ms', (round((j-firstSample)/0.020)/1000));
    %         txt = sprintf('%d ms', round((j-firstSample)/20));
%     text(xlm+100,ylm+100,txt,'Color','w','FontSize',14); %show time
    hold off
    xlim([xlm xlma])
    ylim([ylm ylma])
    
    pictureName = [sprintf('%03d',xx)];
    
    mov(j) = getframe(gcf);
    
    
end

%% Save avi

dirName = cd;
recName = ['Stimulation_1']

clear myVideo

myVideo = VideoWriter([dirName '/' recName]);
myVideo.FrameRate = 4;  % Default 30

open(myVideo);

for m= 1:size(mov,2)
    
    if size(mov(m).cdata) == size(mov(end).cdata)
        try
            writeVideo(myVideo,mov(m));
        catch
            warning('Missing frames');
        end
        
    else
        
    end
end
close(myVideo);

