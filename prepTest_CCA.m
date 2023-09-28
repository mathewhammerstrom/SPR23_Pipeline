%% IMPORTANT: 
% This is analysis code I wrote adapted from tools that don't belong to
% me. The purpose of these analyses was for exploratory research on
% analysis methods. They are not direct replicates of the pipelines I am
% citing here. This code is NOT intended for publishing or widespread use
% yet. I am sorry it is not well-commented :-(, will try to fix ASAP.

%% Analysis Script to Test the PREP Pipeline
% Requires eeglab, the PREP github repo (EEG-CleanTools I believe), and the
% parallel processing toolbox. 

clear all;
close all;
clc;

markers = {'S110','S111','S202','S203'};
load("masterFileEEG.mat");

tic 
for counter =  1:length(masterFileEEG)
    names = strsplit(masterFileEEG(counter).name,{'_','.'});
    number = names{end};

    
    filename = (['Cognitive_Assessment_0' number '.mat']);
    load(filename)
    nameBase = strsplit(EEG.filename,'.');

    [EEG] = doFilter(EEG,0.1,30,2,60,EEG.srate);
    [EEG] = doICA(EEG,1);
    [EEG] = doRemoveOcularICAComponents(EEG);
    [EEG,data,output] = doPrepPipeline(EEG);
    [EEG] = doRereference(EEG,{'TP9','TP10'},{'ALL'},EEG.chanlocs);

    [EEG] = doSegmentData(EEG,markers,[-200, 600]);
    [EEG] = doBaseline(EEG,[-200,0]);

    [EEG] = doArtifactRejection(EEG,'Difference',150);
    [EEG] = doArtifactRejection(EEG,'Gradient',10);
    removalMatrix = EEG.artifact(1).badSegments + EEG.artifact(2).badSegments;

    [EEG] = doRemoveEpochs(EEG,removalMatrix,0);


    if isempty(EEG.segmentMarkers)
        ERP = [];
        FFT = [];
        markerless(counter)=1;
    else
    [ERP] = doERP(EEG,markers,0);

%     [FFT] = doFFT(EEG,markers);
    end
    EEGFolder = 'C:\Users\Krigolson Admin\Desktop\CA_Testing\Data\Export\EEG';
    EEGName = ([nameBase{1} '_EEGp2']);
    ERPFolder = 'C:\Users\Krigolson Admin\Desktop\CA_Testing\Data\Export\ERP';
    ERPName = ([nameBase{1} '_ERPp2']);
%     FFTFolder = 'C:\Users\Krigolson Admin\Desktop\CA_Testing\Data\Export\FFT';
%     FFTName = ([nameBase{1} '_FFTp2']);

    prepName =([nameBase{1} 'PREPp']);

    save(fullfile(EEGFolder,EEGName),'EEG');
    save(fullfile(EEGFolder,prepName),"output");
%     save(fullfile(FFTFolder,FFTName),'FFT');
    save(fullfile(ERPFolder,ERPName),'ERP');

end
toc

