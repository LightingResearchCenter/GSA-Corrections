function StartTime = getOriginalStartTime(loginfoPath)
%GETSTARTTIME Summary of this function goes here
%   Detailed explanation goes here

fidInfo = fopen(loginfoPath,'r','b');
loginfo = fread(fidInfo,'uchar');
fclose(fidInfo);

q = find(loginfo==10,4,'first');
startDateTimeStr = char(loginfo(q(2)+1:q(2)+14))';
StartTime = datevec(startDateTimeStr,'mm-dd-yy HH:MM');

end

