%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% clear all %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%close all; clear; clc;
close all
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% path & filename %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic
datapath = "C:\Users\tlab\OneDrive - The University of Tokyo\tlab\study\data\maxone\";  % datapath has to be adapted
filepath = "20230928\000025";
%filepath = "20230719";
%filepath = "lian1202\435\";
filename = "\data.raw.h5";                                   % the filename is default (unless intentionally changed)

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% assign %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

mydata = datapath + filepath + filename;

%% %%%%%%%%%%%%%%%%%%%%%%%% extract unfiltered traces and downsample traces %%%%%%%%%%%%%%%%%%%%%%%%%%%% %fixed

wellID   = 1;
myfile   = mxw.fileManager(mydata,wellID);
sampRate = myfile.fileObj.samplingFreq;
dataSize = myfile.fileObj.dataLenSamples;
fps = 10;
downSize = sampRate/fps;
filter = false; %true(1)にするとbandpass filterがかかる、上手く動いてないと思う、暫くはフィルターオフで固定
highcut = 2000; %ハイカットオフ周波数
lowcut = 1e-8;
figdata = [filter lowcut highcut]; %グラフ保存用

mapxy = [myfile.fileObj.map.x myfile.fileObj.map.y];



if ~((exist("pre_fps","var")) && (highcut == pre_highcut) && (fps == pre_fps) && (mydata == pre_pass) && (filter==pre_filter))
    disp("読み込みもやってるよ")
    traces1 = [];
    
    
    for time = downSize:downSize:dataSize
        tmp_trace = double(myfile.extractRawData(time,1));
        %tmp_trace = double(myfile.extractBPFData(time,1)); %バンドパスフィルタあり
        traces1 = cat(1,traces1,tmp_trace);
    end
    if filter
        myfile.modifyBPFilter(lowcut,highcut,4);
        traces1 = myfile.bandPassFilter.filter(traces1);
    end
    

    %全部やるとき
    %traces1 = double(myfile.extractRawData(1,dataSize,"electrodes",specify_electrode_number(1800,2000,800,1000,myfile.processedMap.xpos,myfile.processedMap.ypos,myfile.processedMap.electrode)));

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% offset %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    myoffset = mean(traces1(1:200,:)); % first 100 samples (10 seconds) are used to re-align traces
    traces2 = traces1-myoffset;
    
    
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% convert microvolts to milivolts %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %traces3 = traces2/1000;
    %mean_trace = mean(traces2,2);
else
    disp("読み込みはやってないよ")
end


%フィルタをちゃんと活かせる方式の読み込み->遅すぎて要改善
%{
traces1 = [];
for elect_number = transpose(myfile.processedMap.electrode)
    disp(elect_number);
    tmp_trace = double(myfile.extractRawData(1,dataSize,"electrodes",elect_number));
    tmp_trace = downsample(tmp_trace,downSize);
    traces1 = [traces1 tmp_trace];
end
myoffset = mean(traces1(1:200,:)); % first 100 samples (10 seconds) are used to re-align traces
traces2 = traces1-myoffset;
%}

pre_fps = fps;
pre_pass = mydata;
pre_filter = filter;
pre_highcut = highcut;




%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 範囲を選ぶ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%この辺でちゃんとxy座標とかから欲しいindexを見つけ出す

%index = [1 15 78]; %この番号のarrayを使う



%刺激を入れた時間
stimulation_time = 0*fps;
if stimulation_time == 0 %0だとindexエラーおこっちゃう
    stimulation_time = 1;
end

% raw map
map.x = myfile.fileObj.map.x;
map.y = myfile.fileObj.map.y;

%{
for i_index = 1:5
    for j_index = 1:3
        index = specify_roi(34+(i_index-1)*875,823+(i_index-1)*875,69+(j_index-1)*875,858+(j_index-1)*875,mapxy);
        draw_voltage(filepath,figdata,index,stimulation_time,traces1,traces2,map.x,map.y,false);
    end
end
%}

%writematrix(traces2(:,specify_roi(1800,2000,800,1000,mapxy)),"C:\Users\tlab\OneDrive - The University of Tokyo\tlab\study\data\maxone\230829_16.csv");
%writematrix(traces2,"C:\Users\tlab\OneDrive - The University of Tokyo\tlab\study\data\maxone\230829_16.csv");

