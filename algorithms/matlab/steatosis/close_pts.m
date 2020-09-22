function  [close_adj_pts,close_nonadj_pts,count_nonadj,count_adj,nonadj_close_distance]=close_pts(close_Matrix,curvature,list_ind,b,Gmag, Gdir)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% close_pts(close_Matrix,curvature,list_ind,b,Gmag, Gdir) finds close
% adjacent point pairs and close nonadjacent point pairs
% Params:
%   close_Matrix is the distance matrix  
%   curvature is the curvature value of candidate points
%   list_ind is the index number of candidate points
%   b is the clumped nuclei boundary point coordinates
%   Gmag is the image intensity
%   Gdir is the gradient direction
% Return:
%   close_adj_pts stores the obtained close adjacent point pairs
%   close_nonadj_pts stores the obtained close nonadjacent point pairs
%   count_nonadj is the number of the obtained close nonadjacent point pairs
%   count_adj is the number of obtained close adjacent point pairs
%   nonadj_close_distance is the Euclidean distance of each close
%   nonadjacent point pairs
%
%   =======================================================================================
%   Copyright (C) 2018  Xiaoyuan Guo
%   Email: xiaoyuan.guo@emory.edu
%   =======================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global Min_Distance;
global Max_Distance;

k=length(close_Matrix(:,1));
close_adj_pts = zeros(k,2);
close_nonadj_pts = zeros(k,2);
count_adj=0;
count_nonadj=0;
nonadj_close_distance=[];

for i=1:k-1
	for j=i+1:k
        
    	if close_Matrix(i,j)<Min_Distance
        	if abs(i-j)==1||(i==1&&j==k)                
            	count_adj=count_adj+1;
            	close_adj_pts(count_adj,1)=i;
            	close_adj_pts(count_adj,2)=j;
            else
            	count_nonadj=count_nonadj+1;
            	close_nonadj_pts(count_nonadj,1)=i;
            	close_nonadj_pts(count_nonadj,2)=j;
            	nonadj_close_distance(count_nonadj)=close_Matrix(i,j);
            end
        elseif (close_Matrix(i,j)<Max_Distance) && (close_Matrix(i,j)>=Min_Distance) &&(length(list_ind)>=6)
        	if abs(i-j)==1||(i==1&&j==k)
            	continue;
            end
            ret=Is_good_pts(i,j,curvature,list_ind,b,Gmag, Gdir);
            if ret
            	count_nonadj=count_nonadj+1;
            	close_nonadj_pts(count_nonadj,1)=i;
            	close_nonadj_pts(count_nonadj,2)=j;
            	nonadj_close_distance(count_nonadj)=close_Matrix(i,j);           
            end
         end
     end
 end
