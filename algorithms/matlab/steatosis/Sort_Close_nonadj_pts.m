function [new_close_nonadj_pts,distance]=Sort_Close_nonadj_pts(close_nonadj_pts,nonadj_close_distance,count_nonadj)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Sort_Close_nonadj_pts function sorts the close nonadjacent point pairs 
% according to the value of evaluating quality in descending order
% Params:
%   close_nonadj_pts stores those close nonadjacent point pairs
%   nonadj_close_distance records the distance of those nonadjacent point
%   pairs
%   count_nonadj is the number of those close nonadjacent point pairs
% Return:
%   new_close_nonadj_pts are the updated close nonadjacent point pairs
%   distance is the updated distance of those nonadjacent point pairs
%   =======================================================================================
%   Copyright (C) 2018  Xiaoyuan Guo
%   Email: xiaoyuan.guo@emory.edu
%   =======================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
new_close_nonadj_pts=zeros(1,2);
distance=zeros(1,1);
indx=0;
min=1000;
if count_nonadj>0
    close_nonadj_pts=Reduce_Null_Close_Pts(close_nonadj_pts,count_nonadj);
    for i=1:count_nonadj
        min=1000;
        indx=0;
        for j=1:count_nonadj
            if nonadj_close_distance(j)<min && nonadj_close_distance(j)
                min=nonadj_close_distance(j);
                indx=j;               
            end
        end
        new_close_nonadj_pts(i,1)=close_nonadj_pts(indx,1);
        new_close_nonadj_pts(i,2)=close_nonadj_pts(indx,2);
        distance(i)=nonadj_close_distance(indx);
        nonadj_close_distance(indx)=2000;
    end
end


