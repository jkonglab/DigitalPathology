function [ret,index]=In_Cann_pts(p,cann_pts)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% In_Cann_pts function identifies whether a point pair is in candidate
% points
% Params:
%   p is the point
%   cann_pts is the candidate points
% Return:
%   ret is the indicator
%   index is the number index of the point found in candidate points
%   =======================================================================================
%   Copyright (C) 2018  Xiaoyuan Guo
%   Email: xiaoyuan.guo@emory.edu
%   =======================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ret=false;
index=0;
for i=1:length(cann_pts)
    if cann_pts(i)==p
        ret=true;  
        index=i;
    end
end