%index = specify_roi(0,6000,0,6000,mapxy); %要は全部
%TODO 少しだけ出すやつ
%TODO 自分でindex指定したときの保存の名前
%TODO splitの時、フォルダ名に分割数入れる
%TODO 簡単に、適当な場所の4個とかもってくるやつ
%TODO 自動保存OFF機能
%index = specify_roi(0,2000,0,1000,mapxy); %xy両方半分
%draw_voltage(filepath,figdata,stimulation_time,traces1,traces2,map.x,map.y,false,"split",[5,3]); %5,3

%%%%%% 反応があるところのmap作成 %%%%%%%
traces_width = max(traces2) - min(traces2);
active_electrode = find(traces_width > 500);
draw_voltage(filepath,figdata,stimulation_time,traces1,traces2,map.x,map.y,false,"all",[5,3],active_electrode);

toc
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% plot traces %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
% figure
% close all; 
figure('name',"voltage plot",'NumberTitle','off', 'color', 'w'); %append(string(i_index),",",string(j_index))
set(gcf,'Position',[40 400 1600 400]);

% panels
ax1 = subplot(1,3,1); ax1.Box = 'on'; grid(ax1, 'on');
ax2 = subplot(1,3,2); ax2.Box = 'on'; grid(ax2, 'on');
%ax3 = subplot(1,3,3); ax3.Box = 'on'; grid(ax3, 'on'); %グラフ3いらんくね？

% downsampled traces
hold on; plot(ax1, mean_trace(:,index), 'linewidth', .1);
ax1.Title.String = 'downsampled traces';
ax1.XLim = [1 size(traces1,1)];
ax1.YLim = [min(min(mean_trace)) max(max(mean_trace))];
ax1.XLabel.String = 'Time [ s ]';
ax1.XTickLabel = ax1.XTick/10;
grid(ax1, 'on');

% traces after the offecet (microvolts)
hold on; plot(ax2, traces2(stimulation_time:end,index), 'linewidth', .1);
ax2.Title.String = 'offset compensation';
ax2.XLim = [1 size(traces2,1)];
ax2.YLim = [min(min(traces2(stimulation_time:end,index))) max(max(traces2(stimulation_time:end,index)))];
ax2.XLabel.String = 'Time [ s ]';
ax2.XTickLabel = ax2.XTick/10;
ax2.YLabel.String = 'Voltage [ µV ]';
grid(ax2, 'on');

%{
% traces after th eoffecet (microvolts)
hold on; plot(ax3, traces3(stimulation_time:end,index), 'linewidth', .1);
ax3.Title.String = 'voltage traces';
ax3.XLim = [1 size(traces3,1)];
ax3.YLim = [min(min(traces3(stimulation_time:end,index))) max(max(traces3(stimulation_time:end,index)))];
ax3.XLabel.String = 'Time [ s ]';
ax3.XTickLabel = ax3.XTick/10;
ax3.YLabel.String = 'Voltage [ mV ]';
grid(ax3, 'on');
%}

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% activity map %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%close all; 
% get peak-to-peak amplitude
negativePeaks = min(traces3);
positivePeaks = max(traces3);
amplitudes    = abs(negativePeaks)+positivePeaks;

% raw map
map.x = myfile.fileObj.map.x;
map.y = myfile.fileObj.map.y;
map.amp = amplitudes;

% grid map
xlin = linspace( min( map.x ), max( map.x ), 220 );
ylin = linspace( min( map.y ), max( map.y ), 120 );
[X,Y] = meshgrid(xlin,ylin);
mymap.XData = xlin;
mymap.YData = ylin;
mymap.CData = griddata(map.x, map.y, map.amp, X, Y, 'natural');

% figure
%fig = figure('name','Activity map','NumberTitle','off', 'color', [1 1 1]*1);
%set(gcf,'Position',[500 400 630 1155]);

% panel
ax4 = subplot(1,3,3);
ax4.Box = 'on';
%ax4.Position = [.14 .06 .7250 .9125];
ax4.YLim = [-20 2102.5];
ax4.XLim = [-20 3852.5];
ax4.YTick = [];
ax4.XTick = [];
ax4.Box = 'on';
camroll(ax4,90)

% Activity map
mcmap = hot;
mcmap = flipud(mcmap);
hold(ax4,'on'); plot(ax4, map.x, map.y, 'sk', 'color', 'k', 'markersize', 5);
hold(ax4,'on'); plot(ax4, map.x(index), map.y(index), 'sk', 'color', 'r', 'markersize', 8);
colormap(ax4, mcmap);

    %end
