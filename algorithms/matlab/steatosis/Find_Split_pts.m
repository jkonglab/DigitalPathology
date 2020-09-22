function pts=Find_Split_pts(cann_pts,list_ind,close_nonadj_pts,count_nonadj)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find_Split_pts finds then splitting point pairs in a sub-candidate point
% set
% Params:
%   cann_pts is the candidate points
%   list_ind is the index number of candidate points
%   close_nonadj_pts records the close nonadjacent point pairs
%   count_nonadj is the number of close nonadjacent point pairs
% Return:
%   pts is the point pairs that split the candidate point set
%
%   =======================================================================================
%   Copyright (C) 2018  Xiaoyuan Guo
%   Email: xiaoyuan.guo@emory.edu
%   =======================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%find the splitted node point pairs
pts=zeros(2,2);
count=0;
n1=length(cann_pts);
n2=length(list_ind);
if ~n1
    return
end
for i=2:n1
    if In_nonadj_cand_pts(cann_pts(i),cann_pts(i-1),close_nonadj_pts,count_nonadj)
        count=count+1;
        pts(count,1)=cann_pts(i-1);
        pts(count,2)=cann_pts(i);
    end
end

if In_nonadj_cand_pts(cann_pts(n1),cann_pts(1),close_nonadj_pts,count_nonadj)
    count=count+1;
    pts(count,1)=cann_pts(n1);
    pts(count,2)=cann_pts(1);
end