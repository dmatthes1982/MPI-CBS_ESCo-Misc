storeSound    = 1;                                                          % 0 = listen to sound / 1 = don't listen, save as *.wav

amplitude     = 1;                                                          % volume
fsample       = 44100;                                                      % sampling frequency in Hz
fsquare       = 10;                                                         % DESIRED FREQUENCY IN HZ
if fsquare > 40
  error('the maximum possible value is 40 Hz\n');                           % the maximum possible value is 40 Hz
end
if storeSound == 0
  duration    = 5;                                                          % duration in seconds
else
  duration    = 180;                                                        % length of recording in seconds
end
fsinus        = 400;                                                        % tone in Hz (i.e.: 440 Hz = standard pitch a)
t             = 1/fsample:1/fsample:duration;                               % time vector
sinus         = amplitude*sin(2*pi*fsinus * t);

winLength     = 551;                                                        % 551 sample = ca. 12.4943 ms (fsample44100)
u             = 0:1:winLength-1;                                            
y1            = tripuls(u-(44), 89, 1);                                     % 89 sample = ca. 2ms
y2            = rectpuls(u-(89+186), 373);                                  % 373 sample = ca 8.5 ms
y3            = tripuls(u-(89+373+44), 89, -1);                             % 89 sample = ca. 2ms
ybase         = zeros(1,fsample./fsquare);
ybase(1:551)  = y1+y2+y3;
delays        = random('Discrete Uniform', ...                              % calculate random delays
                        round(fsample/fsquare - 2 * winLength) - 1, 1, ...
                        duration * fsquare) - 1;            

y             = [];

for i=1:1:duration * fsquare
  ytemp       = circshift(ybase, delays(i));
  y           = [y, ytemp]; %#ok<AGROW>
end

signal = sinus .* y;

if storeSound == 0
  sound(signal, fsample);
else
  audiowrite(sprintf('asynch%dHz-400Hz-smooth.wav', fsquare), signal, fsample);
end

plot(t, signal);

clear storeSound amplitude fsample duration fsinus u y1 y2 y3 ybase ...
      delays y ytemp i sinus fsquare winLength