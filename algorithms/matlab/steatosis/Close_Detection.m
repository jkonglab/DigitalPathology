function close_Matrix= Close_Detection(list_ind,b)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Close_Detection computes the euclidean distance of each point pair
% Params:
%   list_ind is the index number of candidate points
%   b is the clumped nuclei boundary point coordinates
% Return:
%   close_Matrix is the matrix that stores the euclidean distance
%
%   =======================================================================================
%   Copyright (C) 2018  Xiaoyuan Guo
%   Email: xiaoyuan.guo@emory.edu
%   =======================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%to compute the L2 distance of those candidate pts
N=length(list_ind);
a=1000;
close_Matrix=a(ones(N, N));
 for i = 1:N
     for j = i+1:N 
         distance=sqrt( (b(list_ind(i),2)-b(list_ind(j),2)).^2 + (b(list_ind(i),1)-b(list_ind(j),1)).^2);
         close_Matrix(i,j)=distance;
     end
 end
