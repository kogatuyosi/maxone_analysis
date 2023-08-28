%% plot light time stamps

pathFolderData = '/home/michelef/Trace_20181023_14_14_39.raw.h5';
datainfo = mxw.fileManager(pathFolderData)
bits = h5read(pathFolderData, '/bits');
stimulus.bits = bits.bits;
stimulus.time = double(bits.frameno) - double(datainfo.fileObj.firstFrameNum);
figure('color', 'w');
plot(stimulus.time,stimulus.bits,'.')

%% plot raster plot together with light stimulus

mxw.plot.rasterPlot(datainfo, 'MarkerSize', 2, 'Xlabel', 'Time [s]', 'Ylabel', 'Channels', 'Title', 'Raster Plot');
hold on;
on_time = (stimulus.time(stimulus.bits==1)/20000); on_marks = ones(1,length(stimulus.time(stimulus.bits==1)))*1050;
off_time = (stimulus.time(stimulus.bits==0)/20000); off_marks = ones(1,length(stimulus.time(stimulus.bits==0)))*1100;

plot(on_time,on_marks,'gx');
plot(off_time,off_marks,'rx');
legend('raster','on','off')
hold off

