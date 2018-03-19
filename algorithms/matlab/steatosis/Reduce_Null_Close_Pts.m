function New_close_pts=Reduce_Null_Close_Pts(close_pts,count_adj)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Reduce_Null_Close_Pts function updates the candidate point index by removing 
% those null value of point pairs
% Params:
%   candidate_pts is the candidate points
%   remove_list records the index of points to be removed
% Return:
%   New_close_pts is the updated point pairs
%   =======================================================================================
%   Copyright (C) 2018  Xiaoyuan Guo
%   Email: xiaoyuan.guo@emory.edu
%   =======================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% This function is used for reducing those null values occured in the
% original close adjacent pts and nonadjacent pts matrix
N=count_adj;
New_close_pts=zeros(N,2);
count=0;
for i=1:N    
    if close_pts(i,1)&&close_pts(i,2)
       count=count+1;
       New_close_pts(count,1)=close_pts(i,1);
       New_close_pts(count,2)=close_pts(i,2);
    end
end

