function plotGSAHumanDataComposite

addpath('C:\Users\jonesg5\Documents\GitHub\circadian');

close all
clear
clc

load('GSA_HumanData_DB.mat');

saveDir = fullfile(pwd,'CompositeReports');

for iObj = 1:numel(objArray)
    Title = sprintf('%s \x2013 %s \x2013 Subject %s',...
        objArray(iObj).Location.BuildingName,...
        objArray(iObj).Session.Name,...
        objArray(iObj).ID);
    
    rpt = d12pack.composite(objArray(iObj));
    rpt.Title = Title;
    
    fileName = matlab.lang.makeValidName(sprintf('%s_%s_subject%s',...
        objArray(iObj).Location.BuildingName,...
        objArray(iObj).Session.Name,...
        objArray(iObj).ID));
    filePath = fullfile(saveDir,fileName);
    print(rpt.Figure,filePath,'-dpdf','-r300');
    close(rpt.Figure);
    
end

end