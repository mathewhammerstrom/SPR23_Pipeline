%% IMPORTANT: 
% This is analysis code I wrote adapted from tools that don't belong to
% me. The purpose of these analyses was for exploratory research on
% analysis methods. They are not direct replicates of the pipelines I am
% citing here. This code is NOT intended for publishing or widespread use
% yet. I am sorry it is not well-commented :-(, will try to fix ASAP.

%% Analysis Script to Test the Makoto Pipeline
% Requires eeglab.
clear all;
close all;
clc;

load("masterFileEEG.mat")

files = dir('Cognitive*');
markers = {'S110','S111','S202','S203'};

tic
for counter =  1:length(masterFileEEG)
    names = strsplit(masterFileEEG(counter).name,{'_','.'});
    number = names{3};

    
    filename = (['Cognitive_Assessment_0' number '.mat']);
    load(filename)
    nameBase = strsplit(EEG.filename,'.');
    originalEEG = EEG;

    [EEG] = doResample(EEG,250);
    [EEG] = doFilter(EEG,1,30,2,60,EEG.srate);

    [EEG] = pop_cleanline(EEG);

    [EEG] = pop_clean_rawdata(EEG,'Bandwidth',2,'ChanCompIndices',[1:EEG.nbchan] ,'SignalType','Channels','ComputeSpectralPower',true,'LineFrequencies',[60 120] ,'NormalizeSpectrum',false,'LineAlpha',0.01,'PaddingFactor',2,'PlotFigures',false,'ScanForLines',true,'SmoothingFactor',100,'VerbosityLevel',1,'SlidingWinLength',EEG.pnts/EEG.srate,'SlidingWinStep',EEG.pnts/EEG.srate);
    [EEG] = doInterpolate(EEG,originalEEG.chanlocs,'spherical');
    [EEG] = doRereference(EEG,{'TP9','TP10'},{'ALL'},originalEEG.chanlocs);

    [EEG] = doICA(EEG,1);
    [EEG] = doRemoveOcularICAComponents(EEG);

    [EEG] = doSegmentData(EEG,markers,[-200, 600]);
    [EEG] = doBaseline(EEG,[-200,0]);


    if isempty(EEG.segmentMarkers)
        ERP = [];
        FFT = [];
        markerless(counter)=1;
    else
        [ERP] = doERP(EEG,markers,0);

%         [FFT] = doFFT(EEG,markers);
    end
    EEGFolder = 'C:\Users\Krigolson Admin\Desktop\CA_Testing\Data\Export\EEG';
    EEGName = ([nameBase{1} '_EEGm2']);
    ERPFolder = 'C:\Users\Krigolson Admin\Desktop\CA_Testing\Data\Export\ERP';
    ERPName = ([nameBase{1} '_ERPm2']);
%     FFTFolder = 'C:\Users\Krigolson Admin\Desktop\CA_Testing\Data\Export\FFT';
%     FFTName = ([nameBase{1} '_FFTm2']);


    save(fullfile(EEGFolder,EEGName),'EEG');
%     save(fullfile(FFTFolder,FFTName),'FFT');
    save(fullfile(ERPFolder,ERPName),'ERP');

end
toc
