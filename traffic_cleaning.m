%% Metro Interstate Traffic Volume - data cleaning
% Input : Metro_Interstate_Traffic_Volume.csv (UCI Machine Learning Repository)
% Output: traffic_cleaned.csv

raw = readtable('Metro_Interstate_Traffic_Volume.csv');

% Make sure the date column is a datetime and put the rows in time order
if ~isdatetime(raw.date_time)
    raw.date_time = datetime(raw.date_time, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
end
raw = sortrows(raw, 'date_time');

% The holiday name is only written on the first hour of the day,
% so every hour of that day is marked as a holiday
holidayRows = ~strcmp(string(raw.holiday), 'None');
holidayDays = unique(dateshift(raw.date_time(holidayRows), 'start', 'day'));
raw.IsHoliday = double(ismember(dateshift(raw.date_time, 'start', 'day'), holidayDays));

% Remove repeated hours (same time stamp, extra weather record)
[~, keep] = unique(raw.date_time, 'stable');
raw = raw(keep, :);

% Remove impossible values: 0 Kelvin, rain of 9831 mm, and 0 vehicles per hour
bad = raw.temp <= 0 | raw.rain_1h > 1000 | raw.traffic_volume == 0;
raw = raw(~bad, :);

% Build the cleaned table
data = table(raw.date_time, ...
             hour(raw.date_time), ...
             mod(weekday(raw.date_time) - 2, 7) + 1, ...   % Monday = 1 ... Sunday = 7
             month(raw.date_time), ...
             raw.IsHoliday, ...
             round(raw.temp - 273.15, 2), ...              % Kelvin to degrees Celsius
             raw.rain_1h, raw.snow_1h, raw.clouds_all, ...
             string(raw.weather_main), ...
             raw.traffic_volume, ...
             'VariableNames', {'DateTime','Hour','DayOfWeek','Month','IsHoliday', ...
                               'TempC','Rain','Snow','Clouds','WeatherMain','TrafficVolume'});

writetable(data, 'traffic_cleaned.csv');
disp(height(data));    % number of rows kept (40,562 expected)