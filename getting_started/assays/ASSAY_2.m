%% ASSAY 2

% MULTI-DAY ACTIVITY QUANTIFICATION




%% variables

% Thresholds
thr_spike_rate = 0.05;
thr_amp = 25;

% Paths
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

%% SCAN


MEAs_id = str2double(answer);

if exist(['',dates{1},'/',num2str(MEAs_id(1)),'/scan/'],'dir')
    exp_type = 'scan';
elseif exist(['',dates{1},'/',num2str(MEAs_id(1)),'/Activity_Scan/'],'dir')
    exp_type = 'Activity_Scan';
else
    error('No Activity Scan found')
end

m_Hz = [];
m_uV = [];
m_pct = [];

for chip_id = MEAs_id
    
    
    files = {};
    for i = 1:length(dates)
        files{i} = ['/',dates{i},'/',num2str(chip_id),'/',exp_type];
    end
    
    
    figure('color','w','position',[10 100 1400 720]);c = 0;
    for i = 1:length(files)
        
        p = [main_path,files{i}];
        
        if exist(p,'dir')==7
            cd(p)
            f = dir;
            if length(f)>2
                fullScanFolder = mxw.fileManager(p);
                
                spikeRate = mxw.activityMap.computeSpikeRate(fullScanFolder);
                amplitude90perc = abs(mxw.activityMap.computeAmplitude90percentile(fullScanFolder));
                idx = (spikeRate>thr_spike_rate & amplitude90perc>thr_amp);
                
                subplot(3,length(dates),i)
                mxw.plot.activityMap(fullScanFolder, spikeRate,'Ylabel', 'Hz', 'CaxisLim', [0 2],'Figure',false,'colormap','parula');
                if i==1
                    line([300 800],[2000+400 2000+400],'Color','k','LineWidth',5);
                    text(340,2100+500,'0.5 mm','color','k');
                end
                axis off; xlim([200 3750]);ylim([150 2600])
                title(['MFR = ', num2str(mean(spikeRate(idx)),'%.2f'),'Hz']);
                m_Hz = [m_Hz mean(spikeRate(idx))];
                
                
                if i<length(files)
                    c = colorbar;c.Ticks = [];
                end
                
                subplot(3,length(dates),i+length(dates)*2)
                mxw.plot.activityMap(fullScanFolder, double(idx), 'Ylabel', '','Figure',false,'Title',['Active Elctrodes = ',num2str((sum(idx)/length(idx))*100,'%.2f'),' %'],'colormap','parula');
                xlim([200 3750]);ylim([150 2500])
                m_pct = [m_pct (sum(idx)/length(idx))*100];
                if i<length(files)
                    c = colorbar;c.Ticks = [];
                else
                    c = colorbar;c.Ticks = [0 1];
                end
                set(gca,'Xtick',[],'Ytick',[])
                ax = gca; ax.XColor = [0 0 0];ax.YColor = [1 1 1];
                xlabel([dates{i},'-',num2str(MEAs_id)])
                
                idx = (spikeRate>thr_spike_rate); % might need to be changed
                subplot(3,length(dates),i+length(dates))
                mxw.plot.activityMap(fullScanFolder, amplitude90perc, 'Ylabel', '\muV', 'CaxisLim', [ 20 60], 'Figure',false,'RevertColorMap', true ,'colormap','parula' );
                xlim([200 3750]);ylim([150 2500]);axis off;
                title(['MSA = ', num2str(mean(amplitude90perc(idx)),'%.2f'),'\muV']);
                m_uV = [m_uV mean(amplitude90perc(idx))];
                if i<length(files)
                    c = colorbar;c.Ticks = [];
                end
                
                
                
            end
        end
        
    end
    
end


figure('color','w','position',[10 100 400 720]);hold on
subplot(3,1,1)
bar(m_Hz,'b')
ylim([0 max(m_Hz)+0.1])
ylabel('MFR [Hz]');box off
set(gca,'xtick',[])
subplot(3,1,2)
bar(m_uV,'g')
ylim([0 max(m_uV)+3])
ylabel('MSA [\muV]');box off
set(gca,'xtick',[])
subplot(3,1,3)
bar(m_pct,'r')
ylim([0 max(m_pct)+10])
set(gca,'xtick',1:length(dates),'xticklabel',dates)
ylabel('Active Area [%]');box off

clear