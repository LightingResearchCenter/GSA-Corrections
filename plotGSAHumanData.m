function plotGSAHumanData
close all
clc
load('GSA_HumanData_DB.mat');
Location = vertcat(objArray.Location);
City = {Location.City}';
BuildingName = {Location.BuildingName}';
Session = vertcat(objArray.Session);
SessionName = {Session.Name}';


unqBuilding = unique(BuildingName);
unqSession = unique(SessionName);

Subgroup = {'All','Work Days ONLY','Repeat Subjects and Work Days ONLY'};

for iB = 1:numel(unqBuilding)
    thisBuilding = unqBuilding{iB};
    idxBuilding = strcmp(thisBuilding,BuildingName);
    
    for iS = 1:numel(unqSession)
        thisSession = unqSession{iS};
        idxSession = strcmp(thisSession,SessionName);
        
        idx = idxBuilding & idxSession;
        
        if any(idx)
            ThisObjArray = objArray(idx);
            thisCity = ThisObjArray(1).Location.City;
            
            for iG = 1:numel(Subgroup)
                thisSubgroup = Subgroup{iG};
                
                fileID = ['GSA | HumanData | ',thisCity,' | ',thisBuilding,' | ',thisSession,' | ',thisSubgroup];
                
                generatePlots(ThisObjArray,thisSubgroup,fileID);
            end
            
        end
        
    end
    
end

end


function generatePlots(ObjArray,Subgroup,fileID)

switch Subgroup
    case 'All'
        Compliance = vertcat(ObjArray.Compliance);
        Observation = vertcat(ObjArray.Observation);
        idx = Compliance & Observation;
        t = vertcat(ObjArray.Time);
        ai = vertcat(ObjArray.ActivityIndex);
        cs = vertcat(ObjArray.CircadianStimulus);
        [millerTime,millerAI,millerCS] = millerize(t(idx),ai(idx),cs(idx));
        h = gcf;
        plot(millerTime,[millerAI,millerCS]);
        ylim([0,0.7])
        xlim(datenum([min(millerTime),max(millerTime)]));
        n = numel(ObjArray);
        Title = {fileID;['n = ',num2str(n)]};
        title(Title);
        millerName = ['Miller Plot | ',fileID,'.pdf'];
        millerPath = fullfile('Plots',millerName);
        saveas(h,millerPath)
        clf(h);
        
        Phasor = vertcat(ObjArray.Phasor);
        Vector = vertcat(Phasor.Vector);
        MeanVector = mean(Vector);
        
        [hAxes,hGrid,hLabels] = plots.phasoraxes;
        for ii = 1:numel(Vector)
            [~,hLine,hHead] = plots.phasorarrow(Vector(ii));
        end
        [~,hLine,hHead] = plots.phasorarrow(MeanVector);
        hLine.Color = 'red';
        hLine.LineWidth = 2;
        hHead.FaceColor = 'red';
        title(Title);
        phasorName = ['Phasor Plot | ',fileID,'.pdf'];
        phasorPath = fullfile('Plots',phasorName);
        saveas(h,phasorPath)
        clf(h);
        
    case 'Work Days ONLY'
        
    case 'Repeat Subjects and Work Days ONLY'
        
    otherwise
        
end



end


function [millerTime,millerAI,millerCS] = millerize(t,ai,cs)
%MILLERIZE Summary of this function goes here
%   Detailed explanation goes here

t10 = hour(t)*60 + floor(minute(t)/10)*10; % precise to 10 minutes

millerTimeArray_minutes = 0:10:(24*60-10);

nPoints = numel(millerTimeArray_minutes);

millerAI = zeros(nPoints,1);
millerCS = zeros(nPoints,1);

for i1 = 1:nPoints
    idx = t10 == millerTimeArray_minutes(i1);
    millerAI(i1) = mean(ai(idx));
    millerCS(i1) = mean(cs(idx));
end


millerTime = datetime('today','TimeZone','local') + duration(0,millerTimeArray_minutes',0);

end