% This script runs executes the following steps:
%   - Run manual spike sorter UltraMegaSort on selected electrodes
%   - Plot footrpints of sorted cells
%   - Do manual selection of electrodes for visualizing axonal signals
%   - Plot traces of manual signals
%   - Perform linear fit on latency vs. distance graph to estimate
%     conduction velocity

clear all
clear classes
%% Input variables

% Download the files here:
% https://share.mxwbio.com/d/e93a970aa6514e8980db/

% % define recording file (high-resolution config)
% filename = '/Sample_Data/retinaFull.raw.h5';
% % define one or more electrodes for spike detection
% els = [930];

% % define recording file (sparse config)
% filename = '/Sample_Data/retina.raw.h5' ;
% % define one or more electrodes for spike detection
% els = [18711];


% define number of surrounding electrodes to consider for sorting
nEls = 2;

%% Create filemanager object & call manual spike sorter

datainfo = mxw.fileManager(filename);

n_unit = UMS_sorter(filename, els, nEls);

%% Build neuron structure & extract traces/templates

% Define number of samples to extract before and after the specific spike
% times.
pre = 20;
post = 80;

clear neurs
neurs = mxw.neuronManager(n_unit);
neurs = neurs.extractTemplate('pre',pre,'post',post);
neurs = neurs.extractTraces('pre',pre,'post',post);
      
%%  Plot footprints of sorted neurons



for ii=1:length(neurs)

    mxw.plot.axonTraces(neurs(ii).x,neurs(ii).y,neurs(ii).template,...
        'PlotWaveforms',true,'WaveformWidth',1.5,'WaveformColor','k','Ylabel','Peak-to-peak Amplitude')
   title(['Neuron ' int2str(ii)]);
   
end
 
%% Select axonal electrodes 

% Run the following command
% Manually click on electrodes with axonal signals
% Start with electrode close to AIS
% When finished, press <Enter>

clear axonEls

axonEls = mxw.util.clickElectrodes(datainfo);

%% Plot result
clearvars -except n_unit neurs datainfo axonEls

% select neuron
ii=1;


figure('Color','w')

subplot(1,5,[1 2])

mxw.plot.axonTraces(neurs(ii).x,neurs(ii).y,neurs(ii).template,...
     'PlotWaveforms',true, 'Figure', false,'WaveformWidth',1.5,'WaveformColor','k','Ylabel','Peak-to-peak Amplitude',...
     'HeatMapFeature','pkpkAmp')

hold on

for i=1:length(axonEls)

    ind = find(neurs(ii).electrode==axonEls(i));
    inds(i)=ind;
    plot(neurs(ii).x(ind),neurs(ii).y(ind),'rs','Linewidth',2)
    
end

box on; 

title('Neuron')

subplot(1,5,3)

yOffset = -150;

hold on

for i=1:length(axonEls)
    
    ind = find(neurs(ii).electrode==axonEls(i));

    sig = neurs(ii).traces{ind};
    plot((1:size(sig,1))/20, sig+ones(size(sig))*(i-1)*yOffset,'color', [0.6 0.6 0.6])
    hold on
    plot((1:size(sig,1))/20, mean(sig')+(i-1)*yOffset,'color', 'k', 'linewidth',2)
end
xlabel('Time [ms]')
box on

title({'Axon' 'Traces'})
set(gca,'YTickLabel',[])



subplot(1,5,[4 5])

tmpls=neurs(ii).template(:,inds);
[va, inn] = min(tmpls);
first_el = 1;

neur.x = neurs(ii).x(inds);
neur.y = neurs(ii).y(inds);
neur.lat = (inn-min(inn))/20;

[~, order] = sort(neur.lat); %ordering electrode in ascending latencies to check if selected order is right

neur.first_el = first_el;
neur.first_el_pos = [neur.x(first_el) neur.y(first_el)];
neur.dist_to_first_el = mxw.util.pdist2(neur.first_el_pos,[neur.x neur.y], 'euclidean');

for e= 1:length(axonEls)
    if e==1
       neur.dist_to_first_el_2(e)= 0;
    else
    neur.dist_to_first_el_2(e) = mxw.util.pdist2([neur.x(e) neur.y(e)], [neur.x(e-1) neur.y(e-1)], 'euclidean')+ neur.dist_to_first_el_2(e-1)
    end
end

% compute distaces to first el
% velocity plot
x2 = neur.lat';
y2 = neur.dist_to_first_el_2';

x = neur.lat';
y = neur.dist_to_first_el_2';

b1=x\y; % regression coefficient (velocity)

yCalc1 = b1*x; % slope

Rsq1 = 1 - sum((y - yCalc1).^2)/sum((y - mean(y)).^2);

vel(i)=round(b1);
Rs(i)=Rsq1;

% subplot(3,4,9+(i-1));
% figure('color','w')
scatter(x,y,'o')
xlabel('Latency [ms]')
ylabel('Distance [\mum]')
hold on
plot(x,yCalc1,'r')
title({['Velocity = ' num2str(round(b1/1000,2)) 'm/s'], ['R = ' num2str(round(Rsq1,2))]})
box on


