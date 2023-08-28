%% ASSAY 4

% MULTI-DAY BURST METRICS


%% variables

% set threshold to detect bursts
thr_burst = 1.5; % in rms
% set bin size
gaussian_bin_size = 0.1; % in seconds


% Set path to folder containing the recording
main_path = uigetdir;
cd(main_path)
f = dir;
c = 0;
dates =[];
for i = 3:length(f)
    c = c+1;
    dates{c} = [f(i).name];
end
%f = dir([main_path,'/',dates{1}]);

title2 = 'Assay_2';
prompt = 'Enter MEA chip number:';
answer = inputdlg(prompt,title2);

%% Network

MEAs_id = str2double(answer);

if exist(['',dates{1},'/',num2str(MEAs_id(1)),'/network/'],'dir')
    exp_type = 'network';
elseif exist(['',dates{1},'/',num2str(MEAs_id(1)),'/Network/'],'dir')
    exp_type = 'Network';
else
    error('No Network recording found')
end


Bu_amp = [];
Bu_IBI = [];

for chip_id = MEAs_id
    
    
    files = {};
    for i = 1:length(dates)
        files{i} = ['/',dates{i},'/',num2str(chip_id),'/',exp_type];
    end
    
    max_FR = 0;
    figure('color', 'w','position',[0 100 1450 700]);
    for i = 1:length(files)
        
        p = [main_path,files{i}];
        
        if exist(p,'dir')==7
            cd(p)
            f = dir;
            if length(f)>2
                networkAnalysisFile = mxw.fileManager(p);
                
                % Compute network activity
                networkAct = mxw.networkActivity.computeNetworkAct(networkAnalysisFile, 'BinSize', 0.02, 'file', 5,'GaussianSigma', gaussian_bin_size);
                networkStats = mxw.networkActivity.computeNetworkStats(networkAct, 'Threshold', thr_burst);
                
                max_FR = max([max_FR max(networkAct.firingRate)]);
                
                % POpulation Firing Rate
                subplot(3,length(dates),i)
                mxw.plot.networkActivity(networkAct, 'Threshold', thr_burst, 'Figure', false,'Title',[dates{i},'-',num2str(MEAs_id)]);box off;
                hold on;plot(networkStats.maxAmplitudesTimes,networkStats.maxAmplitudesValues,'or')
                xlim([0 floor(max(networkAct.time))-0.5])
%                 ylim([0 ylim_burst]) % needs to be fixed
                
                subplot(3,length(dates),i+length(dates))
                mxw.plot.networkStats(networkStats, 'Option', 'maxAmplitude',  'Figure', false, ...
                    'Ylabel', 'Counts', 'Xlabel', 'Burst Peak [Hz]', 'Title', '','Bins',20,'Color','g'); box off;
                legend(['Mean BP = ',num2str(mean(networkStats.maxAmplitudesValues),'%.1f'), ' HZ - sd = ',num2str(std(networkStats.maxAmplitudesValues),'%.1f')])
                xlim([mean(networkStats.maxAmplitudesValues)-std(networkStats.maxAmplitudesValues)*3 mean(networkStats.maxAmplitudesValues)+std(networkStats.maxAmplitudesValues)*3])

                subplot(3,length(dates),i+length(dates)*2)
                mxw.plot.networkStats(networkStats, 'Option', 'maxAmplitudeTimeDiff',  'Figure', false,...
                    'Ylabel', 'Counts', 'Xlabel', 'Interburst Interval [s]', 'Title', '','Bins',20,'Color','r'); box off;
                legend(['Mean IBI = ',num2str(mean(networkStats.maxAmplitudeTimeDiff),'%.1f'),' s - sd = ',num2str(std(networkStats.maxAmplitudeTimeDiff),'%.1f')])
                xlim([mean(networkStats.maxAmplitudeTimeDiff)-std(networkStats.maxAmplitudeTimeDiff)*3 mean(networkStats.maxAmplitudeTimeDiff)+std(networkStats.maxAmplitudeTimeDiff)*3])

                Bu_amp = [Bu_amp mean(networkStats.maxAmplitudesValues)];
                Bu_IBI = [Bu_IBI mean(networkStats.maxAmplitudeTimeDiff)];
                
            end
        end
        
    end
    
end

for i=1:length(dates)
    
    subplot(3,length(dates),i)
    ylim([0 max_FR]) 
    
end
                

figure('color','w','position',[100 100 400 400]);hold on
subplot(2,1,1)
bar(Bu_amp,'g')
ylim([0 max(Bu_amp)+10])
ylabel('Burst Peak [Hz]');box off
set(gca,'xtick',[])
subplot(2,1,2)
bar(Bu_IBI,'r')
ylim([0 max(Bu_IBI)+2])
set(gca,'xtick',1:length(dates),'xticklabel',dates)
ylabel('Interburst Interval [s]');box off

clear