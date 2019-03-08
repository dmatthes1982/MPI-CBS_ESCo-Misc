t = 0.002:0.002:1;                                                          % time vector, one second, sample frequency 50 Hz
f = 5:0.05:13;                                                              % frequency vector, 7-13 Hz in steps of 50 mHz

% without noise
x = sin(2*pi*10*t);                                                         % 10 Hz sinusoidal signal without noise
plv = zeros(1, numel(f));

for j = 1:1:numel(f)
  y = sin(2*pi*f(j)*t);
  phasediff = angle(hilbert(x)) - angle(hilbert(y));
  plv(j) = abs( sum(exp(1i*phasediff)) ) / numel(t);                        % estimate plv values for certain frequency differences
end

% with noise
x = sin(2*pi*10*t) + 0.5*randn(size(t));                                    % 10 Hz sinusoidal signal with noise
plv_noise = zeros(1, numel(f));

for j = 1:1:numel(f)
  y = sin(2*pi*f(j)*t) + 0.5*randn(size(t));
  phasediff = angle(hilbert(x)) - angle(hilbert(y));
  plv_noise(j) = abs( sum(exp(1i*phasediff)) ) / numel(t);                  % estimate plv values for certain frequency differences
end

subplot(1,2,1);                                                             % plot results
plot(f, plv);
title('PLV - 10 Hz sine vs. sine wave of other frequencies');
xlabel('frequency of signal 2 in Hz');
ylabel('PLV');

subplot(1,2,2);
plot(f, plv_noise);
title('PLV - 10 Hz sine vs. sine wave of other frequencies (with noise)'); 
xlabel('frequency of second sine wave in Hz');
ylabel('PLV');

clear j f phasediff t x y
