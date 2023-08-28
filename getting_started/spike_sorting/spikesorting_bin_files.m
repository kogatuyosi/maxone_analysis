%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% This script prepares the files to be analyzed with spike sorting
%%% And runs the spyking-circus spike sorter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear globvar;
close all

% Set the below directory for each sorting session
sortingDir  = '~/Desktop/Sorting/2018_Oct_30/';
analysisDir = '~/Desktop/Analysis/2018_Oct_30/';

% This is the path to the hdf52many conversion tool
conversionTool = '~/MaxLab/bin/hdf52many';

% Radius of electrode groups.
% By changing this number, you can change the approx. size of channel groups
radius = 100;

% This script can only sort one hdf5 file per time. Get in contact
% with MaxWell Biosystems AG (support@mxwbio.com) if you need to sort
% multiple recordings in one go. For example for retina experiments.

file_name = '~/Desktop/mxwbio/data/retina/Trace_20180619_03_47_05.raw.h5';

n_cores = 6;

%% Prepare the directories

mkdir (analysisDir)
mkdir (sortingDir)
cd (analysisDir)

%% Create electrode groups

% Extract mapping from the recording file
mapping = h5read(file_name, '/mapping');    % ask support@mxwbio.com why with old files it is 1024 and with new just the correct ones.

% Compute the electrode groups
[electrode_groups, channel_groups] = circus.electrodeGroups( mapping, radius );


%% Visualize  electrode groups

figure;hold on
for group = 1:length(electrode_groups)
    scatter( mapping.x(ismember( mapping.electrode, electrode_groups{group})) , mapping.y(ismember( mapping.electrode, electrode_groups{group})) , 'filled' )
end
hold off;
axis ij;
xlim([-100 4000]);ylim([-100 2000])
xlabel('[\mum]');ylabel('[\mum]');

%% Split data in chunks

tic
circus.saveElectrodeGroupsToFile( channel_groups , [sortingDir '/channel_groups.dat'] );
cmd = [conversionTool ' -i ' file_name ' -c ' sortingDir '/channel_groups.dat' ];
system( cmd )
toc


%% Spike Sort

spike_threshold = 8; % number of times based on baseline noise

tic
for group_idx = 1:length(channel_groups)  % For all the groups
    
    try
        lnDir = [sortingDir '/' num2str(group_idx,'%03d') '/'] ;
        mkdir(lnDir);
        
        probeFile  = [lnDir '/probe.prb'];
        paramsFile = [lnDir '/traces.params'];
        linkedFile = [lnDir '/traces.dat'];
        
        % Generate the Probe file for Spyking Circus
        circus.generateChannelProbe( probeFile, mapping, channel_groups{group_idx} , radius*2 );

        cmd = ['ln -s ' file_name '.' num2str(group_idx-1, '%03d') '.dat ' linkedFile];
        system(cmd)

        % Generate the Parameters File for Spyking Circus
       
        circus.generateParametersFile( paramsFile, probeFile, length(channel_groups{group_idx}), spike_threshold);

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Start Spike Sorting 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        sorting_cmd = ['spyking-circus ' linkedFile ' -c ' num2str(n_cores)];
        disp(sorting_cmd)
        system(sorting_cmd)
     
        % Run those lines after spike sorting finished
        % Split sorting result
        split_sorting_cmd = ['circus-multi ' linkedFile];
        disp(split_sorting_cmd)
        system(split_sorting_cmd)
    catch
    end

end
toc


%% Load sorted neuron time-stamps

spikeTimes = cell(1,length(electrode_groups));

for group_idx = 1:length(electrode_groups)
    
    
    pathToResults = [sortingDir,num2str(group_idx,'%03d'),'/traces/traces.result.hdf5'];
    fileLength = h5info(pathToResults);
    
    for nNeuron = 1:length(fileLength.Groups(1).Datasets)-1
        try
            spikeTimes{group_idx}{nNeuron} = double(h5read(pathToResults,['/spiketimes/temp_' num2str(nNeuron)]));
        catch
            continue;
        end
    end
    
    
end


%% Compute EAP and extract waveforms


f = circus.file(file_name);
m = h5read( file_name , '/mapping' ); 
prePointsSpike = 35;
postPointsSpike = 45;
idx = m.x>0;
waveformLength = prePointsSpike + postPointsSpike;
lsb = h5read( file_name, '/settings/lsb')*10e5;

axonTraces = [];c = 0;
figure('color','w','position',[100 100 1600 800])
for group_idx = 1:length(electrode_groups)

    for i = 1:length(spikeTimes{group_idx})
        c = c+1;
        ts = spikeTimes{group_idx}{i};
        nSpikes = min( 50 , length(ts) );
        axonTraces.ts{c} = ts;
        
        M1 = f.getCutouts( double(ts(1:nSpikes)) , prePointsSpike, postPointsSpike );
        M2 = reshape ( M1 , size(M1,1)/1024 , 1024 , size(M1,2) )*lsb;
        M3 = squeeze ( mean( M2 , 3 ) );
        M4 = M3 - repmat( mean( M3 )  , size(M3,1) , 1);
        
        clf
        subplot(2,2,1:2)
        mxw.plot.axonTraces(m.x, m.y , M4(:,m.channel+1),'PlotWaveforms', true,'Figure',false,'PlotHeatMap',false,'WaveformColor','k')
        title(['Group ' num2str(group_idx), ' / Neuron No. ' num2str(i) ' (' num2str(length(ts)) ' spikes)']);
        axis ij;box off;xlabel('\mum');ylabel('\mum');axis equal;
        [val, ind] = min(min(M4(:,m.channel+1)));
        axis( [(m.x(ind))-100 (m.x(ind))+100 (m.y(ind))-100 (m.y(ind))+100] )
        axonTraces.traces{c} = M4(:,m.channel+1);
        
        M2_connected = M2(:,idx,:);
        M4_connected = M4(:,idx);
        [~,el] = sort(min( M4_connected ));
        
        % Check the template on the 3 electrodes with the largest amplitudes
        subplot(2,2,3);plot(M4_connected(:,el(1:3)));
        set(gca,'xtick',[0:10:size(M4,1)],'xticklabel',[(0:10:size(M4,1))/20])
        title('Largest 3 Average Waveforms')
        box off;xlabel('Time [ms]');ylabel('\muV');
        
        % Check individual traces on the electrode with the largest amplitude
        raw_waveforms = (squeeze( M2_connected(:,el(1),:)));
        raw_waveforms = raw_waveforms -repmat( mean( raw_waveforms )  , size(raw_waveforms,1) , 1);
        subplot(2,2,4);plot(raw_waveforms)
        title('Extracted Waveforms at Electrode with Larget Amplitude');hold on
        set(gca,'xtick',[0:10:size(M4,1)],'xticklabel',[(0:10:size(M4,1))/20])
        box off;xlabel('Time [ms]');ylabel('\muV');
        axonTraces.raw_best_electrodes{c} = raw_waveforms;

        circus.savepng('Directory', [analysisDir,num2str(group_idx,'%03d'), '/grp_' num2str(group_idx,'%03d') '_spikeNo_' num2str(i,'%03d')] )

        
    end
    
    
end


axonTraces.map.x = m.x;
axonTraces.map.y = m.y;
axonTraces.map.electrode = m.electrode;
recording = mxw.fileManager(file_name);

save('sorted_neurons','axonTraces','recording')

