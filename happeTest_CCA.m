%% IMPORTANT: 
% This is analysis code I wrote adapted from tools that don't belong to
% me. The purpose of these analyses was for exploratory research on
% analysis methods. They are not direct replicates of the pipelines I am
% citing here. This code is NOT intended for publishing or widespread use
% yet. I am sorry it is not well-commented :-(, will try to fix ASAP.

%% Analysis Script to Test the HAPPE Pipeline
% Requires eeglab and the HAPPE github repo.

clear all;
close all;
clc;

%This is loading in files that are saved in EEGLAB structures as .mat
%files. 
files = dir('Cognitive*');
markers = {'S110','S111','S202','S203'};
load("masterFileEEG.mat");

tic
for counter =  1:length(masterFileEEG)
    names = strsplit(masterFileEEG(counter).name,{'_','.'});
    number = names{3};

    
    filename = (['Cognitive_Assessment_0' number '.mat']);
    load(filename)
        nameBase = strsplit(EEG.filename,'.');
        originalEEG = EEG;

        [EEG] = doFilter(EEG,1,30,2,60,EEG.srate); 

        lnParams.freq = [60, 120, 180, 240, 300];
        lineFreqs = [lnParams.freq, lnParams.freq*2];
        [EEG, ~] = cleanLineNoise(EEG, struct('lineNoiseMethod', 'clean', ...
            'lineNoiseChannels', 1:EEG.nbchan, 'Fs', EEG.srate, ...
            'lineFrequencies', lineFreqs, 'p', 0.01, 'fScanBandWidth', 2, ...
            'taperBandWidth', 2, 'taperWindowSize', 4, 'taperWindowStep', 4, ...
            'tau', 100, 'pad', 2, 'fPassBand', [0 EEG.srate/2], ...
            'maximumIterations', 10)) ;

        [EEG] = doResample(EEG,250);

%       EEG = pop_rejchan(EEG, 'elec', 1:EEG.nbchan, ...
%             'threshold', [-2.75 2.75], 'norm', 'on', 'measure', ...
%             'spec', 'freqrange', [1 100]) ;

        EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion', ...
            'off', 'ChannelCriterion', .7, 'LineNoiseCriterion', ...
            2.5, 'Highpass', 'off', 'BurstCriterion', 'off', ...
            'WindowCriterion', 'off', 'BurstRejection', ...
            'off', 'Distance', 'Euclidian') ;
  

        artifacts = wdenoise(reshape(EEG.data, size(EEG.data, 1), [])', 9, ...
            'Wavelet', 'coif4', 'DenoisingMethod', 'Bayes', 'ThresholdRule', ...
            'Soft', 'NoiseEstimate', 'LevelDependent')';
        EEG.preWavEEG = reshape(pop_eegfiltnew(EEG, EEG.filterHigh, ...
            EEG.filterLow, [], 0, [], 0).data, size(EEG.data, 1), ...
            []) ;
        EEG.data = reshape(EEG.data, size(EEG.data,1), []) - artifacts ;
        EEG.postWavEEG = reshape(pop_eegfiltnew(EEG,EEG.filterHigh, ...
            EEG.filterLow, [], 0, [], 0).data, size(EEG.data, 1), ...
            []) ;


        [EEG] = doICA(EEG,1);
        [EEG] = doRemoveOcularICAComponents(EEG);

        [EEG] = doInterpolate(EEG,originalEEG.chanlocs,'spherical');
        [EEG] = doRereference(EEG,{'TP9','TP10'},{'ALL'},originalEEG.chanlocs);

        [EEG] = doSegmentData(EEG,markers,[-200, 600]);
        [EEG] = doBaseline(EEG,[-200,0]);


        if isempty(EEG.segmentMarkers)
            ERP = [];
            FFT = [];
            markerless(counter)=1;
        else
            [ERP] = doERP(EEG,markers,0);

%             [FFT] = doFFT(EEG,markers);
        end
        EEGFolder = 'C:\Users\Krigolson Admin\Desktop\CA_Testing\Data\Export\EEG';
        EEGName = ([nameBase{1} '_EEGh2']);
        ERPFolder = 'C:\Users\Krigolson Admin\Desktop\CA_Testing\Data\Export\ERP';
        ERPName = ([nameBase{1} '_ERPh2']);
%         FFTFolder = 'C:\Users\Krigolson Admin\Desktop\CA_Testing\Data\Export\FFT';
%         FFTName = ([nameBase{1} '_FFTh2']);


        save(fullfile(EEGFolder,EEGName),'EEG');
%         save(fullfile(FFTFolder,FFTName),'FFT');
        save(fullfile(ERPFolder,ERPName),'ERP');
    disp(counter);
    pause(5)
end
toc
