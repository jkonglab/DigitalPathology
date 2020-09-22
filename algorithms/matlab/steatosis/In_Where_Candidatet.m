function [ret,where]=In_Where_Candidatet(p,q,Candidate_pts,num_Candi_sets)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% In_Where_Candidatet is used to determine which sub-candidate point sets
% the point is in
% Params:
%   p,q are two points
%   Connected_Pts is the connected point sets
%   num_Candi_sets is the num of sub-candidate sets
% Return:
%   ret is the indicator 
%   where is the corresponding sub-candidate set index
%   =======================================================================================
%   Copyright (C) 2018  Xiaoyuan Guo
%   Email: xiaoyuan.guo@emory.edu
%   =======================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ret=[];
where=0;
for i=1:num_Candi_sets
    cand_pts=Candidate_pts{1,i};
    if sum(find(cand_pts==p))&&sum(find(cand_pts==q))
        ret=cand_pts;
        where=i;
    end
end