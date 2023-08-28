%% Spike sorting
clear all;close all;clc
% This Matlab script sets and runs Spyking Circus

% Important: Spyking Circus has to be properly installed to run this
% script

%% variables
% Set path to directories
sortingBaseDir  = '/home/michelef/Desktop/Sorting_wt';
analysisDir = '/home/michelef/Desktop/Sorting/Analysis';

% Set path to file
fname = {};
%fname{end+1} = '/home/michelef/CTI_mxwbio_BEL/mxwbio/data/neuron/Trace_20180709_10_28_49.raw.h5';
%fname{end+1} = '/local0/tmp/pop_1449.raw.h5'; % wt

%fname{end+1} = '/net/bs-filesvr02/export/group/hierlemann/recordings/Mea1k/nleary/170714/1449/network'; % wt
fname{end+1} = '/net/bs-filesvr02/export/group/hierlemann/recordings/Mea1k/nleary/170714/1443/network'; % a53t



% Set path to parameters
default_parameters_file = '/home/michelef/CTI_mxwbio_BEL/mxwbio/share/parameters.params';

%Detect Operating System
os = mxw.util.os.detect();

% Create file manager
recording = mxw.fileManager(cell2mat(fname));

% Making groups of electrodes
radius = 50;
electrode_groups = mxw.util.electrodeGroups(recording, radius);

% channel_group_1443 = [];checlk_list = [];
% for i = 1:length(electrode_groups)
%     
%     ch = [];
%     for j = electrode_groups{i}'
%         ch = [ch recording.fileObj.map.channel(recording.fileObj.map.electrode==j)];
%     end
%     checlk_list = [checlk_list ch];
%     
%     channel_group_1443{i} = ch;
% end


%% Running Spyking Circus in group of electrodes

for group_idx = 1%:length(electrode_groups)  % For all the groups
    tic
    copyDir = [sortingBaseDir filesep num2str(group_idx,'%03d') filesep] ;
    copyName = 'traces';
    mkdir(copyDir);
    mxw.util.generateProbe( [copyDir 'probe.prb'] , recording , electrode_groups{group_idx} , radius*2 );

    for f_idx = 1:length(fname)
        system([os.copy fname{f_idx} ' ' copyDir copyName '_' num2str(f_idx-1, '%02d') '.h5'])
    end
    
    %% Modify parameters
    
    % Prepare the parameter (.params) file
    sed_cmd = ['sed ''/EXAMPLE_MAPPING/c\mapping = ' copyDir '/probe.prb'' ' default_parameters_file ' > ' copyDir '/traces_00.params'];
    disp(sed_cmd);
    system(sed_cmd);
    
    %%
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Start Spike Sorting 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    sorting_cmd = ['spyking-circus ' copyDir 'traces_00.h5 -c 5'];
    disp(sorting_cmd)
    system(sorting_cmd)
        
    % Run those lines after spike sorting finished
    % Split sorting result
    split_sorting_cmd = ['circus-multi ' copyDir 'traces_00.h5'];
    disp(split_sorting_cmd)
    system(split_sorting_cmd)
    
    % Remove temporarily copied files
    remove_files_cmd = [os.delete copyDir 'traces_*.h5'];
	disp(remove_files_cmd);
    system(remove_files_cmd);
    toc
    disp(group_idx)
    disp(length(electrode_groups))
end

%% plot sorted neurons

f_idx = 1;  % which of the input files to analyze, in this script there is only one input file.
close all;

for group_idx = 12%:length(electrode_groups)
    
    for nTmpl = 1:1000
        figure('color','w','position',[0 0 2000 2000]);

        copyDir = [sortingBaseDir filesep num2str(group_idx,'%03d') filesep] ;
        results_file = [copyDir 'traces_00' filesep 'traces_00.result_' num2str(f_idx-1) '.hdf5'];
       
        try
            ts = h5read( results_file, ['/spiketimes/temp_' num2str(nTmpl)] );
        catch
            disp('No more templates');
            break;
        end
         
        f = mxw.fileManager(fname{f_idx});
        nSpikes = min( 50 , length(ts) );
        
        if nSpikes < 15
            continue
        end
        
        prePointsSpike = 35;
        postPointsSpike = 45;
        waveformLength = prePointsSpike + postPointsSpike;
        
        [waveforms, electrodes] = f.extractCutOuts( double(ts(1:nSpikes)) , prePointsSpike, postPointsSpike);
        
        reshapedWaveforms = reshape ( waveforms , waveformLength, size(waveforms,1)/waveformLength , size(waveforms,2) );
        meanWaveforms = ( squeeze ( mean( reshapedWaveforms , 3 ) ) )';
        M4 = meanWaveforms(:,1:waveformLength) - repmat( mean( meanWaveforms(:,1:waveformLength) )  , size(meanWaveforms(:,1:waveformLength), 1) , 1);
        M4 = M4';
        
        subplot(2,2,1:2)
        mxw.plot.waveforms( f.rawMap.map.x, f.rawMap.map.y, M4 , 'Color' , [0 0 0] )
        title(['Group ' num2str(group_idx), ' / Footprint No. ' num2str(nTmpl) ' (' num2str(length(ts)) ' spikes)']);
        axis ij;box off;xlabel('\mum');ylabel('\mum');axis equal;axis ij;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Check how clean the sorting is
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % only keep connected channels (idx)
%         M2_connected = reshapedWaveforms(:,idx,:);
%         M4_connected = M4(:,idx);
        [~,el] = sort(min(M4));
        
        % Check the template on the 3 electrodes with the largest amplitudes
        subplot(2,2,3);plot(M4(:,el(1:3)),'k');  
        set(gca,'xtick',[0:10:size(M4,1)],'xticklabel',[(0:10:size(M4,1))/20])

        title('Largest 3 Average Waveforms')
        box off;xlabel('Time [ms]');ylabel('\muV');

        % Check individual traces on the electrode with the largest amplitude
        subplot(2,2,4);plot(squeeze( reshapedWaveforms(:,el(1),:)),'k')
        title('Extracted Waveforms at Electrode with Larget Amplitude');hold on
        set(gca,'xtick',[0:10:size(M4,1)],'xticklabel',[(0:10:size(M4,1))/20])
        box off;xlabel('Time [ms]');ylabel('\muV');

        % Save this to a file
        mxw.util.savePNG('Directory', analysisDir, 'FileName' , ['grp_' num2str(group_idx,'%03d') '_spikeNo_' num2str(nTmpl,'%03d')] )
    end
end


%% gest spike times

pathToResults = '/home/michelef/Desktop/Sorting/012/traces_00/traces_00.result.hdf5';

fileLength = h5info(pathToResults);

spikeTimes = cell(length(fileLength.Groups(1).Datasets),1);

for nNeuron = 1:length(fileLength.Groups(1).Datasets)
    
    try
        spikeTimes{nNeuron} = h5read(pathToResults,['/spiketimes/temp_' num2str(nNeuron)]);
    catch
        continue;
    end
    

end