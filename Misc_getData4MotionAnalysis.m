function [data_raw, data_comp] = Misc_getData4MotionAnalysis( cfg )
% MISC_GETDATA4MOTIONANALYSIS is a function which returns the raw data and
% corresponding ica components of a selected participant. Before
% applying an ICA decomposition the raw signal is bandpass filtered
% ([1 48] Hz) and cleaned from transient artifacts, to receive an
% appropriate result for the comparision with the mortion signal. After the
% ICA decomposition the resulting unmixing matrix is applied to filtered
% but not cleaned data and stored in data_comp.
%
% Use as
%   [data_raw, data_comp] = Misc_getData4MotionAnalysis( cfg )
%
% The configuration options are
%   cfg.dataset     = pathname to dataset (e.g.: '/data/pt_01843/eegData/DualEEG_RPS_rawData/DualEEG_RPS_FP_01.vhdr')
%   cfg.participant = number of dyad, could be either 1 or 2
%
% This function requires the fieldtrip toolbox.
%
% See also FT_PREPROCESSING, FT_ARTIFACT_THRESHOLD, FT_REJECTARTIFACT,
% FT_COMPONENTANALYSIS

% Copyright (C) 2019, Daniel Matthes, MPI CBS

% -------------------------------------------------------------------------
% Get and check config options
% -------------------------------------------------------------------------
dataset     = ft_getopt(cfg, 'dataset', []);
participant = ft_getopt(cfg, 'participant', []);

if ~exist(dataset, 'file')
  error('The specified file (cfg.dataset) does not exist');
end

if ~ismember(participant, [1,2])
  error('The participant number (cfg.participant) could only be 1 or 2.');
end

% -------------------------------------------------------------------------
% Data import
% -------------------------------------------------------------------------
cfg                     = [];
cfg.dataset             = dataset;
cfg.channel             = 'all';
cfg.showcallinfo        = 'no';
cfg.feedback            = 'no';

fprintf('<strong>Import raw data...</strong>\n');
ft_info off;
data_raw = ft_preprocessing(cfg);                                           % import all data of selected dyad
ft_info on;

numOfChan = length(data_raw.label);

if participant == 1                                                         % select data of participant 1
  data_raw.label = strrep(data_raw.label(1:numOfChan/2), '_1', '');
  data_raw.trial{1} = data_raw.trial{1}(1:numOfChan/2,:);
elseif particpant == 2                                                      % select data of participant 2
  data_raw.label = strrep(data_raw.label(numOfChan/2+1:end), '_1', '');
  data_raw.trial{1} = data_raw.trial{1}(numOfChan/2+1:end,:);
end

if any(ismember(data_raw.label, {'Fp1', 'Fp2'}))                                % Adaption for RPS
  loc = ismember(data_raw.label, 'Fp1');
  data_raw.label(loc) = {'V1'};
  loc = ismember(data_raw.label, 'Fp2');
  data_raw.label(loc) = {'V2'};
  loc = ismember(data_raw.label, 'PO9');
  data_raw.label(loc) = {'H1'};
  loc = ismember(data_raw.label, 'PO10');
  data_raw.label(loc) = {'H2'};
end

% -------------------------------------------------------------------------
% Lowpass filtering
% -------------------------------------------------------------------------
cfg = [];
cfg.bpfilter          = 'yes';                                              % use bandpass filter
cfg.bpfreq            = [1 48];                                             % bandpass frequency
cfg.bpfilttype        = 'but';                                              % bandpass filter type
cfg.bpinstabilityfix  = 'split';                                            % deal with filter instability
cfg.channel           = 'all';                                              % use all channels
cfg.trials            = 'all';                                              % use all trials
cfg.feedback          = 'no';                                               % feedback should not be presented
cfg.showcallinfo      = 'no';                                               % prevent printing the time and memory after each function call

fprintf('<strong>Filter (lowpass) raw data...</strong>\n');
data_preproc = ft_preprocessing(cfg, data_raw);

% -------------------------------------------------------------------------
% Clean data from transient artifacts
% -------------------------------------------------------------------------
% Generate trl definition
trlLength   = data_preproc.fsample * 200 / 1000;
sampleinfo  = data_preproc.sampleinfo;
trialinfo   = 1;

numOfTrials = fix(2*((sampleinfo(2) - sampleinfo(1) +1) / trlLength) - 1);
trl         = zeros(numOfTrials, 4);

begsample = 1;
endsample = begsample + numOfTrials - 1;

trl(begsample:endsample, 1) = sampleinfo(1):trlLength/2: ...
                              (numOfTrials-1) * (trlLength/2) + ...
                              sampleinfo(1);
