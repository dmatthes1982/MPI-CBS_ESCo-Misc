function Misc_shiftTriggerForward( cfg )
% MISC_SHIFTTRIGGERFORWARD is writing the missing video start trigger into 
% a copy of the selected Brain Vision marker file and shifts the marker to
% the positive range, so that Interact will accept this new marker.
%
% Use as
%   Misc_shiftTriggerForward( cfg )  
%
% The configuration options are
%   cfg.videoStart  = video start trigger, estimated by MISC_ESTIMVIDEOSTART
%   cfg.vmrkFile    = path to Brain Vision VMRK file (e.g. '/data/p_01904/JOEI_Hauptstudie/EEG raw files/JOEI_05.vmrk')
%
% The output file gets the suffix *_shiftedForward.vmrk
%
% This function requires the fieldtrip toolbox.
%
% See also MISC_ESTIMVIDEOSTART

% Copyright (C) 2018, Daniel Matthes, MPI CBS

% -------------------------------------------------------------------------
% check config options
% -------------------------------------------------------------------------
videoStart  = ft_getopt(cfg, 'videoStart', []);
vmrkFile    = ft_getopt(cfg, 'vmrkFile', []);

if ~isnumeric(videoStart)                                                   % check video start trigger
  error('cfg.videoStart has to be a numeric value.');
end

if ~isfile(vmrkFile)                                                        % check eeg marker file
  error('%s is not a file. Please correct cfg.vmrkFile!', vmrkFile);
end

% -------------------------------------------------------------------------
% read events, fix offset column
% -------------------------------------------------------------------------
events = ft_read_event(vmrkFile);                                           % import markers

row = cellfun(@(x) isempty(x), {events.offset}, 'UniformOutput', false);
row = cell2mat(row);
[events(row).offset] = deal(0);                                             % fix the last column

% -------------------------------------------------------------------------
% insert video start trigger
% -------------------------------------------------------------------------
VidStartStruct.type     = 'Response';                                       % create structure for video start trigger
VidStartStruct.value    = 'R128';
VidStartStruct.sample   = videoStart;
VidStartStruct.duration = 1;
VidStartStruct.offset   = 0;

events = [VidStartStruct events];                                           % add video start trigger at the beginning of the marker list

% -------------------------------------------------------------------------
% fix type column
% -------------------------------------------------------------------------
for i=1:1:numel(events)
  events(i).type = sprintf('Mk%d=%s',i,events(i).type);                     % fix the type column
end

% -------------------------------------------------------------------------
% shift sample numbers forward
% -------------------------------------------------------------------------
for i=1:1:numel(events)
  events(i).sample = events(i).sample + abs(videoStart) + 1;                % shift the sample numbers to the positive range
end

% -------------------------------------------------------------------------
% copy the existing vmrk file
% -------------------------------------------------------------------------
[filepath,name,ext] = fileparts(vmrkFile);
fileCopy = [filepath, '/', name, '_shiftedForward', ext];
[~] = copyfile(vmrkFile, fileCopy);

% -------------------------------------------------------------------------
% modify copy of vmrk file
% -------------------------------------------------------------------------
fid = fopen(fileCopy,'r');                                                  % open the copied file

i = 1;
textLine = fgetl(fid);                                                      % import marker file line by line into the cell array vmrkContent
while ischar(textLine)
    vmrkContent{i,1} = textLine;                                            %#ok<AGROW>
    i = i+1;
    textLine = fgetl(fid);
end
fclose(fid);

row = find(contains(vmrkContent, 'New Segment'),1,'first');                 % get timestamp of the first 'New Segment' entry
newSegment = vmrkContent{row};
newSegment = strsplit(newSegment, ',');
newSegment = newSegment{end};

row = find(contains(vmrkContent, 'Mk1='));                                  % get first marker
vmrkContent = vmrkContent(1:row-1);                                         % delete all existing markers

shiftedMarkers = cell(numel(events), 1);                                    % transform event structure in a cell-array with one element for each trigger                                                                                   

for i=1:1:numel(events)
  shiftedMarkers{i} = sprintf('%s,%s,%d,%d,%d', events(i).type, ...
                  events(i).value, events(i).sample, events(i).duration,...
                  events(i).offset);
end

row = find(contains(shiftedMarkers, 'New Segment'));                        % re-add the saved timestamp of the first 'New Segment' entry
shiftedMarkers{row} = [ shiftedMarkers{row} ',' newSegment];

vmrkContent = [vmrkContent; shiftedMarkers];                                % add the shifted markers to the rest of the original vmrk file

fid = fopen(fileCopy, 'w');                                                 % write the content of the vmrkContent matrix into the new vmrk file
for i = 1:numel(vmrkContent)-1
  fprintf(fid,'%s\n', vmrkContent{i});
end
i = i+1;
fprintf(fid,'%s', vmrkContent{i});

end

