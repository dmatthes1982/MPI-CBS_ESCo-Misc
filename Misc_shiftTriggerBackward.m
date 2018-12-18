function Misc_shiftTriggerBackward( cfg )
% MISC_SHIFTTRIGGERBACKWARD shifts the markers back to their original 
% position. This function has to be executed after coding in INTERACT
% and before preprocessing the eeg data within the ESCo pipelines.
% Otherwise there will be a wrong relationship between eeg data and
% condition marker.
%
% Use as
%   Misc_shiftTriggerBackward( cfg )
%
% The configuration options are
%   cfg.videoStart  = video start trigger, estimated by MISC_ESTIMVIDEOSTART
%   cfg.vmrkFile    = modified VMRK file in Iinteract (e.g. '/data/p_01904/JOEI_Hauptstudie/EEG raw files/JOEI_05_shiftedForward.vmrk')
%
% The output file gets the suffix *_shiftedBackward.vmrk
%
% This function requires the fieldtrip toolbox.
%
% See also MISC_ESTIMVIDEOSTART, MISC_SHIFTTRIGGERFORWARD

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

if ~strcmp(events(1).type, 'Response')                                      % check if the input vmrk file was formerly forward shifted
  error(['The first trigger is not a ''Response R128'' trigger. This' ...
          ' vmrk file seems to be not forward shifted.']);
end

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
  events(i).sample = events(i).sample - abs(videoStart) - 1;                % shift the sample numbers backward
end

% -------------------------------------------------------------------------
% copy the existing vmrk file
% -------------------------------------------------------------------------
[filepath,name,ext] = fileparts(vmrkFile);
name = erase(name, '_shiftedForward');
fileCopy = [filepath, '/', name, '_shiftedBackward', ext];
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
