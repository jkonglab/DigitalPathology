function my_conn=find_big_adj(adj,x)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% find_big_adj function finds the adjacent point of x that has larger index
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
for i = x:length(adj)
   if (adj(x,i)==1)&&(i~=x)
       my_conn=i;
   end
end
