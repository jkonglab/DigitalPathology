function [ret,num]=In_Connected_Pts(p,q,Connected_Pts)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% In_Connected_Pts function identifies whether a point pair is in Connected
% points
% Params:
%   p,q are the points
%   Connected_Pts records the connected points
% Return:
%   ret is the indicator
%   num is the number index of the point pair found in connected points
%   =======================================================================================
%   Copyright (C) 2018  Xiaoyuan Guo
%   Email: xiaoyuan.guo@emory.edu
%   =======================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
num=0;
ret=false;
if p&&q %To detect whether (p,q) are connected
    for i=1:length(Connected_Pts(:,1))
        if (Connected_Pts(i,1)==p&&Connected_Pts(i,2)==q )|| (Connected_Pts(i,1)==q&&Connected_Pts(i,2)==p)
            ret=true;
            num=i;
        end
    end
else% to detect point p|q is used
    if p==0&&q~=0
        p=q;
        q=0;
    end
    for i=1:length(Connected_Pts(:,1))
        if (Connected_Pts(i,1)==p||Connected_Pts(i,2)==p)
            ret=true;
            num=i;
        end
    end
end
