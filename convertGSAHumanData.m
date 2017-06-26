close all
clear
clc

% addpath('/Users/geoff/GitHub/circadian');
addpath('C:\Users\jonesg5\Documents\GitHub\circadian');

CalibrationPath = '\\root\projects\DaysimeterAndDimesimeterReferenceFiles\recalibration2016\calibration_log.csv';

DirHumanData = fullfile(pwd,'HumanData');
DirNames = {'DC-1800F','DC-ROB','Grand_Junction','Portland','Seattle-1202'};
DirLocation = fullfile(DirHumanData,DirNames);

IndexPath = fullfile(DirHumanData,'GSA_HumanData_Index.xlsx');

City = {'Washington','Washington','Grand Junction','Portland','Seattle'};
State = {'District of Columbia','District of Columbia','Colorado','Oregon','Washington'};
Abbrv = {'DC','DC','CO','OR','WA'};
ZIP = {'20405-0001','20407-0001','81501-2550','97204-2825','98134-2388'};
Street = {'1800 F ST NW','7TH & D STREETS','400 ROOD AVE','1220 SW 3RD AVE','4735 E MARGINAL WAY S'};
BuildingName = {...
    'GSA Central Office Building',...
    'GSA Regional Office Building',...
    'Wayne Aspinall Federal Building',...
    'Edith Green - Wendell Wyatt Federal Building',...
    'Federal Center South Building, 1202'};
TimeZone = {'America/New_York','America/New_York','America/Denver','America/Los_Angeles','America/Los_Angeles'};

Index = readtable(IndexPath);

