tic
tmp_ans = [];
for i=0:2:10
    tmp = [i i*2 i*3];
    tmp_ans = cat(1,tmp_ans,tmp);
end
toc

tmp_b = 3;
tmp_str_1 = 'C:\Users\tlab\Documents\勉強\竹内研\データ\maxone\20230719\';  % datapath has to be adapted
tmp_str_2 = 'data.raw.h5'; 
tmp_mydata = [tmp_str_1 tmp_str_2];

tmp1 = 23.0 / 7

tmp_list = ["gt" 4 7];

disp(1:2:9);

close all; %clear; clc;