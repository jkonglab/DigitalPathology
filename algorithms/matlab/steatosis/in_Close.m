function isnot=in_Close(p,close_adj_pts)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% in_Close function determines whether a point is in the close adjacent
% point pairs or not
% Params:
%   p is the points
%   close_adj_pts records the close adjacent point pairs
% Return:
%   isnot is the indicator
%   =======================================================================================
%   Copyright (C) 2018  Xiaoyuan Guo
%   Email: xiaoyuan.guo@emory.edu
%   =======================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
isnot=0;
for i=1:length(close_adj_pts(:,1))
    if close_adj_pts(i,1)==p
        isnot=close_adj_pts(i,2);
    elseif close_adj_pts(i,2)==p
        isnot=close_adj_pts(i,1);
    end
end
if isnot~=0
    return
end