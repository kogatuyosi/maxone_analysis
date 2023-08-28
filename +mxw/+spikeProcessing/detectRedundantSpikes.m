function indToRemove=detectRedundantSpikes(fmObject,deltaSamples,deltaDist)


%% load spikes, prepare data

relativeSpikeTimes = mxw.util.computeRelativeSpikeTimes(fmObject);
spikeAmplitudes=abs(double(fmObject.fileObj.spikes.amplitude));

ts = relativeSpikeTimes.time;
chs = double(relativeSpikeTimes.channel);

[aa locs]= ismember(chs,chsConnected);
elPerSpike = els(locs);
xPerSpike = xpos(locs);
yPerSpike = ypos(locs);    
    
tsSamples = 20000*ts;


%% group spikes based on temporal proximity

a = [inf; diff(tsSamples)];
b = find(a<=deltaSamples);
d = find(a>deltaSamples);

gr=cell(0,0);
c=1;
for i=1:(length(d)-1)

    if (d(i+1)-d(i))>1
        
        iSt = d(i);
        iE = d(i+1)-1;
    gr{end+1}.iStart=iSt;
    gr{end}.iEnd=iE;
    
    gr{end}.ind=iSt:iE;
    gr{end}.tsS = tsSamples(iSt:iE);
    gr{end}.chs = chs(iSt:iE);
    gr{end}.els = elPerSpike(iSt:iE);
    gr{end}.pos = [xPerSpike(iSt:iE) yPerSpike(iSt:iE)];
    
    mm(i)=max(diff(tsSamples(iSt:iE)));
    
%     ones(size(iSt:iE))
    
    end
end


%% spatial proximity

% 1. subdivide electrodes in each group by spatial proximity
% 2. per group, only keep spike with highest amplitude value

indToRemove = [];

for i=1:length(gr)
    
    elGroups = mxw.util.groupElectrodes(gr{i}.pos,deltaDist);
    
    for j=1:length(elGroups)
        
        if length(elGroups{j})>1
            jInd = gr{i}.ind(elGroups{j});
        
            % keep electrode with largest amplitude
            [val iMax] = max(spikeAmplitudes(jInd));
            indRemove = jInd;
            jInd(iMax) = [];
            
            indToRemove = [indToRemove jInd];
        end
    end
    
end
    
