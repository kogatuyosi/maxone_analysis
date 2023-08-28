cd ~/Desktop/mxwbio/data/retina/20180918_P103/
clear;clc

%% LOAD spike sorting output and light stimulation time stamps

load R.mat
load stimulus.mat
cd ..

%1) 25x repetition of ON-OFF alternation of 2 seconds
stimulus_type{1} = [ones(25,1); zeros(25,1)]; % 1 = ON 0 = OFF
%2) 6x repetition of a marching square paradigm of a 5x5 checkerboard
stimulus_type{2} = [ repmat([ones(1,25); 1:25 ],1,6)'; repmat([zeros(1,25); 1:25],1,6)' ]; % first column 1 = ON 0 = OFF | second column indicates square position in the 5x5 matrix 1-25
% [ 1 2 3 4 5
%  6 7 8 9 10
%  11 12 13 14 15
%  16 17 18 19 20
%  21 22 23 24 25]
%3 6x repetition of a moving bar paradigm
stimulus_type{3} = repmat([ 45    90   180   225   315     0   135   270],1,6);
%4 6x repetition of the moving grating
stimulus_type{4} = repmat([ 45    90   180   225   315     0   135   270],1,6);

%5 15 minutes of white noise recording
stimulus_type{5} = hdf5read('~/Desktop/mxwbio/data/retina/20180918_P103//white_noise_movie_50um_15min.hdf5','colors');


clearvars -except R stimulus stimulus_type

%% PLOT and EXTRACT light time stamps

