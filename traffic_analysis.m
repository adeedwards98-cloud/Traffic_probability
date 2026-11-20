%% Metro Interstate Traffic Volume - analysis
% Input : traffic_cleaned.csv (created by traffic_cleaning.m)

clear; clc; close all;

%% 1. Load the cleaned data
if ~isfile('traffic_cleaned.csv')
    error('traffic_cleaned.csv not found. Run traffic_cleaning.m first.');
end

data = readtable('traffic_cleaned.csv');
if ~isdatetime(data.DateTime)
    data.DateTime = datetime(data.DateTime, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
end
fprintf('Number of observations: %d\n', height(data));

%% 2. Histograms (Figures 1.1 and 1.2)
figure;
subplot(2,2,1);
histogram(data.TrafficVolume, 30, 'FaceColor', '#4C72B0');
title('Traffic Volume'); xlabel('Vehicles per hour'); ylabel('Frequency');

subplot(2,2,2);
histogram(data.TempC, 30, 'FaceColor', '#55A868');
title('Temperature'); xlabel('Temperature (°C)'); ylabel('Frequency');

subplot(2,2,3);
histogram(data.Clouds, 20, 'FaceColor', '#C44E52');
title('Cloud Cover'); xlabel('Cloud cover (%)'); ylabel('Frequency');

subplot(2,2,4);
histogram(data.Rain(data.Rain > 0), 30, 'FaceColor', '#D494C7');
title('Rain (hours with rain only)'); xlabel('Rain (mm per hour)'); ylabel('Frequency');

figure;
subplot(2,2,1);
histogram(data.Hour, -0.5:1:23.5, 'FaceColor', '#8172B2');
title('Hour of Day'); xlabel('Hour (0 to 23)'); ylabel('Frequency');

subplot(2,2,2);
histogram(data.DayOfWeek, 0.5:1:7.5, 'FaceColor', '#64B5CD');
title('Day of Week'); xlabel('Day (1 = Monday, 7 = Sunday)'); ylabel('Frequency');

subplot(2,2,3);
histogram(data.Month, 0.5:1:12.5, 'FaceColor', '#E39C50');
title('Month'); xlabel('Month (1 to 12)'); ylabel('Frequency');

subplot(2,2,4);
histogram(data.Snow(data.Snow > 0), 15, 'FaceColor', '#CCB974');
title('Snow (hours with snow only)'); xlabel('Snow (mm per hour)'); ylabel('Frequency');

%% 3. Histogram with fitted Normal curve (Figure 1.3)
traffic = data.TrafficVolume;
mu = mean(traffic);
sigma = std(traffic);

figure;
hh = histogram(traffic, 40, 'FaceColor', '#4C72B0');
hold on;
xx = linspace(min(traffic), max(traffic), 500);
pdfValues = exp(-0.5*((xx-mu)/sigma).^2) / (sigma*sqrt(2*pi));
plot(xx, pdfValues * numel(traffic) * hh.BinWidth, 'r', 'LineWidth', 2);
title('Traffic Volume with Fitted Normal Curve');
xlabel('Vehicles per hour'); ylabel('Frequency');
legend('Traffic Volume', 'Fitted Normal Curve');
hold off;

%% 4. Box plots of Traffic Volume (Figures 2.1 to 2.5)

% Figure 2.1: by hour
groups = unique(data.Hour);
figure; hold on;
for i = 1:numel(groups)
    drawBasicBox(data.TrafficVolume(data.Hour == groups(i)), i, 0.6);
end
xticks(1:numel(groups)); xticklabels(cellstr(string(groups)));
title('Traffic Volume by Hour of Day');
xlabel('Hour of day (0 to 23)'); ylabel('Vehicles per hour');
hold off;

% Figure 2.2: by day of week
groups = unique(data.DayOfWeek);
dayNames = {'Mon','Tue','Wed','Thu','Fri','Sat','Sun'};
figure; hold on;
for i = 1:numel(groups)
    drawBasicBox(data.TrafficVolume(data.DayOfWeek == groups(i)), i, 0.6);
end
xticks(1:numel(groups)); xticklabels(dayNames(groups));
title('Traffic Volume by Day of Week');
xlabel('Day of week'); ylabel('Vehicles per hour');
hold off;

% Figure 2.3: by holiday
groups = unique(data.IsHoliday);
figure; hold on;
for i = 1:numel(groups)
    drawBasicBox(data.TrafficVolume(data.IsHoliday == groups(i)), i, 0.6);
end
xticks(1:numel(groups)); xticklabels(cellstr(string(groups)));
title('Traffic Volume by Holiday');
xlabel('Holiday (0 = No, 1 = Yes)'); ylabel('Vehicles per hour');
hold off;

% Figure 2.4: by month
groups = unique(data.Month);
figure; hold on;
for i = 1:numel(groups)
    drawBasicBox(data.TrafficVolume(data.Month == groups(i)), i, 0.6);
end
xticks(1:numel(groups)); xticklabels(cellstr(string(groups)));
title('Traffic Volume by Month');
xlabel('Month (1 to 12)'); ylabel('Vehicles per hour');
hold off;

% Figure 2.5: by weather type
weatherLabels = cellstr(string(data.WeatherMain));
weatherGroups = unique(weatherLabels);
figure; hold on;
for i = 1:numel(weatherGroups)
    drawBasicBox(data.TrafficVolume(strcmp(weatherLabels, weatherGroups{i})), i, 0.6);
end
xticks(1:numel(weatherGroups)); xticklabels(weatherGroups); xtickangle(40);
title('Traffic Volume by Weather Type');
xlabel('Weather type'); ylabel('Vehicles per hour');
hold off;

%% 5. Bar chart of weather types (Figure 3.1)
weatherCounts = zeros(numel(weatherGroups), 1);
for i = 1:numel(weatherGroups)
    weatherCounts(i) = sum(strcmp(weatherLabels, weatherGroups{i}));
end
[weatherCounts, order] = sort(weatherCounts, 'descend');
sortedNames = weatherGroups(order);

figure;
bar(weatherCounts, 'FaceColor', '#F03C16');
xticks(1:numel(weatherCounts)); xticklabels(sortedNames); xtickangle(40);
title('Bar Chart Showing Weather Type Distribution', 'FontSize', 11);
xlabel('Weather type', 'FontSize', 10);
ylabel('Number of hours', 'FontSize', 10);

%% 6. Line chart for weekdays and weekends (Figure 3.2)
isWeekend = data.DayOfWeek >= 6;
meanWeekday = zeros(24, 1);
meanWeekend = zeros(24, 1);
for hr = 0:23
    meanWeekday(hr+1) = mean(data.TrafficVolume(~isWeekend & data.Hour == hr));
    meanWeekend(hr+1) = mean(data.TrafficVolume( isWeekend & data.Hour == hr));
end

figure;
plot(0:23, meanWeekday, 'LineWidth', 2); hold on;
plot(0:23, meanWeekend, 'LineWidth', 2);
title('Average Traffic Volume by Hour: Weekdays and Weekends');
xlabel('Hour of day'); ylabel('Average vehicles per hour');
legend('Weekdays (Mon to Fri)', 'Weekends (Sat, Sun)', 'Location', 'northwest');
grid on; hold off;

%% 7. Correlation heat map (Figure 4)
vars = {'Hour','DayOfWeek','Month','IsHoliday','TempC','Rain','Snow','Clouds','TrafficVolume'};
numericData = double(data{:, vars});
corrMatrix = corrcoef(numericData);
nVars = numel(vars);

figure;
imagesc(corrMatrix, [-1 1]);
axis square; colorbar;
if exist('turbo', 'file'), colormap(turbo); else, colormap(jet); end
xticks(1:nVars); xticklabels(vars); xtickangle(45);
yticks(1:nVars); yticklabels(vars);
title('Correlation Heatmap Showing Traffic Variables');
for i = 1:nVars
    for j = 1:nVars
        text(j, i, sprintf('%.2f', corrMatrix(i,j)), ...
            'HorizontalAlignment', 'center', 'FontSize', 8);
    end
end

%% 8. Summary statistics table (Figure 5)
Variable = vars';
MeanValue = mean(numericData, 1)';
MedianValue = median(numericData, 1)';
StdValue = std(numericData, 0, 1)';
Minimum = min(numericData, [], 1)';
Maximum = max(numericData, [], 1)';
centered = numericData - mean(numericData, 1);
SkewnessValue = (mean(centered.^3, 1) ./ (mean(centered.^2, 1).^1.5))';

stats = table(Variable, MeanValue, MedianValue, StdValue, Minimum, Maximum, SkewnessValue, ...
    'VariableNames', {'Variable','Mean','Median','Std','Min','Max','Skewness'});
disp(' ');
disp('Table Showing Summary Statistics for the Traffic Variables');
disp(stats);

%% 9. Splitting the data by whole days
% Every fifth calendar day (20%) is used for testing, with all of its hours.
dayIdx = floor(days(dateshift(data.DateTime, 'start', 'day') - datetime(2012,10,2)));
isTest = mod(dayIdx, 5) == 0;

predictors = {'Hour','DayOfWeek','Month','IsHoliday','TempC','Rain','Snow','Clouds'};
Xall = double(data{:, predictors});
Yall = double(data.TrafficVolume);

Xtrain = Xall(~isTest, :);   Ytrain = Yall(~isTest);
Xtest  = Xall(isTest, :);    Ytest  = Yall(isTest);
dayTrain = dayIdx(~isTest);
dayTest  = dayIdx(isTest);

fprintf('\nTraining hours: %d (%d days)\n', numel(Ytrain), numel(unique(dayTrain)));
fprintf('Testing hours : %d (%d days)\n', numel(Ytest),  numel(unique(dayTest)));

rmseFun = @(y, p) sqrt(mean((y - p).^2));
maeFun  = @(y, p) mean(abs(y - p));
r2Fun   = @(y, p) 1 - sum((y - p).^2) / sum((y - mean(y)).^2);

% Baseline: always predict the training average
predBase = mean(Ytrain) * ones(size(Ytest));

%% 10. Multiple Linear Regression (least squares with dummy variables)
% Hour, DayOfWeek and Month are treated as categories (first category = baseline).
XregTrain = [ones(size(Xtrain,1),1), ...
             makeDummies(Xtrain(:,1), 0:23), ...
             makeDummies(Xtrain(:,2), 1:7), ...
             makeDummies(Xtrain(:,3), 1:12), ...
             Xtrain(:,4:8)];
XregTest  = [ones(size(Xtest,1),1), ...
             makeDummies(Xtest(:,1), 0:23), ...
             makeDummies(Xtest(:,2), 1:7), ...
             makeDummies(Xtest(:,3), 1:12), ...
             Xtest(:,4:8)];

betaLR = XregTrain \ Ytrain;
predLR = XregTest * betaLR;

% Standard errors, t values and p values (normal approximation, large sample)
residTrain = Ytrain - XregTrain * betaLR;
dof = size(XregTrain,1) - size(XregTrain,2);
s2 = sum(residTrain.^2) / dof;
covB = s2 * inv(XregTrain' * XregTrain);
seB = sqrt(diag(covB));
tB = betaLR ./ seB;
pB = erfc(abs(tB) / sqrt(2));

lastRows = (numel(betaLR)-4):numel(betaLR);      % IsHoliday, TempC, Rain, Snow, Clouds
coefTable = table({'IsHoliday';'TempC';'Rain';'Snow';'Clouds'}, ...
    betaLR(lastRows), seB(lastRows), tB(lastRows), pB(lastRows), ...
    'VariableNames', {'Variable','Coefficient','StdError','tValue','pValue'});
disp(' ');
disp('Multiple Linear Regression: holiday and weather coefficients');
disp(coefTable);
fprintf('Training R2 = %.3f, number of coefficients = %d\n', ...
    r2Fun(Ytrain, XregTrain*betaLR), numel(betaLR));

%% 11. K-Nearest Neighbours (KNN) regression
% Euclidean distance on standardized predictors, using ALL training hours.
kValues = [1 3 5 7 10 15 20 30 50];
kMax = max(kValues);

% Choosing k with 4-fold cross-validation, folds made of whole days
foldID = mod(dayTrain, 5);            % values 1 to 4 (days divisible by 5 are the test days)
sqErr = zeros(numel(Ytrain), numel(kValues));

for f = 1:4
    trIdx = foldID ~= f;
    vaIdx = foldID == f;

    mF = mean(Xtrain(trIdx,:), 1);
    sF = std(Xtrain(trIdx,:), 0, 1);  sF(sF == 0) = 1;
    Xa = (Xtrain(trIdx,:) - mF) ./ sF;
    Xb = (Xtrain(vaIdx,:) - mF) ./ sF;

    nbr = nearestNeighbours(Xa, Xb, kMax);        % indices of the nearest training rows
    Ya = Ytrain(trIdx);
    Yb = Ytrain(vaIdx);
    rows = find(vaIdx);
    for i = 1:numel(kValues)
        pred = mean(Ya(nbr(:, 1:kValues(i))), 2);
        sqErr(rows, i) = (Yb - pred).^2;
    end
    fprintf('Cross-validation fold %d of 4 done\n', f);
end

cvRMSE = sqrt(mean(sqErr, 1));
[~, best] = min(cvRMSE);
kBest = kValues(best);
fprintf('\nBest KNN value (k): %d\n', kBest);

% Final KNN model
mT = mean(Xtrain, 1);
sT = std(Xtrain, 0, 1);  sT(sT == 0) = 1;
XtrainS = (Xtrain - mT) ./ sT;
XtestS  = (Xtest  - mT) ./ sT;

nbrFinal = nearestNeighbours(XtrainS, XtestS, kBest);
predKNN = mean(Ytrain(nbrFinal), 2);

%% 12. Model performance comparison (Figure 11)
results = table(["Baseline (mean)"; "Multiple Linear Regression"; "KNN"], ...
    [rmseFun(Ytest,predBase); rmseFun(Ytest,predLR); rmseFun(Ytest,predKNN)], ...
    [maeFun(Ytest,predBase);  maeFun(Ytest,predLR);  maeFun(Ytest,predKNN)], ...
    [r2Fun(Ytest,predBase);   r2Fun(Ytest,predLR);   r2Fun(Ytest,predKNN)], ...
    'VariableNames', {'Model','RMSE','MAE','R2'});
disp(' ');
disp('Model Performance Comparison');
disp(results);

% Extra details used in the report
wk = Xtest(:,2) <= 5;
fprintf('Weekday RMSE : Linear %.1f, KNN %.1f\n', rmseFun(Ytest(wk),predLR(wk)),  rmseFun(Ytest(wk),predKNN(wk)));
fprintf('Weekend RMSE : Linear %.1f, KNN %.1f\n', rmseFun(Ytest(~wk),predLR(~wk)), rmseFun(Ytest(~wk),predKNN(~wk)));
fprintf('Within 500 vehicles: Linear %.0f%%, KNN %.0f%%\n', ...
    100*mean(abs(Ytest-predLR) <= 500), 100*mean(abs(Ytest-predKNN) <= 500));

%% 13. KNN: cross-validated RMSE for different k (Figure 8)
figure;
plot(kValues, cvRMSE, '-o', 'LineWidth', 2);
xlabel('Number of neighbours (k)', 'FontSize', 12);
ylabel('Cross-validated RMSE', 'FontSize', 12);
title('KNN: Cross-Validated RMSE for Different k', 'FontSize', 14);
grid on;

%% 14. Linear Regression: predicted vs actual and residuals (Figures 6 and 7)
figure;
scatter(Ytest, predLR, 6, 'filled', 'MarkerFaceAlpha', 0.3); hold on;
plot([0 7500], [0 7500], '--', 'Color', [0.9 0.5 0.2], 'LineWidth', 2);
xlabel('Actual traffic volume (vehicles per hour)', 'FontSize', 12);
ylabel('Predicted traffic volume', 'FontSize', 12);
title('Linear Regression: Predicted vs Actual', 'FontSize', 14);
grid on; hold off;

figure;
histogram(Ytest - predLR, 50);
xlabel('Residual (actual minus predicted)', 'FontSize', 12);
ylabel('Frequency', 'FontSize', 12);
title('Linear Regression: Residuals', 'FontSize', 14);

%% 15. KNN: predicted vs actual and residuals (Figures 9 and 10)
figure;
scatter(Ytest, predKNN, 6, 'filled', 'MarkerFaceAlpha', 0.3); hold on;
plot([0 7500], [0 7500], '--', 'Color', [0.9 0.5 0.2], 'LineWidth', 2);
xlabel('Actual traffic volume (vehicles per hour)', 'FontSize', 12);
ylabel('Predicted traffic volume', 'FontSize', 12);
title(sprintf('KNN (k = %d): Predicted vs Actual', kBest), 'FontSize', 14);
grid on; hold off;

figure;
histogram(Ytest - predKNN, 50);
xlabel('Residual (actual minus predicted)', 'FontSize', 12);
ylabel('Frequency', 'FontSize', 12);
title(sprintf('KNN (k = %d): Residuals', kBest), 'FontSize', 14);

disp(' ');
disp('Analysis completed.');

%% Local functions (must stay at the end of the file)

function drawBasicBox(values, position, boxWidth)
    % Draws one box-and-whisker plot using only basic MATLAB commands.
    values = sort(values(:));
    if isempty(values), return; end
    q1 = basicPercentile(values, 25);
    q2 = basicPercentile(values, 50);
    q3 = basicPercentile(values, 75);
    spread = q3 - q1;
    inside = values(values >= q1 - 1.5*spread & values <= q3 + 1.5*spread);
    outliers = values(values < q1 - 1.5*spread | values > q3 + 1.5*spread);
    lowW = min(inside);
    upW  = max(inside);
    left = position - boxWidth/2;
    right = position + boxWidth/2;

    if q3 > q1
        rectangle('Position', [left, q1, boxWidth, q3 - q1], 'EdgeColor', 'b', 'LineWidth', 1.2);
    end
    plot([left right], [q2 q2], 'r-', 'LineWidth', 2);
    plot([position position], [lowW q1], 'k-');
    plot([position position], [q3 upW], 'k-');
    plot([position-boxWidth/4 position+boxWidth/4], [lowW lowW], 'k-');
    plot([position-boxWidth/4 position+boxWidth/4], [upW upW], 'k-');
    if ~isempty(outliers)
        plot(position*ones(size(outliers)), outliers, '+', 'Color', [0.85 0.33 0.1], 'MarkerSize', 4);
    end
end

function q = basicPercentile(sortedValues, p)
    % Percentile by linear interpolation for a sorted column vector.
    n = numel(sortedValues);
    if n == 1
        q = sortedValues(1);
        return;
    end
    r = 1 + (n - 1) * p / 100;
    lo = floor(r);
    hi = ceil(r);
    q = sortedValues(lo) * (1 - (r - lo)) + sortedValues(hi) * (r - lo);
end

function D = makeDummies(x, categoryValues)
    % 0/1 columns for every category except the first (the baseline).
    D = zeros(numel(x), numel(categoryValues) - 1);
    for c = 2:numel(categoryValues)
        D(:, c-1) = double(x == categoryValues(c));
    end
end

function nbr = nearestNeighbours(Xtrain, Xquery, k)
    % For every query row, returns the indices of its k nearest training rows
    % (Euclidean distance), nearest first. Works in batches to save memory.
    nQuery = size(Xquery, 1);
    nbr = zeros(nQuery, k);
    trainNorm = sum(Xtrain.^2, 2)';
    batch = 250;
    for first = 1:batch:nQuery
        last = min(first + batch - 1, nQuery);
        Q = Xquery(first:last, :);
        D = sum(Q.^2, 2) + trainNorm - 2 * (Q * Xtrain');
        [~, idx] = mink(D, k, 2);
        nbr(first:last, :) = idx;
    end
end
