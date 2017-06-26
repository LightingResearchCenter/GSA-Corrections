close all
clear
clc

% addpath('/Users/geoff/GitHub/circadian');
addpath('C:\Users\jonesg5\Documents\GitHub\circadian');

CalibrationPath = '\\root\projects\DaysimeterAndDimesimeterReferenceFiles\recalibration2016\calibration_log.csv';

DirStaticData = fullfile(pwd,'StaticData');
DirNames = {'DC-1800F','DC-ROB','Grand_Junction','Portland','Seattle-1202'};
DirLocation = fullfile(DirStaticData,DirNames);

IndexPath = fullfile(DirStaticData,'GSA_StaticData_Index.xlsx');

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
    WeatherPath = fullfile(DirSession,'logs','weatherLog.xlsx');
    
    BuildingShortName = DirNames{iLoc};
    idxBuilding = strcmpi(Index.BuildingShortName,BuildingShortName);
    
    for iSes = 1:numel(DirSession)
        Session = struct('Name',SessionName{iSes});
        
        DirCropped = fullfile(DirSession{iSes},'croppedData');
        DirOriginal = fullfile(DirSession{iSes},'originalData');
        
        ListingCropped = dir([DirCropped,filesep,'*.cdf']);
        
        cdfPath = fullfile(DirCropped,{ListingCropped.name}');
        cdfDate = datetime(regexprep(cdfPath,'.*croppedData.\d\d\d\d-(.*)\.cdf','$1'),'InputFormat','yyyy-MM-dd-HH-mm-ss');
        
        tempPath = regexprep(cdfPath,'croppedData(.\d\d\d\d)*.\.cdf','originalData$1*');
        searchLog = regexprep(cdfPath,['croppedData(\',filesep,'\d\d\d\d).*\.cdf'],'originalData$1*-LOG.txt');
        searchData = regexprep(cdfPath,['croppedData(\',filesep,'\d\d\d\d).*\.cdf'],'originalData$1*-DATA.txt');
        
        idxSession = strcmpi(Index.Session,SessionName{iSes}) & idxBuilding;
        
        ThisWeatherPath = WeatherPath{iSes};
        
        for iFile = 1:numel(cdfPath)
            ListingLog = dir(searchLog{iFile});
            if ~isempty(ListingLog)
                loginfoPath = fullfile(DirOriginal,{ListingLog.name}');
                logDate = datetime(regexprep(loginfoPath,'.*originalData.\d\d\d\d-(.*)-LOG\.txt','$1'),'InputFormat','yyyy-MM-dd-HH-mm-ss');
                [~,closest] = min(abs(logDate - cdfDate(iFile)));
                loginfoPath = loginfoPath{closest};
                
                datalogPath = regexprep(loginfoPath,'-LOG','-DATA');
                
                cdfData = daysimeter12.readcdf(cdfPath{iFile});
                SerialNumber = str2double(cdfData.GlobalAttributes.deviceSN(end-2:end));
                t1_cdf = (cdflib.epochBreakdown(cdfData.Variables.time(1)))';
                t1_cdf = t1_cdf(1:6); % Throw away ms
                t1_log = getOriginalStartTime(loginfoPath);
                
                
                
                idxSerialNumber = (Index.SerialNumber==SerialNumber) & idxSession;
                ThisIndex = Index(idxSerialNumber,:);
                
                ThisLocObj = LocObj;
                ThisLocObj.Workstation = ThisIndex.Workstation;
                ThisLocObj.Floor = ThisIndex.Floor;
                ThisLocObj.Wing = ThisIndex.Wing;
                ThisLocObj.Exposure = ThisIndex.Exposure;
                ThisLocObj.WindowProximity = ThisIndex.WindowProximity;
                
                thisObj = d12pack.StaticData;
                
                if all(t1_cdf == t1_log)
                    thisObj.TimeZoneLaunch = TimeZone{iLoc};
                else
                    thisObj.TimeZoneLaunch = 'America/New_York';
                end
                thisObj.TimeZoneDeploy = TimeZone{iLoc};
                
                thisObj.CalibrationPath = CalibrationPath;
                thisObj.RatioMethod = 'postir';
                
                thisObj.Orientation = ThisIndex.Orientation;
                thisObj.Type = ThisIndex.Type;
                thisObj.WeatherLog = thisObj.WeatherLog.import(ThisWeatherPath);
                
                % Add Location
                thisObj.Location = ThisLocObj;
                
                % Add Session
                thisObj.Session = Session;
                
                % Import the original data
                thisObj.log_info = thisObj.readloginfo(loginfoPath);
                thisObj.data_log = thisObj.readdatalog(datalogPath);
                
                % Add observation mask (accounting for cdfread error)
                thisObj.Observation = false(size(thisObj.Time));
                tmpObservation = logical(cdfData.Variables.logicalArray);
                thisObj.Observation(1:numel(tmpObservation),1) = tmpObservation(:);
                
                % Add error mask (accounting for cdfread error)
                if isfield(cdfData.Variables,'complianceArray')
                    thisObj.Error = true(size(thisObj.Time));
                    tmpError = ~logical(cdfData.Variables.complianceArray);
                    thisObj.Error(1:numel(tmpError),1) = tmpError(:);
                end
                
                if numel(thisObj.Calibration) >= 2
                    objArray(ii,1) = thisObj;
                    ii = ii + 1;
                else
                    iMissingCalibration = iMissingCalibration + 1;
                    display(['Missing calibration for SN: ', num2str(thisObj.SerialNumber)]);
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

save('GSA_StaticData_DB.mat','objArray');
close(h)

clear
load('GSA_StaticData_DB.mat')

Analysis = objArray.analysis;
excelName = fullfile('Tables',['GSA_StaticData_',datestr(now,'yyyy-mmm-dd'),'_v8.xlsx']);
writetable(Analysis.Overall,excelName,'Sheet','Overall');
writetable(Analysis.Sunny,excelName,'Sheet','Sunny');
writetable(Analysis.Cloudy,excelName,'Sheet','Cloudy');

