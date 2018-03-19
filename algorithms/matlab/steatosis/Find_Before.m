function p_before=Find_Before(p,cann_pts)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find_Before finds the adjacent point in the candidate points that has
% smaller point index than a specific point
% Params:
%   p is the point
%   cann_pts is the candidate points
% Return:
%   ret indicates whether the point pair (p,q) is close nonadjacent or not
%
%   =======================================================================================
%   Copyright (C) 2018  Xiaoyuan Guo
%   Email: xiaoyuan.guo@emory.edu
%   =======================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

p_before=0;
for i=1:length(cann_pts)
    if p==cann_pts(i)&&i~=1
        p_before=cann_pts(i-1);
    end
    if i==1&&p==cann_pts(i)
        p_before=cann_pts(length(cann_pts));
    end
end