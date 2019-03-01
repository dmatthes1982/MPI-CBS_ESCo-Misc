addpath('utilities/arrow');                                                 % add path of arrow plotting function
Cond = zeros(1,30);                                                         % allocate memory

%% estimate random phase angles for condition one (3 trials 10 Sample points)
for i = 1:1:30
  comp = NaN;
  while(isnan(comp))
    comp = complex(randi([-9 9]), randi([-9 9]));
  end
  Cond(i) = comp/abs(comp);
end

Cond1 = reshape(Cond, 3,10);

%% estimate random phase angles for condition two (3 trials 10 Sample points)
for i = 1:1:30
  comp = NaN;
  while(isnan(comp))
    comp = complex(randi([-9 9]), randi([-9 9]));
  end
  Cond(i) = comp/abs(comp);
end

Cond2 = reshape(Cond, 3,10);

%% estimate random phase angles for condition three (3 trials 10 Sample points)
for i = 1:1:30
  comp = NaN;
  while(isnan(comp))
    comp = complex(randi([-9 9]), randi([-9 9]));
  end
  Cond(i) = comp/abs(comp);
end

Cond3 = reshape(Cond, 3,10);

%% Combine data of the three conditions into one dataset
CatCond = [Cond1; Cond2; Cond3];

%% Estimation of ITPC values for all conditions and the combined condition
ITPC(1,:) = abs(sum(Cond1, 1))/size(Cond1,1);
ITPC(2,:) = abs(sum(Cond2, 1))/size(Cond2,1);
ITPC(3,:) = abs(sum(Cond3, 1))/size(Cond3,1);
ITPC(4,:) = abs(sum(CatCond, 1))/size(CatCond,1);

%% Average ITPC values over timepoints (one value per condition)
meanITPC = zeros(4,1);

for i = 1:1:4
  meanITPC(i) = mean(ITPC(i,:));
end

%% Explanation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% If you compare the results of the element meanITPC, you will see the
% relation:
%
% meanITPC(4) ~= (meanITPC(1)+meanITPC(2)+meanITPC(3))/3
%
% This fact will be illustrated with the following figure.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% consider only the values at timepoint 1, estimate the resulting phase vector
ITPCvector(1,1) = sum(Cond1(:,1))/3;
ITPCvector(2,1) = sum(Cond2(:,1))/3;
ITPCvector(3,1) = sum(Cond3(:,1))/3;

%% draw a circle with radius 1
clf;
[~] = viscircles([0,0],1,'Color','b');
hold on;

%% estimate all vector endpoints and prepare the axis properties
v1end = [real(ITPCvector(1)), imag(ITPCvector(1))];
v2end = v1end + [real(ITPCvector(2)), imag(ITPCvector(2))];
v3end = v2end + [real(ITPCvector(3)), imag(ITPCvector(3))];

abs1end = [0 ITPC(1,1)];
abs2end = abs1end + [0 ITPC(2,1)];
abs3end = abs2end + [0 ITPC(3,1)];

maxVal = max(ceil(abs([v3end v2end v1end abs3end]))) + 1;

f = figure(1);
axis([-maxVal maxVal -maxVal maxVal]);
axis square;
f.Units = 'normalized';
f.OuterPosition = [0 0 1 1];

%% illustrate the estimation of the ITPC value for the combined condition
arrow([0 0], v1end);
arrow(v1end, v2end);
arrow(v2end, v3end);
arrow([0 0], v3end);
a1 = arrow([0 0], v3end/3, 'Color', 'g');

text(0, -maxVal+0.5, num2str(norm(v3end/3)), 'Color', 'g');

%% illustrate the estimation of averaged ITPC value over conditions
arrow([0 0], abs1end);
arrow(abs1end, abs2end);
arrow(abs2end, abs3end);
arrow([0 0], abs3end);
a2 = arrow([0 0], abs3end/3, 'Color', 'r');

text(-maxVal+0.5, 0, num2str(norm(abs3end/3)), 'Color', 'r');

legend([a1 a2], 'ITPC value of a combined condition (concatenate trials prior ITPC estimation)', ...
                'mean ITPC value (estimate average of the ITPC values over conditions of interest');

title('Estimation of ITPC');

clear comp Cond i v1end v2end v3end abs1end abs2end abs3end maxVal f a1 a2
