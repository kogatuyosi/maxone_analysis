%% function that generates random spike trains
%fr: frequency of spiking neuron, tSim:length of recording, nTrials: number of simulations 

function [spikeMat, tVec] = poissonSpikeGen(fr, tSim, nTrials)
dt = 1/1000; % s
nBins = floor(tSim/dt);
spikeMat = rand(nTrials, nBins) < fr*dt;
tVec = 0:dt:tSim-dt;