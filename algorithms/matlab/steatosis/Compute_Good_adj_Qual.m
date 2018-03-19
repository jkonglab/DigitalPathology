function [good_conn_pts_p,good_conn_pts_q,count]=Compute_Good_adj_Qual(list_ind,b,cann_pts,conn_lines,Connected_Pts)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Connect_pts function connects a point pair 
% Params:
%   p,q are the point pair that needs to be connected 
%   b is the clumped nuclei boundary point coordinates
%   list_ind is the index number of candidate points
%   conn_lines records the connected lines
%   Connected_Pts records the connected point pairs information
%   line_num is the number of connected point pairs
%   Nx,Ny are the image width, height
%   gradDX,gradDY are the image gradient value along the x-axis and y-axis
%   k is the curvature value of clumped nuclei boundary points
%   curve is the connecting points coordinates 
%   close_nonadj_pts stores those close nonadjacent point pairs
%   count_nonadj is the number of those close nonadjacent point pairs
% Return:
%   conn_lines,Connected_Pts,line_num record the update information
%   =======================================================================================
%   Copyright (C) 2018  Xiaoyuan Guo
%   Email: xiaoyuan.guo@emory.edu
%   =======================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

bpt = @(pt) b(list_ind(pt),:);
bpts = @(pt1, pt2) b(list_ind(pt1):list_ind(pt2),:);
n=length(cann_pts);
N=length(list_ind);
% global QUALTHRESH
count=0;
good_conn_pts_p=[];
good_conn_pts_q=[];

%adj_qual_mat(n,1):right next;adj_qual_mat(n,2):left next; 
%adj_qual_mat(n,3):right next's next;adj_qual_mat(n,4):left left next;
adj_qual_mat=zeros(n,5);
%(p,q,qual_pq,qq,qual_pqq)
if n==4
    p1=cann_pts(1);
    p2=cann_pts(2);
    p3=cann_pts(3);
    p4=cann_pts(4);
    [ret1,num1]=In_Connected_Pts(p1,p2,Connected_Pts);
    [ret2,num2]=In_Connected_Pts(p3,p4,Connected_Pts);
    [ret3,num3]=In_Connected_Pts(p1,p4,Connected_Pts);
    [ret4,num4]=In_Connected_Pts(p2,p3,Connected_Pts);
    if (ret1&&ret2)||(ret3&&ret4)
        return
    end
    
end
for i=1:n
    %index the candidate points one by one
    p=cann_pts(i);
    q=Find_Next(p,cann_pts);
    [ret,num]=In_Connected_Pts(p,q,Connected_Pts); 
    qq=Find_Next(q,cann_pts);
    adj_qual_mat(i,1)=p;
    adj_qual_mat(i,2)=q;
    adj_qual_mat(i,4)=qq;
    
    curve1=Compute_curve_pts(p,q,Connected_Pts,cann_pts,b,list_ind,conn_lines);
    curve2=Compute_curve_pts(q,qq,Connected_Pts,cann_pts,b,list_ind,conn_lines);
    curve2=vertcat(curve2,curve1);

    if ret%if connected e.g. 3---8, here I use 2-3------8-9 to add more possiblity
        p1=Find_Before(p,cann_pts);
        q1=qq;
        if p1==q1
            adj_qual_mat(i,3) = 0;
        else
            curve3=[];
            curve_temp=Compute_curve_pts(p1,p,Connected_Pts,cann_pts,b,list_ind,conn_lines);
            curve3=[curve3;curve_temp];
            curve_temp=Compute_curve_pts(p,q,Connected_Pts,cann_pts,b,list_ind,conn_lines);
            curve3=[curve3;curve_temp];
            curve_temp=Compute_curve_pts(q,q1,Connected_Pts,cann_pts,b,list_ind,conn_lines);
            curve3=[curve3;curve_temp];
            adj_qual_mat(i,3)=measurequality(curve3);
        end
    else
        if length(curve1(:,1))<2
            adj_qual_mat(i,3)=0;
        else
            adj_qual_mat(i,3) = measurequality(curve1);
        end
        
    end
    if qq==p
        adj_qual_mat(i,5) = 0;
    else
        if length(curve2(:,1))<2
            adj_qual_mat(i,5)=0;
        else
            adj_qual_mat(i,5) = measurequality(curve2);
        end
    end
    
end

%Find good connected points
[good_conn_pts_p,good_conn_pts_q,count]=Good_Conn_Pts(list_ind,b,adj_qual_mat,Connected_Pts,cann_pts);


