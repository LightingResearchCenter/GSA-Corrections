%% Reset MATLAB
fclose('all');
close all
clear
clc

%% Turn off warnings
warning('off','MATLAB:xlswrite:AddSheet');

%% Enable dependencies
addpath('C:\Users\jonesg5\Documents\GitHub\d12pack');

%% Generate timestamp
timestamp = datestr(now,'yyyy-mm-dd HHMM');

%% Map paths
projectDir = '\\ROOT\projects\GSA_Daysimeter\ORGANIZED GSA';
exportDir = fullfile(projectDir, 'ExportedData');
dbPath = fullfile(projectDir, 'GSA_HumanData_DB.mat');

%% Load and preprocess data
load(dbPath);

L = vertcat(objArray.Location);
L = categorical({L.BuildingName}');
L = renamecats(L, matlab.lang.makeValidName(categories(L)));

S = vertcat(objArray.Session);
S = categorical({S.Name}');
S = renamecats(S, regexprep(categories(S),'(.).*','${upper($1)}'));

ID = categorical({objArray.ID}');

filePaths  = string([exportDir,filesep]) + string(L) + ".xlsx";
sheetNames = string(S) + " " + string(ID);

%% Iterate through objects
nObj = numel(objArray);
h = waitbar(0,'Exporting data. Please wait ...');
for iObj = 1:nObj
    exportAIonly(objArray(iObj),filePaths(iObj),sheetNames(iObj));
    waitbar(iObj/nObj,h);
end
close(h);

%% Turn on warnings
warning('on','MATLAB:xlswrite:AddSheet');