ii = 1;
jj = 0;
iMissingCalibration = 0;
h = waitbar(0,'Please wait...');
nLoc = numel(DirLocation);
for iLoc = 1:nLoc
    waitbar(iLoc/nLoc);
    
    LocObj = d12pack.LocationData;
    LocObj.City = City{iLoc};
    LocObj.State_Territory = State{iLoc};
    LocObj.PostalStateAbbreviation = Abbrv{iLoc};
    LocObj.ZIP = ZIP{iLoc};
    LocObj.Street = Street{iLoc};
    LocObj.BuildingName = BuildingName{iLoc};
    LocObj.Country = 'United States of America';
    LocObj.Organization = 'General Services Administration';
    
    ListingLoc = dir(DirLocation{iLoc});
    ListingLoc = ListingLoc([ListingLoc.isdir],:);
    dotDir = strcmp({ListingLoc.name}','.') | strcmp({ListingLoc.name}','..');
    ListingLoc(dotDir,:) = [];
    SessionName = {ListingLoc.name}';
    DirSession = fullfile(DirLocation{iLoc},SessionName);
    
    BuildingShortName = DirNames{iLoc};
    idxBuilding = strcmpi(Index.BuildingShortName,BuildingShortName);
    
    for iSes = 1:numel(DirSession)
        Session = struct('Name',SessionName{iSes});
        
        DirCropped = fullfile(DirSession{iSes},'croppedData');
        DirOriginal = fullfile(DirSession{iSes},'originalData');
        DirLogs = fullfile(DirSession{iSes},'logs');
        
        ListingCropped = dir([DirCropped,filesep,'*.cdf']);
        
        cdfPath = fullfile(DirCropped,{ListingCropped.name}');
        cdfDate = datetime(regexprep(cdfPath,'.*croppedData.\d\d\d\d-(.*)\.cdf','$1'),'InputFormat','yyyy-MM-dd-HH-mm-ss');
        
        tempPath = regexprep(cdfPath,'croppedData(.\d\d\d\d)*.\.cdf','originalData$1*');
        searchLog = regexprep(cdfPath,['croppedData(\',filesep,'\d\d\d\d).*\.cdf'],'originalData$1*-LOG.txt');
        searchData = regexprep(cdfPath,['croppedData(\',filesep,'\d\d\d\d).*\.cdf'],'originalData$1*-DATA.txt');
        
        idxSession = strcmpi(Index.Session,SessionName{iSes}) & idxBuilding;
        
        for iFile = 1:numel(cdfPath)
            ListingLog = dir(searchLog{iFile});
            if ~isempty(ListingLog)
                loginfoPath = fullfile(DirOriginal,{ListingLog.name}');
                logDate = datetime(regexprep(loginfoPath,'.*originalData.\d\d\d\d-(.*)-LOG\.txt','$1'),'InputFormat','yyyy-MM-dd-HH-mm-ss');
                [~,closest] = min(abs(logDate - cdfDate(iFile)));
                loginfoPath = loginfoPath{closest};
                
                datalogPath = regexprep(loginfoPath,'-LOG','-DATA');
                
                cdfData = daysimeter12.readcdf(cdfPath{iFile});
                ID = cdfData.GlobalAttributes.subjectID;
                t1_cdf = (cdflib.epochBreakdown(cdfData.Variables.time(1)))';
                t1_cdf = t1_cdf(1:6); % Throw away ms
                t1_log = getOriginalStartTime(loginfoPath);
                
                idxID = (Index.ID==str2double(ID)) & idxSession;
                ThisIndex = Index(idxID,:);
                
                ThisLocObj = LocObj;
                
                if all(t1_cdf == t1_log)
                    thisObj.TimeZoneLaunch = TimeZone{iLoc};
                else
                    thisObj.TimeZoneLaunch = 'America/New_York';
                end
                thisObj.TimeZoneDeploy = TimeZone{iLoc};
                
                ThisLocObj.Workstation = ThisIndex.Workstation;
                ThisLocObj.Floor = ThisIndex.Floor;
                ThisLocObj.Wing = ThisIndex.Wing;
                ThisLocObj.Exposure = ThisIndex.Exposure;
                
                bedLogPath = fullfile(DirLogs,['bedLog_subject',ID,'.xlsx']);
                workLogPath = fullfile(DirLogs,['workLog_subject',ID,'.xlsx']);
                
                thisObj = d12pack.HumanData;
                thisObj.CalibrationPath = CalibrationPath;
                thisObj.RatioMethod = 'lowluxthreshold';
                
                % Add subject ID
                thisObj.ID = ID;
                
                % Add Location
                thisObj.Location = ThisLocObj;
                
                % Add Session
                thisObj.Session = Session;
                
                if exist(bedLogPath,'file') == 2
                    
                    % Add bed log
                    thisObj.BedLog = thisObj.BedLog.import(bedLogPath);
                    
                    % Add work log
                    if exist(workLogPath,'file') == 2
                        thisObj.WorkLog = thisObj.WorkLog.import(workLogPath);
                    else
                        thisObj.WorkLog = d12pack.WorkLogData;
                        thisObj.WorkLog.StartTime = duration(9,0,0);
                        thisObj.WorkLog.EndTime = duration(17,0,0);
                    end
                    
                    % Import the original data
                    thisObj.log_info = thisObj.readloginfo(loginfoPath);
                    thisObj.data_log = thisObj.readdatalog(datalogPath);
                    
                    % Add observation mask (accounting for cdfread error)
                    thisObj.Observation = false(size(thisObj.Time));
                    tmpObservation = logical(cdfData.Variables.logicalArray);
                    thisObj.Observation(1:numel(cdfData.Variables.logicalArray),1) = tmpObservation(:);
                    
                    % Add compliance mask (accounting for cdfread error)
                    thisObj.Compliance = true(size(thisObj.Time));
                    tmpCompliance = logical(cdfData.Variables.complianceArray);
                    thisObj.Compliance(1:numel(cdfData.Variables.complianceArray),1) = tmpCompliance(:);
                    
                    if numel(thisObj.Calibration) >= 2
                        objArray(ii,1) = thisObj;
                        ii = ii + 1;
                    else
                        iMissingCalibration = iMissingCalibration + 1;
                        display(['Missing calibration for SN: ', num2str(thisObj.SerialNumber)]);
                    end
                else
                    warning(['Missing: ',bedLogPath]);
                    display(cdfPath{iFile});
                    display(loginfoPath);
                end
            end
            jj = jj + 1;
        end
    end
end

percentComplete = 100*numel(objArray)/jj;
display(percentComplete);

percentMissingCalibration = 100*iMissingCalibration/jj;
display(percentMissingCalibration);

save('GSA_HumanData_DB.mat','objArray');
close(h)

clear
load('GSA_HumanData_DB.mat')

Analysis = objArray.analysis;
excelName = fullfile('Tables',['GSA_HumanData_',datestr(now,'yyyy-mmm-dd'),'_v10.xlsx']);
writetable(Analysis,excelName);

