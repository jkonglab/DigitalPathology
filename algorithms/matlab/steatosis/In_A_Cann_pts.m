function [in,cann_pts]=In_A_Cann_pts(p,q,Candidate_pts,n)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% In_A_Cann_pts function determines which sub-candidate point sets the
% point pair is in
% Params:
%   p,q are the point pair that needs to be connected 
%   Candidate_pts is the set of sub-candidate points
%   n is the number of sub-candidate point sets
% Return:
%   in is the indicator 
%   cand_pts is the candidate point set that the point pair in
%   =======================================================================================
%   Copyright (C) 2018  Xiaoyuan Guo
%   Email: xiaoyuan.guo@emory.edu
%   =======================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cann_pts=[];
in=false;

for i=1:n
    if In_Cann_pts(p,Candidate_pts{1,i})&& In_Cann_pts(q,Candidate_pts{1,i})
        cann_pts=Candidate_pts{1,i};
        in=true;
    end
end
