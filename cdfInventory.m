close all
clear
clc

% addpath('/Users/geoff/GitHub/circadian');
addpath('C:\Users\jonesg5\Documents\GitHub\circadian');

DirStaticData = fullfile(pwd,'StaticData');
DirNames = {'DC-1800F','DC-ROB','Grand_Junction','Portland','Seattle-1202'};
DirLocation = fullfile(DirStaticData,DirNames);

ii = 1;

for iLoc = 1:numel(DirLocation)
    
    
    ListingLoc = dir(DirLocation{iLoc});
    ListingLoc = ListingLoc([ListingLoc.isdir],:);
    dotDir = strcmp({ListingLoc.name}','.') | strcmp({ListingLoc.name}','..');
    ListingLoc(dotDir,:) = [];
    SessionName = {ListingLoc.name}';
    DirSession = fullfile(DirLocation{iLoc},SessionName);
    
    for iSes = 1:numel(DirSession)
        Session = struct('Name',SessionName{iSes});
        
        DirCropped = fullfile(DirSession{iSes},'croppedData');
        
        ListingCropped = dir([DirCropped,filesep,'*.cdf']);
        
        cdfPath = fullfile(DirCropped,{ListingCropped.name}');
        
        for iFile = 1:numel(cdfPath)
            cdfData = daysimeter12.readcdf(cdfPath{iFile});
            SN(ii,1) = str2double(cdfData.GlobalAttributes.deviceSN(end-2:end));
            ID{ii,1} = cdfData.GlobalAttributes.subjectID;
            t1_cdf = (cdflib.epochBreakdown(cdfData.Variables.time(1)))';
            DateUsed{ii,1} = datetime(t1_cdf(1:3));
            FileName{ii,1} = ListingCropped(iFile).name;
            
            ii = ii + 1;
        end
    end
end

staticInventory = table(SN,DateUsed,ID,FileName);
writetable(staticInventory,'StaticCDFInventory.xlsx');

%%
DirHumanData = fullfile(pwd,'HumanData');
DirNames = {'DC-1800F','DC-ROB','Grand_Junction','Portland','Seattle-1202'};
DirLocation = fullfile(DirHumanData,DirNames);

clear('SN','ID','DateUsed','FileName');

ii = 1;

for iLoc = 1:numel(DirLocation)
    
    
    ListingLoc = dir(DirLocation{iLoc});
    ListingLoc = ListingLoc([ListingLoc.isdir],:);
    dotDir = strcmp({ListingLoc.name}','.') | strcmp({ListingLoc.name}','..');
    ListingLoc(dotDir,:) = [];
    SessionName = {ListingLoc.name}';
    DirSession = fullfile(DirLocation{iLoc},SessionName);
    
    for iSes = 1:numel(DirSession)
        Session = struct('Name',SessionName{iSes});
        
        DirCropped = fullfile(DirSession{iSes},'croppedData');
        
        ListingCropped = dir([DirCropped,filesep,'*.cdf']);
        
        cdfPath = fullfile(DirCropped,{ListingCropped.name}');
        
        for iFile = 1:numel(cdfPath)
            cdfData = daysimeter12.readcdf(cdfPath{iFile});
            SN(ii,1) = str2double(cdfData.GlobalAttributes.deviceSN(end-2:end));
            ID{ii,1} = cdfData.GlobalAttributes.subjectID;
            t1_cdf = (cdflib.epochBreakdown(cdfData.Variables.time(1)))';
            DateUsed{ii,1} = datetime(t1_cdf(1:3));
            FileName{ii,1} = ListingCropped(iFile).name;
            
            ii = ii+1;
        end
    end
end

HumanInventory = table(SN,DateUsed,ID,FileName);
writetable(HumanInventory,'HumanCDFInventory.xlsx');