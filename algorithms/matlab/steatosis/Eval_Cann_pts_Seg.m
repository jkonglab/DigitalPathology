function ret=Eval_Cann_pts_Seg(cann_pts,b,list_ind,close_nonadj_pts,Connected_Pts,conn_lines,count_nonadj)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Eval_Cann_pts_Seg decides whether the left unconnected points need to be
% connectedb or not
% Params:
%   ret is the indicator
% Return:
%   result is the indicator
%   =======================================================================================
%   Copyright (C) 2018  Xiaoyuan Guo
%   Email: xiaoyuan.guo@emory.edu
%   =======================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
bpt = @(pt) b(list_ind(pt),:);
bpts = @(pt1, pt2) b(list_ind(pt1):list_ind(pt2),:);
L=length(cann_pts);
global avg_area;
len=L;
pts=Find_Split_pts(cann_pts,list_ind,close_nonadj_pts,count_nonadj);
curve=[];
ret=false;
if pts(2,1)
    len=2;
else
    len=1;
end

if L-len<6
    for i=1:L
        if i~=L
            p=cann_pts(i);
            q=cann_pts(i+1);
        else
            p=cann_pts(i);
            q=cann_pts(1);
        end
        [ret,num]=In_Connected_Pts(p,q,Connected_Pts);
        if ret
            curve=vertcat(curve,cell2mat(conn_lines(num)));       
        elseif (p==length(list_ind)&&q==1)||(p==1&&q==length(list_ind))
            curve=vertcat(curve,b(list_ind(end):end,:));
            curve=vertcat(curve,b(1:list_ind(1),:));
        elseif  abs(p-q)==1
            curve= vertcat(curve,bpts(p, q));
        end
    end
    if length(curve)
        ar = polyarea(curve(:,1),curve(:,2));
        if ar<1.5*avg_area
            ret=true;
        else 
            ret=false;
            return
        end

    end
end