trl(begsample:endsample, 3) = 0:trlLength/2: ...
                              (numOfTrials-1) * (trlLength/2);
trl(begsample:endsample, 2) = trl(begsample:endsample, 1) ... 
                              + trlLength - 1;
trl(begsample:endsample, 4) = trialinfo;

% Detect transient artifacts (200µV delta within 200 ms. 
% The window is shifted with 100 ms, what means 50 % overlapping.)
cfg                               = [];
cfg.trl                           = trl;
cfg.continuous                    = 'no';
cfg.artfctdef.threshold.channel   = 'all';                                  % specify channels of interest
cfg.artfctdef.threshold.bpfilter  = 'no';                                   % use no additional bandpass
cfg.artfctdef.threshold.bpfreq    = [];
cfg.artfctdef.threshold.range     = 200;                                    % range 200 µV
cfg.showcallinfo                  = 'no';

fprintf('<strong>Detect transient artifacts...</strong>\n');
cfg_artifact = ft_artifact_threshold(cfg, data_preproc);

% Reject transient artifacts
cfg.artfctdef               = cfg_artifact.artfctdef;
cfg.artfctdef.reject        = 'partial';
cfg.artfctdef.minaccepttim  = 0.2;

fprintf('<strong>Reject transient artifacts...</strong>\n');
data_clean = ft_rejectartifact(cfg, data_preproc);

% Concatenate dataset
data_clean = concatenate( data_clean);

% -------------------------------------------------------------------------
% ICA decomposition
% -------------------------------------------------------------------------
cfg               = [];
cfg.method        = 'runica';
cfg.channel       = 'all';
cfg.trials        = 'all';
cfg.numcomponent  = 'all';
cfg.demean        = 'no';
cfg.updatesens    = 'no';
cfg.showcallinfo  = 'no';

fprintf('\n<strong>Run ICA decomposition...</strong>\n');
data_ica = ft_componentanalysis(cfg, data_clean);

% -------------------------------------------------------------------------
% Transform the whole data_prepoc into the component space
% -------------------------------------------------------------------------
cfg               = [];
cfg.unmixing      = data_ica.unmixing;
cfg.topolabel     = data_ica.topolabel;
cfg.demean        = 'no';
cfg.showcallinfo  = 'no';

ft_info off;
fprintf('\n<strong>Transform the whole filtered data into component space...</strong>\n');
data_comp = ft_componentanalysis(cfg, data_preproc);                         % estimate components by using the previously calculated unmixing matrix
ft_info on;

end

% -------------------------------------------------------------------------
% SUBFUNCTION for concatenation
% -------------------------------------------------------------------------
function [ data ] = concatenate( data )

numOfTrials = length(data.trial);                                           % estimate number of trials
trialLength = zeros(numOfTrials, 1);                                        
numOfChan   = size(data.trial{1}, 1);                                       % estimate number of channels

for i = 1:numOfTrials
  trialLength(i) = size(data.trial{i}, 2);                                  % estimate length of single trials
end

dataLength  = sum( trialLength );                                           % estimate number of all samples in the dataset
data_concat = zeros(numOfChan, dataLength);
time_concat = zeros(1, dataLength);
endsample   = 0;

for i = 1:numOfTrials
  begsample = endsample + 1;
  endsample = endsample + trialLength(i);
  data_concat(:, begsample:endsample) = data.trial{i}(:,:);                 % concatenate data trials
  if begsample == 1
    time_concat(1, begsample:endsample) = data.time{i}(:);                  % concatenate time vectors
  else
    if (data.time{i}(1) == 0 )
      time_concat(1, begsample:endsample) = data.time{i}(:) + ...
                                time_concat(1, begsample - 1) + ...         % create continuous time scale
                                1/data.fsample;
    elseif(data.time{i}(1) > time_concat(1, begsample - 1))
      time_concat(1, begsample:endsample) = data.time{i}(:);                % keep existing time scale
    else
      time_concat(1, begsample:endsample) = data.time{i}(:) + ...
                                time_concat(1, begsample - 1) + ...         % create continuous time scale
                                1/data.fsample - ...
                                data.time{i}(1);
    end
  end
end

data.trial       = [];
data.time        = [];
data.trial{1}    = data_concat;                                             % add concatenated data to the data struct
data.time{1}     = time_concat;                                             % add concatenated time vector to the data struct
data.trialinfo   = 0;                                                       % add a fake event number to the trialinfo for subsequend artifact rejection
data.sampleinfo  = [1 dataLength];                                          % add also a fake sampleinfo for subsequend artifact rejection

end
