function [ videoStart, numOfFrames ] = Misc_estimVideoStart( cfg )
% MISC_ESTIMVIDEOSTART estimates the video start trigger by using the video
% stop trigger and the number of frames of the video files.
%
% Use as
%   [ videoStart, numOfFrames ] = Misc_estimVideoStart( cfg )
%
% The configuration options are
%   cfg.videoPath   = location of video files (e.g. '/data/p_01904/JOEI_Hauptstudie/videos/')
%   cfg.videoIdent  = video identifier (e.g. 'JOEI_05')
%   cfg.videoFs     = Video sampling rate (default: 25 pictures per second)
%   cfg.vmrkFile    = path to Brain Vision VMRK file (e.g. '/data/p_01904/JOEI_Hauptstudie/EEG raw files/JOEI_05.vmrk')
%   cfg.eegFs       = EEG sampling rate (default: 500 samples per second)
%
% NOTE: start matlab as follows: MATLAB --patch stdc++
%
% This function requires the fieldtrip toolbox.
%
% See also VIDEOREADER, FT_READ_HEADER

% Copyright (C) 2018, Daniel Matthes, MPI CBS

% -------------------------------------------------------------------------
% check config options
% -------------------------------------------------------------------------
videoPath   = ft_getopt(cfg, 'videoPath', []);
videoIdent  = ft_getopt(cfg, 'videoIdent', []);
videoFs     = ft_getopt(cfg, 'videoFs', 25);
vmrkFile    = ft_getopt(cfg, 'vmrkFile', []);
eegFs       = ft_getopt(cfg, 'eegFs', 500);

if ~isfolder(videoPath)                                                     % check video path
  error('%s is not a folder. Please correct cfg.videoPath!', videoPath);
end

if isempty(videoIdent)                                                      % check video identifier
  error('A video identifier has to be specified!');
end

if ~isfile(vmrkFile)                                                        % check eeg marker file
  error('%s is not a file. Please correct cfg.vmrkFile!', vmrkFile);
end

fileList    = dir([videoPath, videoIdent, '*.wmv']);                        % estimate video file names
if isempty(fileList)
  error('There is no video which is has the selected identifier.\n');
end
fileList    = struct2cell(fileList);
fileList    = fileList(1,:);
numOfFiles  = numel(fileList);

% -------------------------------------------------------------------------
% get video stop trigger
% -------------------------------------------------------------------------
events    = ft_read_event(vmrkFile);                                        % read events from marker file
element   = find(ismember({events.type},'Response'),1,'last');              % find last video trigger in file
if isempty(element)
  error('No video trigger was found in the selected vmrk file!');
end
videoStop = events(element).sample;                                         % get sample number of last video trigger

% -------------------------------------------------------------------------
% allocate memory
% -------------------------------------------------------------------------
numOfFrames = zeros(1, numOfFiles);
duration    = zeros(1, numOfFiles);

% -------------------------------------------------------------------------
% estimate total processing time
% -------------------------------------------------------------------------
for i = 1:1:numOfFiles
  v = VideoReader([videoPath fileList{i}]);                                 %#ok<TNMLP>
  duration(i) = v.duration;
end

numOfImg = sum(duration) * videoFs;

% -------------------------------------------------------------------------
% estimate video start trigger
% -------------------------------------------------------------------------
f = waitbar(0, sprintf('Please wait (0/%g)...', numOfImg));

totalFrames = 0;
for i = 1:1:numOfFiles
  v = VideoReader([videoPath fileList{i}]);                                 %#ok<TNMLP>
  frames = 0;
  while hasFrame(v)
    [~]         = readFrame(v);
    frames      = frames + 1;
    totalFrames = totalFrames + 1;
    waitbar(totalFrames/numOfImg, f, ...
                sprintf('Please wait (%g/%g)...', totalFrames, numOfImg));
  end
  numOfFrames(i) = frames;
end

close(f);
videoStart = videoStop - max(numOfFrames)*(eegFs/videoFs) + 1;

end