%end
%}
function index_list = specify_roi(xmin,xmax,ymin,ymax,mapxy) %指定した範囲に含まれる要素のindexを返す関数(チャンネル番号)
index_list = [];
for i = 1:length(mapxy)
    x = mapxy(i,1);
    y = mapxy(i,2);
    if (xmin<=x) && (x<xmax) && (ymin<=y) && (y<ymax)
        index_list = [index_list i];
    end
end
end

function electrode_number_list = specify_electrode_number(x_min,x_max,y_min,y_max,mapx,mapy,electrode) %指定した範囲に含まれる要素の電極番号？を返す関数
electrode_number_index = [];
for i = 1:length(mapx)
    x = mapx(i);
    y = mapy(i);
    if (x_min<=x) && (x<x_max) && (y_min<=y) && (y<y_max)
    electrode_number_index = [electrode_number_index i]; %これはまだmyfile.processedMap.electrodeのindex,myfile.processedMap.xposで絞り込んだだけ
    end
end
electrode_number_list = transpose(electrode(electrode_number_index));
%disp(electrode_number_index);
%disp(electrode_number_list);
end

function draw_voltage(filepath,figdata,stimulation_time,traces1,traces2,mapx,mapy,isMean,mode,split_nums,index) %figdata = [filter lowcut highcut] split = [xsplit ysplit]
xsteps = 1;
ysteps = 1;

if (nargin < 11) %指定しなければindexは全範囲
    index = specify_roi(0,max(mapx)+1,0,max(mapy)+1,[mapx mapy]); %specify_roiの実装が<=だったり<だったりするので余裕をもたせる
end

switch mode
    case "all" %なんかすることあるかな、xsteps,ystepsはそれぞれ1で固定
        disp("all");
        xmin = min(mapx(index));
        xmax = max(mapx(index));
        ymin = min(mapy(index));
        ymax = max(mapy(index));
        xlength = (xmax - xmin)/xsteps;
        ylength = (ymax - ymin)/ysteps;
    case "split" %split_numsは[5 3]のようにx,y方向それぞれの分割数を記述することを想定
        disp("split");
        xsteps = split_nums(1);
        ysteps = split_nums(2);
        xmin = min(mapx(index));
        xmax = max(mapx(index));
        ymin = min(mapy(index));
        ymax = max(mapy(index));
        xlength = (xmax - xmin)/xsteps;
        ylength = (ymax - ymin)/ysteps;
end

figure_handle = zeros(xsteps,ysteps);
%TODO 抜けがある、square形状でないindexに対応していない、最大最小しか見れてない、別のmodeを作んないとかもね


