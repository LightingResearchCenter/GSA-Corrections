function plotGSAHumanDataDaysigrams

addpath('C:\Users\jonesg5\Documents\GitHub\circadian');

close all
clear
clc

load('GSA_HumanData_DB.mat');

saveDir = fullfile(pwd,'Daysigrams');

for iObj = 1:numel(objArray)
    t = objArray(iObj).Time(objArray(iObj).Observation);
    [y0,m0,d0] = ymd(t(1));
    [yf,mf,df] = ymd(t(end));
    StartTime = datetime(y0,m0,d0,'TimeZone',t(1).TimeZone);
    EndTime = datetime(yf,mf,df,'TimeZone',t(end).TimeZone) + caldays(1);
    
    Title = sprintf('%s \x2013 %s \x2013 Subject %s',...
        objArray(iObj).Location.BuildingName,...
        objArray(iObj).Session.Name,...
        objArray(iObj).ID);
    
    d = d12pack.daysigram(objArray(iObj),Title,StartTime,EndTime);
    nD = numel(d);
    for iD = 1:nD
        fileName = matlab.lang.makeValidName(sprintf('%s_%s_subject%s_%iof%i',...
            objArray(iObj).Location.BuildingName,...
            objArray(iObj).Session.Name,...
            objArray(iObj).ID,...
            iD,nD));
        filePath = fullfile(saveDir,fileName);
        print(d(iD).Figure,filePath,'-dpdf','-r300');
        close(d(iD).Figure);
    end
    
end

end