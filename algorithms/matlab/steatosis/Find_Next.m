function q_next=Find_Next(q,cann_pts)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find_Next function finds the adjacent point of x that is next to the
% point in the candidate point set
% Params:
%   q is the point
%   cann_pts is the candidate points
% Return:
%   q_next is the result point
%   =======================================================================================
%   Copyright (C) 2018  Xiaoyuan Guo
%   Email: xiaoyuan.guo@emory.edu
%   =======================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

q_next=0;
for i=1:length(cann_pts)
    if q==cann_pts(i)&&i~=length(cann_pts)
        q_next=cann_pts(i+1);
    end
    if i==length(cann_pts)&&q==cann_pts(i)
        q_next=cann_pts(1);
    end
end