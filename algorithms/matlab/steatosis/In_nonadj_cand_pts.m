function ret=In_nonadj_cand_pts(p,q,close_nonadj_pts,count_nonadj)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% In_nonadj_cand_pts function identifies the point pair in which close
% nonadjacent point pairs
% Params:
%   p,q are the point pairs
%   close_adj_pts records the close adjacent point pairs
%   count_nonadj is the number of close nonadjacent point pairs
% Return:
%   ret is the indicator
%   =======================================================================================
%   Copyright (C) 2018  Xiaoyuan Guo
%   Email: xiaoyuan.guo@emory.edu
%   =======================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ret=0;
if q==0 % detect the single point case
    for i=1:count_nonadj
        if  close_nonadj_pts(i,1)==p||close_nonadj_pts(i,2)==p
            ret=i;
        end
    end
else % detect the point pair case
    for i=1:count_nonadj
        if  (close_nonadj_pts(i,1)==p&&close_nonadj_pts(i,2)==q)||(close_nonadj_pts(i,1)==q&&close_nonadj_pts(i,2)==p)
            ret=i;
        end
    end    
end