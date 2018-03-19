function [cand_pts1,cand_pts2]=Split_Candidate_Pts(p,q,candidate_pts)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Split_Candidate_Pts function splits candidate points divided by point the 
% point pair(p,q)
% Params:
%   p,q are the point pair that needs to be connected 
%   b is the clumped nuclei boundary point coordinates
%   candidate_pts is the set of candidate points
% Return:
%   cand_pts1,cand_pts2 are two subset of candidate points
%   =======================================================================================
%   Copyright (C) 2018  Xiaoyuan Guo
%   Email: xiaoyuan.guo@emory.edu
%   =======================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

n=length(candidate_pts);
cand_pts1=[];
cand_pts2=[];
num_1=1;
num_2=1;
[p,q]=Swap_pq(p,q);
for i=1:n
    if candidate_pts(i)<p||candidate_pts(i)>q
    	cand_pts1(num_1)=candidate_pts(i); 
    	num_1=num_1+1;
    elseif candidate_pts(i)>p||candidate_pts(i)<q
    	cand_pts2(num_2)=candidate_pts(i); 
    	num_2=num_2+1;
    end
    if candidate_pts(i)==p||candidate_pts(i)==q
        cand_pts1(num_1)=candidate_pts(i); 
       num_1=num_1+1;
    end
end


