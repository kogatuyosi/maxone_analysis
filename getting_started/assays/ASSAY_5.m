%% ASSAY 5

% CORRELATION ASSAY, FUNCTIONAL CONNECTIVITY

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% XCORR function by Mark Humphries / Dayan, P & Abbott, L. F. (2001)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear
close all
%% variables

p = uigetdir;
d = mxw.fileManager(p);
d.removeSpikeArtifcats(300,50)
% Directory for saving results
resultsdir = '/home/mxwbio/Desktop/data/network';

% Thresholds for electrode selection
thr_spikerate = 1; % in Hz
thr_amplitude90perc = 25; % in uV
thr_amplitudestd = 25; % in uV
thr_isiV = 1; %in percentage %

binSize = 0.0005; % in ms. Bin size for detecting spike coincidence. 
duration = 0.02; % 0.2 = 200ms (length both lags together, i.e. duration/2 = lag). Time window across which the distribution is calculated. 

iter_jitter = 5;% number of iterations for jittering spike trains

%% exec
spikeRate = mxw.activityMap.computeSpikeRate(d);
amplitude90perc = abs(mxw.activityMap.computeAmplitude90percentile(d));
amplitudestd = mxw.activityMap.computeAmplitudestd(d);
isiv = mxw.activityMap.computeISIv(d);

idx = spikeRate>thr_spikerate & amplitude90perc>thr_amplitude90perc & amplitudestd<thr_amplitudestd & isiv<1;
disp(sum(idx))

if 1
figure('color','w','position',[100 100 1300 800]);hold on
subplot(241);histogram(spikeRate,100);line([thr_spikerate thr_spikerate],[0 100],'Color','r');box off;xlabel(['spike rate [Hz]'])
subplot(242);histogram(amplitude90perc,100);line([thr_amplitude90perc thr_amplitude90perc],[0 100],'Color','r');box off;xlabel(['amplitude 90perc [\muV]'])
subplot(243);histogram(amplitudestd,100);line([thr_amplitudestd thr_amplitudestd],[0 100],'Color','r');box off;xlabel(['amplitude std [\muV]'])
subplot(244);histogram(isiv,100);line([thr_isiV thr_isiV],[0 100],'Color','r');box off;xlabel(['isi violations 0-2 ms [%]'])
xlim([0 5])

subplot(2,4,[5 6]);
plot(d.fileObj.map.x,d.fileObj.map.y,'.k')
hold on;plot(d.fileObj.map.x(idx),d.fileObj.map.y(idx),'og')
hold on;xlabel('\mum');ylabel('\mum');axis equal;axis ij;

subplot(2,4,[7 8]);
ch = d.fileObj.map.channel(idx);
idx2 = ismember(d.fileObj.spikes.channel,ch);

Fs = d.fileObj.samplingFreq;
% find time stamps detected during recording (red triangles)
ts = double(d.fileObj.spikes.frameno - d.fileObj.firstFrameNum)/Fs;
% channel list, where spike time stamps where detected
ch = d.fileObj.spikes.channel;
%plot raster
plot(ts, ch,'.k');hold on;
plot(ts(idx2),ch(idx2),'+g')
box off; xlabel('time [s]');ylabel('channel')
title('raster plot')

end

x = d.fileObj.map.x(idx);
y = d.fileObj.map.y(idx);
ts = d.extractedSpikes.frameno(idx)';
centers = [x y];

% D1 = squareform(pdist(centers,'euclidean'));
D = mxw.util.pdist2(centers,centers,'euclidean'); % the same?


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate and validate Functional Connectivity
% Code adapted from Test_different_surrogates_v191218.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ccells = length(ts);
spk_time = []; ch_info = [];

for ch = 1:ccells
    time = (double(ts{ch}) - d.fileObj.firstFrameNum)/Fs;
    spk_time = [spk_time time]; % make giant vector with all spike times across all electrodes (in s)
    ch_info =  [ch_info ones(1,length(time))*ch]; % keep trach of electrode nr associated with all spike times
    c_ts = double(ts{ch}) - d.fileObj.firstFrameNum;
    c_ts(c_ts<0)=[];
    spks_data.raster(ch,:) = {c_ts};
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% General information
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

spks_data.binsize = 1;
spks_data.nbins = double(Fs*max(spk_time)); %(single-sample bins)
spks_data.nchannels = ccells;
spks_data.expsys = '';
spks_data.datatype = '';
spks_data.dataID = '';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate CCG; norm type = counts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[ccgR1,tR] = CCG(spk_time,ch_info,'binSize',binSize,'duration',duration);

range = 1:(duration*1000); %(in ms)
ccgR2 = ccgR1(range,:,:);

%mat = squeeze(mean(ccgR2,1));
mat = squeeze(max(ccgR2,[],1));
mat(1:length(mat)+1:end)=0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Jittering spike trains
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

