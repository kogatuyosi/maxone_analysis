
%% run BeatAnalysis

load 'C:/Matlab_data/cardiacExample.mat'
deltaSamples = 100;
minNumSpikes = 50;

[beatValues, valueMatrix] = mxw.cardiacAnalysis.computeBeatValues(cardiacFile, deltaSamples, minNumSpikes);


%% Plot initialization points
f=100
figure('color','white');
scatter(valueMatrix(:,6)+(rand(size(valueMatrix(:,6)))-0.5)*f, valueMatrix(:,7)+(rand(size(valueMatrix(:,6)))-0.5)*f,[],valueMatrix(:,1),'filled')
% scatter(xCenter, yCenter,[],numSpikesCon,'filled')

% colorbar
axis ij
axis equal
xlim([-50 4000])
ylim([-50 2050])
box on
xlabel('X-coordinate')
ylabel('Y-coordinate')

%% 