for x_count = 1:xsteps
    for y_count = 1:ysteps

        %TODO indexの分割、squre状に。あとでindexとのand加えるか
        xrange = [xmin + xlength*(x_count-1), xmin + xlength*x_count];
        yrange = [ymin + ylength*(y_count-1), ymin + ylength*y_count];
        %{
        if (x_count == xsteps) || (y_count == ysteps)
            index = specify_roi(xmin + xlength*(x_count-1), xmax + 1, ymin + ylength*(y_count-1), ymax + 1, [mapx mapy]);
        else
            index = specify_roi(xmin + xlength*(x_count-1), xmin + xlength*x_count, ymin + ylength*(y_count-1), ymin + ylength*y_count, [mapx mapy]);
        end
        %}
        if x_count == xsteps %端点処理
            xrange(2) = xmax + 1;
        end

        if y_count == ysteps %端点処理
            yrange(2) = ymax + 1;
        end

        sub_index = intersect(specify_roi(xrange(1), xrange(2), yrange(1), yrange(2), [mapx mapy]),index); %元の指定indexとsqure範囲の積集合を取る

        if isempty(sub_index) %空の範囲は描画しない
            disp("oh my god")
            continue
        end
        %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% plot traces %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        figure('name',"voltage plot",'NumberTitle','off', 'color', 'w'); %append(string(i_index),",",string(j_index))
        set(gcf,'Position',[40 400 1600 400]);
        
        % panels
        ax1 = subplot(1,3,1); ax1.Box = 'on'; grid(ax1, 'on');
        ax2 = subplot(1,3,2); ax2.Box = 'on'; grid(ax2, 'on');
        %ax3 = subplot(1,3,3); ax3.Box = 'on'; grid(ax3, 'on'); %グラフ3いらんくね？
        
        % downsampled traces
        
        %%描画範囲の処理
        if isMean %平均の計算の場合
            draw_traces1 = mean(traces1(:,sub_index),2);
            draw_traces2 = mean(traces2(stimulation_time:end,sub_index),2);
        else %普通のとき
            draw_traces1 = traces1(:,sub_index);
            draw_traces2 = traces2(stimulation_time:end,sub_index);
        end
        
        hold on; plot(ax1, draw_traces1, 'linewidth', .1);
        ax1.Title.String = 'downsampled traces';
        ax1.XLim = [1 size(draw_traces1,1)];
        if (min(min(draw_traces1)) == max(max(draw_traces1)))
            ax1.YLim = [0 max(max(draw_traces1))];
        else
            ax1.YLim = [min(min(draw_traces1)) max(max(draw_traces1))];
        end
        ax1.XLabel.String = 'Time [ s ]';
        ax1.XTickLabel = ax1.XTick/10;
        grid(ax1, 'on');
        
        % traces after the offecet (microvolts)
        hold on; plot(ax2, draw_traces2, 'linewidth', .1);
        ax2.Title.String = 'offset compensation';
        ax2.XLim = [1 size(draw_traces2,1)];
        if (min(min(draw_traces2)) == max(max(draw_traces2)))
            ax2.YLim = [0 max(max(draw_traces2))];
        else
            ax2.YLim = [min(min(draw_traces2)) max(max(draw_traces2))];
        end
        %ax2.YLim = [-1000 1000];
        ax2.XLabel.String = 'Time [ s ]';
        ax2.XTickLabel = ax2.XTick/10;
        ax2.YLabel.String = 'Voltage [ µV ]';
        grid(ax2, 'on');
        
        %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% activity map %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % figure
        %fig = figure('name','Activity map','NumberTitle','off', 'color', [1 1 1]*1);
        %set(gcf,'Position',[500 400 630 1155]);
        
        % panel
        ax4 = subplot(1,3,3);
        ax4.Box = 'on';
        %ax4.Position = [.14 .06 .7250 .9125];
        ax4.YLim = [-20 2102.5];
        ax4.XLim = [-20 3852.5];
        ax4.YTick = [];
        ax4.XTick = [];
        ax4.Box = 'on';
        camroll(ax4,90)
        
        % Activity map
        mcmap = hot;
        mcmap = flipud(mcmap);
        hold(ax4,'on'); plot(ax4, mapx, mapy, 'sk', 'color', 'k', 'markersize', 5);
        hold(ax4,'on'); plot(ax4, mapx(sub_index), mapy(sub_index), 'sk', 'color', 'r', 'markersize', 8);
        colormap(ax4, mcmap);

        figure_handle(x_count,y_count) = gcf;


    end
end

%%%%%%%%% savefig %%%%%%%%%
figfolderpath = "C:\Users\tlab\OneDrive - The University of Tokyo\tlab\study\data\graph\";
figpath =  figfolderpath + filepath;

if not(exist(figpath,'dir'))
    mkdir(figpath);
end

for x_count = 1:xsteps
    for y_count = 1:ysteps

        figname = ""; %fignameにはフィルタや開始位置、allやsplitなどの情報をおく
        if figdata(1) %filterがONなら
            lowcut = figdata(2);
            highcut = figdata(3);
            figname = figname + "filter" + string(lowcut) + "_" + string(highcut);
        else %filterがOFFなら
            figname = figname + "nonfilter";
        end
        
        %xlim = [min(mapx(index)) max(mapx(index))];
        %ylim = [min(mapy(index)) max(mapy(index))];
        
        switch mode
            case "all"
                figname = figname + "_all";
            case "split"
                figname = figname + "_square_split_x" + string(xsteps) + "y" + string(ysteps);
                xyplace = "x" + string(x_count) + "y" + string(y_count); %splitの場合はフォルダを別に作ってその中にグラフを入れる
        end
        %figname = figname + "_square" + "_x" + string(fix(xlim(1))) + "_" + string(ceil(xlim(2))) + "_y" + string(fix(ylim(1))) + "_" + string(ceil(ylim(2)));
        figname = figname + "_start" + string(stimulation_time);
        if isMean
            figname = figname + "_mean";
        end
        
        disp("データ保存中")
        switch mode
            case "split"
                if not(exist(figpath + "\" + figname,'dir'))
                    mkdir(figpath + "\" + figname)
                end
                xyplace = xyplace + ".fig";
                saveas(figure_handle(x_count,y_count), figpath + "\" + figname + "\" +xyplace);
            case "all"
                figname = figname + ".fig";
                saveas(figure_handle(x_count,y_count), figpath + "\" + figname);
        end
        
    end
end
end