parfor ITER = 1:iter_jitter; display(ITER)
    spks_times_rand_jit = randomizeasdf2(spks_data,'jitter','stdtime',200);
    spk_time_rand = []; ch_info_rand = [];
    for ch = 1:ccells
        time = [spks_times_rand_jit.raster{ch}/Fs];
        spk_time_rand = [spk_time_rand time];
        ch_info_rand = [ch_info_rand ones(1,length(time))*ch];
    end
    [ccgR1_rand,tR_rand] = CCG(spk_time_rand,ch_info_rand,'binSize',binSize,'duration',duration);
   
    ccgR2_rand = ccgR1_rand(range,:,:);
    %mat_rand = squeeze(mean(ccgR2_rand,1));
    mat_rand = squeeze(max(ccgR2_rand,[],1));
    mat_rand(1:length(mat)+1:end)=0;
    surr_mat(:,:,ITER) = mat_rand;
end

% figure;plot(spk_time(ch_info==1),ones(1,length(spk_time(ch_info==1))),'.k');hold on
% hold on;plot(spks_times_rand_jit.raster{1}/20000,ones(1,length(spks_data.raster{1})),'.r')
% (spks_times_rand_jit.raster{1}(1)) - spks_data.raster{1}(1)
% (spks_times_rand_jit.raster{1}(2)) - spks_data.raster{1}(2)
% (spks_times_rand_jit.raster{1}(3)) - spks_data.raster{1}(3)

thresh = mxw.util.percentile(surr_mat,95,3);
jitter_data.xcorr_wu = mat;
jitter_data.xcorr_bu = mat>thresh;
jitter_data.xcorr_surr_95pct = thresh;

% Save
save(fullfile(resultsdir,'net_jitter.mat'),'jitter_data');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

xcorr_wu = jitter_data.xcorr_wu;
xcorr_bu = jitter_data.xcorr_bu;
% D = tril(D);

figure('Position',[100 100 2000 800],'color','w');
% Plot XCORR
subplot(131); imagesc(xcorr_wu);
axis square
ylabel('neuron idx','Fontsize',12);
xlabel('neuron idx','Fontsize',12);
c = colorbar;ylabel(c, 'XCORR');caxis([0 prctile(xcorr_wu(:),90)]);
title(['XCORR (with ', num2str(duration*1000/2),' ms lag)'])

% Plot distance
subplot(132); imagesc(D);
axis square
ylabel('neuron idx','Fontsize',12);
xlabel('neuron idx','Fontsize',12);
c = colorbar;ylabel(c, '\mum');
title('Distance')

% Plot distance to sttc
dd = D;
ss = xcorr_wu;

dd = D(xcorr_bu);
ss = xcorr_wu(xcorr_bu);

% dd = D(:);% ss = xcorr_wu;
% idx = ss==0 | isnan(ss); dd(idx) = []; ss(idx) = [];
% ss_shuff = xcorr_bu(:); idx = ss_shuff==0 | isnan(ss_shuff); ss_shuff(idx) = [];

% subplot(133); 
% hold on; plot(dd,ss,'o','MarkerSize',5,'MarkerEdgeColor','k','MarkerFaceColor','white');
% set(gca, 'Box', 'off','TickDir', 'out','TickLength', [.02 .02]);
% axis square
% ylabel('XCORR','Fontsize',12);
% xlabel('Distance [um]','Fontsize',12);
% %ylim([0 prctile(xcorr_wu(:),90)+3])

% Plot XCORR
subplot(133); imagesc(xcorr_bu);
axis square
ylabel('neuron idx','Fontsize',12);
xlabel('neuron idx','Fontsize',12);
c = colorbar;ylabel(c, 'XCORR');caxis([0 1]);
title(['significant XCORR (with ', num2str(duration*1000/2),' ms lag)'])

figure('Position',[100 100 2000 800],'color','w');
subplot(121)
input_matrix = (xcorr_bu);
mxw.networkActivity.plot_network_connectivity(input_matrix,centers)
xlim([0 4000]);ylim([0 2200]);xlabel(['\mum']);ylabel(['\mum']);
xlabel('\mum');ylabel('\mum');
title('Connectivity Map')

subplot(122)
connect_per_neuron = sum(input_matrix,1);
connect_per_neuron(connect_per_neuron==0) = [];
h = histogram(connect_per_neuron,20);
h.FaceColor = 'k'; h.EdgeColor = 'k'; h.FaceAlpha = 1;
box off;ylabel('Counts');xlabel('Number of Connections per Neuron')
legend(['Mean Connections = ',num2str(mean(connect_per_neuron),'%.2f'), ' s sd = ',num2str(std(connect_per_neuron),'%.2f')])

figure('Position',[100 100 800 800],'color','w');
hold on; plot(dd,ss,'o','MarkerSize',5,'MarkerEdgeColor','k','MarkerFaceColor','white');
set(gca, 'Box', 'off','TickDir', 'out','TickLength', [.02 .02]);
axis square
ylabel('XCORR','Fontsize',12);
xlabel('Distance [um]','Fontsize',12);

clear
File 1