function [In,q,num]=A_Pt_In_Connected(p,Connected_Pts)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A_Pt_In_Connected is used to determine whether a point in connected
% points or not
% Params:
%   p is the index of a point
%   Connected_Pts is the connected point sets
% Return:
%   In is the indicator 
%   q is the corresponding point index 
%   =======================================================================================
%   Copyright (C) 2018  Xiaoyuan Guo
%   Email: xiaoyuan.guo@emory.edu
%   =======================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

k=length(Connected_Pts(:,1));
In=false;
num=0;
q=0;
for i=1:k
  if Connected_Pts(i,1)==p
      In=true;
      q=Connected_Pts(i,2);
      num=i;
  elseif Connected_Pts(i,2)==p
      In=true;
      q=Connected_Pts(i,1);
      num=i;
  end
end
if num>0
    return
end