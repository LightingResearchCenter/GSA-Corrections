function DataArray = scratch
%
addpath('C:\Users\jonesg5\Documents\GitHub\circadian');
addpath('C:\Users\jonesg5\Documents\GitHub\GSA-People-FloatingSchedule');

% Map directories
dataDirArray = mapDirs;

% Map data paths
[cdfPath,log_info_path,data_log_path] = mapData(dataDirArray);
[location,session] = path2loc(cdfPath);

%
nFile = numel(cdfPath);
for iFile = nFile:-1:1
    if exist(log_info_path{iFile},'file') == 2
        cdfData = daysimeter12.readcdf(cdfPath{iFile});
        [temp,~,~] = fileparts(cdfPath{iFile});
        temp2 = regexprep(temp,'croppedData','logs');
        bedLogPath = fullfile(temp2,['bedLog_subject',cdfData.GlobalAttributes.subjectID,'.xlsx']);
        workLogPath = fullfile(temp2,['workLog_subject',cdfData.GlobalAttributes.subjectID,'.xlsx']);
        if exist(bedLogPath,'file') == 2
            if exist(workLogPath,'file') == 2
                DataArray(iFile,1) = d12pack.convert2HumanData( ...
                    log_info_path{iFile}, ...
                    data_log_path{iFile}, ...
                    cdfData, ...
                    bedLogPath,workLogPath);
            else
                DataArray(iFile,1) = d12pack.convert2HumanData( ...
                    log_info_path{iFile}, ...
                    data_log_path{iFile}, ...
                    cdfData, ...
                    bedLogPath);
            end
        end
    end
end

end
% MARK: File path mapping

function dataDirArray = mapDirs

GSADir = '\\ROOT\projects\GSA_Daysimeter';

buildingBase = {
    'WashingtonDC\Daysimeter_People_Data';...
    'WashingtonDC-RegionalOfficeBldg-7th&Dstreet\Daysimeter_People_Data';...
    'Seattle_Washington\Daysimeter_People_Data\FCS_Building_1201';...
    'Seattle_Washington\Daysimeter_People_Data\FCS_Building_1202';...
    'GrandJunction_Colorado_site_data\Daysimeter_People_Data';...
    'Portland_Oregon_site_data\Daysimeter_People_Data'
    };

buildingDir = fullfile(GSADir,buildingBase);

summerDir = fullfile(buildingDir,'summer');
winterDir = fullfile(buildingDir,'winter');
seasonDir = [summerDir;winterDir];

dataDirArray = fullfile(seasonDir,'croppedData');

tfDir = dirDoesExist(dataDirArray);
if any(~tfDir)
    warning('Missing directories removed from list.');
    dataDirArray(~tfDir) = [];
end

end

function [cdfArray,loginfoPath,datalogPath] = mapData(dataDirArray)

tempCellArray = cellfun(@findCdf,dataDirArray,'UniformOutput',false);

cdfArray = vertcat(tempCellArray{:});

tempPath = regexprep(cdfArray,'croppedData','originalData');
tempPath2 = regexprep(tempPath,'_cropped','');
tempPath3 = regexprep(tempPath2,'_reprocessed','');
loginfoPath = regexprep(tempPath3,'\.cdf','-LOG.txt');
datalogPath = regexprep(tempPath3,'\.cdf','-DATA.txt');

end

function pathArray = findCdf(dirPath)

listing = dir([dirPath,filesep,'*.cdf']);

pathArray = fullfile(dirPath,{listing.name}');

end

function logPath = constructLogPath(cdfPath,subjectId)

[cdfDir,~,~] = fileparts(cdfPath);
[buildingDir,~,~] = fileparts(cdfDir);
logName = ['workLog_subject',subjectId,'.xlsx'];
logPath = fullfile(buildingDir,'logs',logName);

end

function TF = dirDoesExist(dirArray)

if iscell(dirArray)
    TF = cellfun(@isdir,dirArray);
else
    TF = isdir(dirArray);
end

end

function TF = fileDoesExist(pathArray)

fun = @(x) exist(x,'file') == 2;

if iscell(pathArray)
    TF = cellfun(fun,pathArray);
else
    TF = fun(pathArray);
end

end

function [location,session] = path2loc(cdfArray)
f = @(C)strsplit(C,filesep);
parts = cellfun(f,cdfArray,'UniformOutput',false);

location = cell(size(cdfArray));
session = cell(size(cdfArray));

for iC = 1:numel(cdfArray)
    theseParts = parts{iC};
    if numel(theseParts) == 10
        location{iC} = theseParts{7};
        session{iC} = theseParts{8};
    elseif numel(theseParts) == 9
        location{iC} = theseParts{5};
        session{iC} = theseParts{7};
    else
        error('Unknown file pattern');
    end
end

location = regexprep(location,'^WashingtonDC$','DC 1800F','ignorecase');
location = regexprep(location,'^WashingtonDC-RegionalOfficeBldg-7th&Dstreet$','DC ROB','ignorecase');
location = regexprep(location,'^FCS_Building_1201$','Seattle FCS 1201','ignorecase');
location = regexprep(location,'^FCS_Building_1202$','Seattle FCS 1202','ignorecase');
location = regexprep(location,'^GrandJunction_Colorado_site_data$','Grand Junction','ignorecase');
location = regexprep(location,'^Portland_Oregon_site_data$','Portland','ignorecase');
end
