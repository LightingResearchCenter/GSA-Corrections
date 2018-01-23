function exportAIonly(obj,filepath,sheetName)
%EXPORT Summary of this function goes here
%   Detailed explanation goes here

varNames = { ...
    'Time', ...
    'ActivityIndex'};

t = table( ...
    obj.Time, ...
    round(obj.ActivityIndex*10000)/10000, ...
    'VariableNames',varNames);

t = t(obj.Observation,:);
writetable(t,filepath,'Sheet',sheetName);

end