%figure('color','w','position',[100 100 1300 600]);
for i = 1:length(stimulus)
    %subplot(2,length(stimulus),i)
    figure('color','w','position',[100 100 1300 600]);
    plot(stimulus{i}.time,stimulus{i}.bits,'.');hold on;
    xlabel('frame');ylabel('light time stamp')
    if i==3;ylim([-2 2]);else;ylim([6 10]);end
    
    if i==1 || i==2
        %25x repetition of ON-OFF alternation of 2 seconds
        % 6x repetitions of marching square paradigm of a 5x5 checkerboard
        if i==1; title('Full Field ON-OFF');elseif i==2;title('Marching Square');end
        ts = stimulus{i}.time(stimulus{i}.bits == 9);
        
        ts(1) = [];
        %subplot(1,length(stimulus),i)
        plot(ts,ones(1,length(ts))*9,'.r');hold on;
        idx = diff(ts)>5000;
        
        % get start and stop light time stamps
        startingPoints = [ts(1); ts(find(idx)+1);];
        stopPoints = [ts(idx); ts(end)];
        t = round(mean(diff([startingPoints stopPoints],[],2)));
        plot(startingPoints,ones(1,length(startingPoints))*8.5,'rx');hold on;
        plot(stopPoints,ones(1,length(stopPoints))*8.5,'ro');hold on;
        plot(stopPoints,ones(1,length(stopPoints))*7.4,'b+');hold on;
        plot(stopPoints+t,ones(1,length(stopPoints))*7.4,'bd');hold on;
        
        light_time_stamps{i} = [startingPoints stopPoints];
        light_time_stamps{i} = [light_time_stamps{i};stopPoints stopPoints+t];
        
    elseif i==3
        % 6x repetition of a moving bar paradigm
        title('Moving Bar');
        ts = stimulus{i}.time(stimulus{i}.bits == 0);
        ts2 = stimulus{i}.time(stimulus{i}.bits == 1);
        %subplot(1,length(stimulus),i)
        plot(ts,ones(1,length(ts))*0,'.b');hold on;
        plot(ts2,ones(1,length(ts2))*1,'.r');hold on;
        
        idx = diff(ts)>200000; % !! THIS SHOULD BE ADJUSTED ACCORDING TO VELOCITY !!
        %idx2 = diff(ts2)>20000; % !! THIS SHOULD BE ADJUSTED ACCORDING TO VELOCITY !!
        
        % get start and stop light time stamps
        startingPoints = sort([ts(1); ts(find(idx)+1);]);
        % startingPoints = reshape(startingPoints,9,6)'; % !! THIS SHOULD BE ADJUSTED ACCORDING IF REPETITIONS OR NUMBER OF DIRECTIONS IS CHANGED !!
        start = startingPoints(1:end-1);%reshape(startingPoints(:,1:end-1)',numel(startingPoints(:,1:end-1)),1);
        stop = startingPoints(2:end);%reshape(startingPoints(:,2:end)',numel(startingPoints(:,2:end)),1);
        plot(start,ones(1,length(start))*0.5,'rx');hold on;
        plot(stop,ones(1,length(stop))*0.4,'bo');hold on;
        
        
        light_time_stamps{i} = [start stop];
        
    elseif  i==4
        % 6x repetition of the moving grating
        title('Moving Gratings');
        ts = stimulus{i}.time(stimulus{i}.bits == 9);
        %subplot(1,length(stimulus),i)
        plot(ts,ones(1,length(ts))*9,'.r');hold on;
        
        idx = diff(ts)>5000; % !! THIS SHOULD BE ADJUSTED ACCORDING TO VELOCITY !!
        
        % get start and stop light time stamps
        s = [ts(find(idx)+1); ts(end)];
        startingPoints = s(1:end-1);
        stopPoints = s(2:end);
        %startingPoints(1:9:length(startingPoints)) = []; % THIS SHOULD BE ADJUSTED ACCORDING TO VELOCITY !!
        %stopPoints(1:9:length(startingPoints)) = []; % THIS SHOULD BE ADJUSTED ACCORDING TO VELOCITY !!
        plot(startingPoints,ones(1,length(startingPoints))*8.5,'rx');hold on;
        plot(stopPoints,ones(1,length(stopPoints))*8.4,'bo');hold on;
        
        
        light_time_stamps{i} = [startingPoints stopPoints];
        
        
    elseif  i==5
        % white noise
        title('White Noise');
        ts = stimulus{i}.time(stimulus{i}.bits == 8);
        %subplot(1,length(stimulus),i)
        plot(ts,ones(1,length(ts))*9,'.r');hold on;
        legend(['white noise frequency = ', num2str(1000/(mean(diff(ts))/20)), 'Hz'])
        
        idx1 = diff(ts)>5000;
        ts1 = ts(idx1);
        ts2 = ts1(1);
        ts = ts(ts>ts2+1000);
         ts3 = ts1(2);
         ts(ts>ts3) = [];
        
        idx = diff(ts)<400; % !! THIS SHOULD BE ADJUSTED ACCORDING TO VELOCITY !!
        
        % get start and stop light time stamps
        startingPoints = [ts(1); ts(find(idx)+1);];
        plot(startingPoints,ones(1,length(startingPoints))*8.5,'bx');hold on;
        
        
        light_time_stamps{i} = [startingPoints];
        
        
    end
end

clearvars -except R stimulus light_time_stamps stimulus_type

%% EXTRACT RGC time stamps

n_spikes = 500; % minimum number of spikes across all stimuli

RGCs = [];

% put each sorted RGC in a separate cell
temp_TS = [];
for j = 1:length(R)
    temp_TS = [temp_TS; R{j} ones(length(R{j}),1)*j];
end

for k = unique(temp_TS(:,2))'
    if length(temp_TS(temp_TS(:,2)==k,3))>n_spikes
        RGCs{end+1} = [temp_TS(temp_TS(:,2)==k,1) temp_TS(temp_TS(:,2)==k,3)];
    end
end

clearvars -except light_time_stamps RGCs stimulus_type


%% ASSIGN RGC time stamps to a given light stimulation

FullField = cell(1,length(RGCs));
MarchingSquare = cell(1,length(RGCs));
Bar = cell(1,length(RGCs));
Gratings = cell(1,length(RGCs));
WhiteNoise = cell(1,length(RGCs));


for i = 1:length(stimulus_type)
    
    ls = light_time_stamps{i};
    
    if size(ls,1)<1000
        for j = 1:length(RGCs)
            
            ts1 = RGCs{j};
            ts2 = ts1(ts1(:,2)==i,1)';
            
            norm_TEMP_ts = cell(length(ls),1);
            for k = 1:(length(ls))
                
                norm_TEMP_ts{k,1} = double((ts2(ts2>ls(k,1) & ts2<ls(k,2)) - ls(k,1)))/20000;
                
            end
            
            if i==1
                FullField{j} = norm_TEMP_ts;
            elseif i==2
                MarchingSquare{j} = norm_TEMP_ts;
            elseif i==3
                Bar{j} = norm_TEMP_ts;
            elseif i==4
                Gratings{j} = norm_TEMP_ts;
            end
            
            
        end
        
    else
        
        for j = 1:length(RGCs)
            ts1 = RGCs{j};
            ts2 = ts1(ts1(:,2)==i,1)';
            WhiteNoise{j} = double(ts2);
        end
    end
    
    
end

clearvars -except light_time_stamps stimulus_type FullField MarchingSquare Bar Gratings WhiteNoise


%% plot example RGC
close all
for ii = [230 410]
    
    % plot full field
    ts = FullField{ii};
    figure('color','w','position',[100 100 1300 700],'Name',num2str(ii));
    c1 = 0; c2 = 0;
    for i = 1:length(ts)
        
        if stimulus_type{1}(i)==1
            subplot(2,6,1);hold on
            title('ON FullField')
            c = [0 1 0]; c1 = c1+1;
            cc = c1;
        else
            subplot(2,6,2);hold on
            title('OFF FullField')
            c = [1 0 0]; c2 = c2+1;
            cc = c2;
        end
        plot(ts{i},ones(1,length(ts{i}))*cc,'.','color',c)
        xlabel('time [s]');ylabel('trial')
        box off
        
    end
    
    % plot march square
    ts = MarchingSquare{ii};
    ON_average = [];
    OFF_average = [];
    c1 = 0; c2 = 0;
    for i = unique(stimulus_type{2}(:,1))'
        
        for j = unique(stimulus_type{2}(:,2))'
            
            ts_temp = ts((stimulus_type{2}(:,1)==i & stimulus_type{2}(:,2)==j));
            
            for k = 1:length(ts_temp)
                
                if  i==1
                    subplot(2,6,3);hold on
                    title('ON MarchSqaure')
                    c = [0 1 0]; c1 = c1+1;
                    cc = c1;
                else
                    subplot(2,6,5);hold on
                    title('OFF MarchSqaure')
                    c = [1 0 0]; c2 = c2+1;
                    cc = c2;
                end
                plot(ts_temp{k},ones(1,length(ts_temp{k}))*cc,'.','color',c)
                xlabel('time [s]');ylabel('trial')
                box off
                ylim([0 150])
                
            end
            
            if i==1
                ON_average(j) = mean(cellfun('length',ts_temp));
            else
                OFF_average(j) = mean(cellfun('length',ts_temp));
            end
            
        end
    end
    subplot(2,6,4);
    imagesc(reshape(ON_average,5,5)')
    colorbar
    axis equal; axis ij; xlim([0 6]); ylim([0 6])
    caxis([0 ceil(max(max([ON_average;OFF_average])))])
    title('ON Receptive Field')
    subplot(2,6,6);
    imagesc(reshape(OFF_average,5,5)')
    colorbar
    axis equal;axis ij; xlim([0 6]); ylim([0 6])
    caxis([0 ceil(max(max([ON_average;OFF_average])))])
    title('OFF Receptive Field')
    
    % plot march square
    ts = Bar{ii};
    cc = 0;
    for i = unique(stimulus_type{3})
        
        ts_temp = ts(stimulus_type{3}==i);
        
        for k = 1:length(ts_temp)
            
            subplot(2,6,[7 8]);hold on
            title('Moving Bar')
            cc = cc+1;
            
            plot(ts_temp{k},ones(1,length(ts_temp{k}))*cc,'.','color','k')
            xlabel('time [s]');ylabel('direction (degrees)')
            box off
            ylim([0 50])
            
        end
        
    end
    set(gca,'ytick',[1:6:48]+2,'yticklabel',[0:45:315])
    for i = 1:6:48
        line([0 20],[i i]);
    end
    
    
    % plot march square
    ts = Gratings{ii};
    cc = 0;
    for i = unique(stimulus_type{3})
        
        ts_temp = ts(stimulus_type{3}==i);
        
        for k = 1:length(ts_temp)
            
            subplot(2,6,[9 10]);hold on
            title('Grating')
            cc = cc+1;
            
            plot(ts_temp{k},ones(1,length(ts_temp{k}))*cc,'.','color','k')
            xlabel('time [s]');ylabel('direction (degrees)')
            box off
            ylim([0 50])
            
        end
        
    end
    set(gca,'ytick',[1:6:48]+2,'yticklabel',[0:45:315])
    for i = 1:6:48
        line([0 7],[i i]);
    end
    
end

clearvars -except light_time_stamps stimulus_type FullField MarchingSquare Bar Gratings WhiteNoise

%% plot white noise response
close all;
for rgcs_idx = [230 410]%[round(-1 + (length(WhiteNoise)+1)*rand(10,1))']% 300 9 353]
    
    spiketimes = WhiteNoise{rgcs_idx};
    saved_frames = logical(stimulus_type{5});
    ligth_ts = light_time_stamps{5};
    
    % remove rgc time stamps before white noise starts
    spiketimes(spiketimes<ligth_ts(12)) = [];
    spiketimes(spiketimes>ligth_ts(end-100)) = [];
    
    spiketimes = spiketimes - ligth_ts(1);
    ligth_ts = ligth_ts - ligth_ts(1);
    
    
    
    if 0
        white_noise_ts = [];
        for i = 2:length(ligth_ts)
            if i == 2
                n = (ligth_ts(i) - ligth_ts(i-1)) - 1;
            else
                n = (ligth_ts(i) - ligth_ts(i-1));
            end
            white_noise_ts = [white_noise_ts single(ones(1,n)*(i-1))];
        end
    end
    
    if 0
        figure;plot(spiketimes,ones(1,length(spiketimes)),'xr')
        hold on;plot(ligth_ts,ones(1,length(ligth_ts))*0.5,'ob');ylim([-1 3])
        hold on;plot(1:length(white_noise_ts),ones(1,length(white_noise_ts))*0.2,'ob');ylim([-1 3])
        
    end
    
    if ~exist('white_noise_ts')
        load('~/Desktop/mxwbio/data/retina/20180918_P103/white_noise_frames.mat');
    end
    
    indices_images = [];
    indices_images{1} = white_noise_ts(round(sort(spiketimes)));
    
    cluster_to_plot = 1;
    neuron_image_frames = [double(indices_images{cluster_to_plot})];
    ts_RGC = neuron_image_frames; % here i select 5000 frames, try with more or less
    
    
    SpikeHistory = [];
    n_frames_befor_spikes = 20; % how many frames to get before spike
    for i = 1:length(ts_RGC)
        idx = ts_RGC(i);
        if idx > n_frames_befor_spikes+1
            SpikeHistory(size(SpikeHistory,1)+1,:)=(idx-n_frames_befor_spikes):(idx);
        end
    end
    
    
    twoD_movie = [];
    for i = 1:size(SpikeHistory,2)
        
        twoD_image = mean(saved_frames(:,:,SpikeHistory(:,i)),3);
        twoD_movie(:,:,i) = twoD_image;
        
    end
    
    
    
    % plot STA
    
    figure('Position',[0 0 1500 1500],'Color','w','Name',num2str(rgcs_idx))
    fitst_frame = 1;
    for i = fitst_frame:size(twoD_movie,3)
        expanded_frame = twoD_movie(:,:,i);
        
        subplot(6,5,i);
        imagesc(expanded_frame)
        %caxis([0.4 0.8])
        xlabel('pixel - space'); ylabel('pixel - space');
        title(['t = -',num2str(round((size(twoD_movie,3)-i)*16)),' ms'])
        colorbar
        box off
        axis equal
    end
    
    
    
    
end

clearvars -except light_time_stamps stimulus_type FullField MarchingSquare Bar Gratings WhiteNoise
