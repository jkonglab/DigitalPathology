function [unused_num,left_pts,go_on]=Left_Unconnected(cann_pts,Connected_Pts)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Left_Unconnected is the points left unconnected
% Params:
%   cann_pts is the candidate points
%   Connected_Pts is the connected point pairs
% Return:
%   unused_num is the number of unused candidate points
%   left_pts is the points left unconnected
%   go_on is the indicator whether the segmentation should continue
%   =======================================================================================
%   Copyright (C) 2018  Xiaoyuan Guo
%   Email: xiaoyuan.guo@emory.edu
%   =======================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

K=length(cann_pts);
used_num=0;
unused_num=0;
left_pts=[];

for i=1:K
    p=cann_pts(i);
    q=0;
    [ret,~]=In_Connected_Pts(p,q,Connected_Pts);
    if ret
        used_num=used_num+1;
    else
        unused_num=unused_num+1;
        left_pts(unused_num)=p;
    end
end
% fprintf("unused_num is %d!!!\n",unused_num)
go_on=true;
count=0;
if unused_num>1
    for i=1:unused_num-1
        if abs(left_pts(i)-left_pts(i+1))>1
            count=count+1;
        end   
    end
    if ~(left_pts(1)==1&&left_pts(unused_num)==K)&& unused_num>1
        count=count+1;
    end
    if count==unused_num
        go_on=false;
    end
else
    go_on=false;
end