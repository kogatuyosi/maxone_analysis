function n_unit = UMS_sorter(filename, els, nEls, varargin)


p = inputParser;

p.addParameter('Length', []);
% p.addParameter('files', 1:this.nFiles);
p.parse(varargin{:});
args = p.Results;



%% Initialize & params

datainfo = mxw.fileManager(filename);

Fs = datainfo.fileObj.samplingFreq; % this is the sampling frequency of the MEA
thr_spikes = 5;



%% Step 1: Define fix els and neighbouring els

elsGroups=cell(1,length(els));

for i= 1:length(els)
    
    [neighEls, neighInd]=mxw.util.get_neighbouring_electrodes(els(i), datainfo, nEls);
    
    elsGroups{i}.fixEl=els(i);
    elsGroups{i}.neighEls=neighEls;
    
    elsGroups{i}.fixElInd=find(datainfo.fileObj.map.electrode==els(i));
    elsGroups{i}.neighElInd=neighInd;
    
    elsGroups{i}.allEls = [els(i) neighEls'];
    elsGroups{i}.allInd = [find(datainfo.fileObj.map.electrode==els(i)) neighInd];
    
end

%% Step 2: Initialize UMS-SpSo structures


umsGroup=cell(size(elsGroups));

for i=1:length(elsGroups)
    
    clear spikes
    spikes = ss_default_params(Fs);
    spikes.params.display.isi_bin_size = 0.2;
    spikes.params.refractory_period = 1.5;
    spikes.params.display.default_waveformmode = 2;
    spikes.params.thresh = thr_spikes; % spike detection threshold
    spikes.params.display.show_isi = 1;
    
    umsGroup{i}.spikes = spikes;
    umsGroup{i}.allEls = elsGroups{i}.allEls;
    umsGroup{i}.allInd = elsGroups{i}.allInd;
end

%% Step 2: Data loading and spike detection in chunks

% params

loadPos = 1;
data_chunk_size_in_seconds = 10;

chunk_info = {};

if isempty(args.Length)
    maxLen = datainfo.fileObj.dataLenSamples;
else
    maxLen = args.Length;
end

tic
while loadPos < maxLen
    
    lenToLoad= data_chunk_size_in_seconds*Fs;
    
    if loadPos+lenToLoad > maxLen
        lenToLoad = maxLen - loadPos;
    end
    
    [data, filesArray, electrodesArray] = datainfo.extractBPFData(loadPos, lenToLoad);
    
    chunk_info{end+1}.loadPos = loadPos;
    chunk_info{end}.lenToload = lenToLoad;
    
    for i=1:length(umsGroup)
        
        spikes = umsGroup{i}.spikes;
        BPFdataChannels = data(:,elsGroups{i}.allInd);
        spikes = ss_detect({BPFdataChannels},spikes);
        umsGroup{i}.spikes = spikes;
        
    end
    
    loadPos = loadPos+lenToLoad+1;
    disp(['Seconds loaded: ' num2str(round(loadPos/Fs)) '/' num2str(round(maxLen/Fs))]);
end
toc

%% for every electrode, run Splitmerge_tool

for i=1:length(umsGroup)
    if ~isempty(umsGroup{i}.spikes.spiketimes)
        spikes_tmp = umsGroup{i}.spikes;
        spikes_tmp = ss_align(spikes_tmp);
        spikes_tmp = ss_kmeans(spikes_tmp);
        spikes_tmp = ss_energy(spikes_tmp);
        spikes_tmp = ss_aggregate(spikes_tmp);
        
        evalin('base','clear spikes');
        splitmerge_tool(spikes_tmp)
        
        pause
        
        try
            spikes=evalin('base','spikes');
            umsGroup{i}.spikes = spikes;
        catch
            disp('No cluster selected')
        end
        
    end
end

%% now create a pseudo-neuron structure for each good unit

n_unit=[];

for i=1:length(umsGroup)
    if ~isempty(umsGroup{i}.spikes.spiketimes)
        spikes = umsGroup{i}.spikes;
        
        if isfield(spikes,'labels')
            good_units=spikes.labels(spikes.labels(:,2)==2,1);
            if ~isempty(good_units)
                for jj=1:length(good_units)
                    
                    % combine ts from individual chunks
                    unit_ts_ind=find(spikes.assigns==good_units(jj));
                    chunk_ts=spikes.spiketimes(unit_ts_ind)*Fs;
                    unit_chunk_ind=spikes.trials(unit_ts_ind);
                    
                    unit_ts=chunk_ts;
                    for k=1:length(chunk_info)
                        unit_ts(unit_chunk_ind==k) = chunk_ts(unit_chunk_ind==k)+chunk_info{k}.loadPos;
                    end
                    
                    % save unit info
                    N=length(n_unit)+1;
                    n_unit{N}.ts=unit_ts;
                    n_unit{N}.frame_no=datainfo.fileObj.firstFrameNum+unit_ts;
                    n_unit{N}.fileObj=datainfo.fileObj;
                    
                    % save detection electrodes
                    n_unit{N}.sortEls = umsGroup{i}.allEls;
                    n_unit{N}.sortInd = umsGroup{i}.allInd;
                    
                end
            end
        end
    end
end

