function new_candidate_pts=Remove_Pts(candidate_pts,remove_list)  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Remove_Pts function updates the candidate point index according to the
% removelist
% according to the value of evaluating quality in descending order
% Params:
%   candidate_pts is the candidate points
%   remove_list records the index of points to be removed
% Return:
%   new_candidate_pts is the updated candidate point pairs
%   distance is the updated distance of those nonadjacent point pairs
%   =======================================================================================
%   Copyright (C) 2018  Xiaoyuan Guo
%   Email: xiaoyuan.guo@emory.edu
%   =======================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

new_candidate_pts=[];
j=1;

for i=1:length(candidate_pts(1,:))
    if(~In_RemoveList(remove_list,candidate_pts(1,i)))
        new_candidate_pts(j)=candidate_pts(1,i);
        j=j+1;
    end  
end
