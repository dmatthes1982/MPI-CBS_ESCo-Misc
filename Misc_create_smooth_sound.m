storeSound    = 1;                                                          % 0 = listen to sound / 1 = don't listen, save as *.wav

amplitude     = 1;                                                          % volume
fsample       = 44100;                                                      % sampling frequency in Hz
fsquare       = 10;                                                         % DESIRED FREQUENCY IN HZ
if fsquare > 40                                                             % maximum possible value is 40 Hz
  error('the maximum possible value is 40 Hz\n');
end
if storeSound == 0
  duration    = 5;                                                          % duration in seconds
else
  duration    = 180;                                                        % length of recording in seconds
end

fsinus        = 400;                                                        % tone in Hz (i.e.: 440 Hz = standard pitch a)
t             = 0:1/fsample:duration-1/fsample;
sinus         = amplitude*sin(2*pi*fsinus * t);

ts            = 0:1:fsample-1;
ta            = 0:fsample/fsquare:fsample-1;
y1            = pulstran(ts-(44), ta, 'tripuls', 89, 1);                    % 89 sample = ca. 2ms
y2            = pulstran(ts-(89+186), ta, 'rectpuls', 373);                 % 373 sample = ca 8.5 ms
y3            = pulstran(ts-(89+373+44), ta, 'tripuls', 89, -1);            % 89 sample = ca. 2ms
ytemp         = y1+y2+y3;                                                   % 89+373+89 = 551 sample = ca. 12.4943 ms  

for i = 1:1:length(ytemp)-1                                                 % repair points of discontinuity
  if (abs(ytemp(i)-ytemp(i+1)) == 1)
    ytemp(i) = ytemp(i+1);
  end
end

y = zeros(1,fsample*duration);                                              % allocate memory

for i = 1:fsample:(duration*fsample)
  y(i:i+fsample-1) = ytemp(:);                                              % create complete function 
end


signal = sinus .* y;

if storeSound == 0
  sound(signal, fsample);
else
  audiowrite(sprintf('%dHz-400Hz-smooth.wav', fsquare), signal, fsample);
end

plot(t, signal);

clear storeSound fsample fsquare duration fsinus sinus ts ta y1 y2 y3 ...
      y ytemp i amplitude