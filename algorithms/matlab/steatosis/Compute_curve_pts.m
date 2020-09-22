function curve=Compute_curve_pts(p,q,Connected_Pts,cann_pts,b,list_ind,conn_lines)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute_curve_pts function obtains the connecting lines of a point pair,
% if the point pair is connected, return the connecting line points; if
% not, return the boundary points of the point pair
% Params:
%   p,q are two points to be connected
%   Connected_Pts records the connected points
%   cann_pts is the candidate points
%   b is the boundary points 
%   list_ind is the index of high curvature points 
%   conn_lines stores the connected line information
% Return:
%   curve is the connected line of the point pair
%   =======================================================================================
%   Copyright (C) 2018  Xiaoyuan Guo
%   Email: xiaoyuan.guo@emory.edu
%   =======================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

bpt = @(pt) b(list_ind(pt),:);
bpts = @(pt1, pt2) b(list_ind(pt1):list_ind(pt2),:);
n=length(cann_pts);
N=length(list_ind);    
In=false;
num=0;
[In,num]=In_Connected_Pts(p,q,Connected_Pts);
curve=[];  
if p==N&&q==1
	curve = [curve; b(list_ind(end):end,:); b(1:list_ind(1),:)];
elseif In==true&&num~=0
	curve = [curve; conn_lines{1,num}];
else
	curve = [curve; bpts(p, q)];
end