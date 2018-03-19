function [close_nonadj_pts,count_nonadj]=Update_Close_Nonadj_pts(close_adj_pts,count_adj,close_nonadj_pts,count_nonadj,remove_list,nonadj_close_distance)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Update_Close_Nonadj_pts function updates the nonadjacent point pairs
% according to the remove list
% Params:
%   close_adj_pts records the close adjacent point pairs
%   count_adj is the number of close adjacent point pairs
%   close_nonadj_pts records the close nonadjacent point pairs
%   count_nonadj is the number of close nonadjacent point pairs
%   remove_list records the points that need to be removed
%   nonadj_close_distance records the distance of each close nonadjacent
%   point pair
% Return:
%   close_nonadj_pts is the updated close nonadjacent point pairs
%   count_nonadj is the number of the updated close nonadjacent point pairs
%   =======================================================================================
%   Copyright (C) 2018  Xiaoyuan Guo
%   Email: xiaoyuan.guo@emory.edu
%   =======================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clean=0;
[close_nonadj_pts,nonadj_close_distance]=Sort_Close_nonadj_pts(close_nonadj_pts,nonadj_close_distance,count_nonadj);
%update point index
l_rm=length(remove_list);
if l_rm
    for i=1:l_rm
        x1=remove_list(i);
        %judge wether x1 in close_nonadj_pts
        ret=In_nonadj_cand_pts(x1,0,close_nonadj_pts,count_nonadj);
        if ret%x1 in close_nonadj_pts
            ret2=In_nonadj_cand_pts(x1,0,close_adj_pts,count_adj);
            y=close_adj_pts(ret2,1);%(x1,y) are close adj points
            if y==x1
                y=close_adj_pts(ret2,2);
            end
            x2=close_nonadj_pts(ret,1);%(x1,x2) are close nonadj points

            if x2~=x1
                close_nonadj_pts(ret,2)=y;
            else
                close_nonadj_pts(ret,1)=y;
            end            
            
        end
    end 
end
                            
count_nonadj=count_nonadj-clean;
if count_nonadj
    close_nonadj_pts=Reduce_Null_Close_Pts(close_nonadj_pts,count_nonadj);
end