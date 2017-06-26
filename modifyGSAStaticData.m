close all
clear
clc

% addpath('/Users/geoff/GitHub/circadian');
addpath('C:\Users\jonesg5\Documents\GitHub\circadian');
load('GSA_StaticData_DB.mat')

tempSession = vertcat(objArray.Session);
Session = {tempSession.Name}';
idxWinter = strcmp(Session,'Winter');

tempLocation = vertcat(objArray.Location);
BuildingName = {tempLocation.BuildingName}';
idxCOB = strcmp(BuildingName,'GSA Central Office Building');

idxSelect = idxWinter & idxCOB;

objArray = objArray(idxSelect);

for iObj = 1:numel(objArray)
    thisObj = objArray(iObj);
    
    t1 = datetime(2014,12,4,'TimeZone',thisObj.Time(1).TimeZone);
    t2 = datetime(2014,12,19,'TimeZone',thisObj.Time(1).TimeZone);
    
    idx = thisObj.Time >= t1 & thisObj.Time <= t2;
    objArray(iObj).Observation = idx & thisObj.Observation;
end

save('COB_Winter_StaticData_DB_modified.mat','objArray');
clear
load('COB_Winter_StaticData_DB_modified.mat')

Analysis = objArray.analysis;
excelName = fullfile('Tables',['COB_Winter_StaticData_',datestr(now,'yyyy-mmm-dd'),'_v1.xlsx']);
writetable(Analysis.Overall,excelName,'Sheet','Overall');
writetable(Analysis.Sunny,excelName,'Sheet','Sunny');
writetable(Analysis.Cloudy,excelName,'Sheet','Cloudy');