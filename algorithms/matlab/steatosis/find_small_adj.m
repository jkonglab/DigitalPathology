function my_conn=find_small_adj(adj,x)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% find_small_adj function finds the adjacent point of x that has smaller index
% value than x
% Params:
%   adj is the adjacent point matrix
%   x is a point
% Return:
%   my_conn is the result point
%   =======================================================================================
%   Copyright (C) 2018  Xiaoyuan Guo
%   Email: xiaoyuan.guo@emory.edu
%   =======================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

my_conn=0;
for i = 1:x
   if (adj(x,i)==1)&&(i~=x)
       my_conn=i;
   end
end
