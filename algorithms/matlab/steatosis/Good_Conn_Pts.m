function [good_conn_pts_p,good_conn_pts_q,count]=Good_Conn_Pts(list_ind,b,adj_qual_mat,Connected_Pts,cann_pts)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Good_Conn_Pts function detects the point pairs unconnected that have
% high possibility to be connected
% Params:
%   list_ind is the index of high curvature points 
%   b is the boundary points 
%   adj_qual_mat is the ellipse fitting quality of each adjacent point pair
%   Connected_Pts records the connected points
%   cann_pts is the candidate points
% Return:
%   good_conn_pts_p,good_conn_pts_q are the obtained point pairs that need
%   to be connectd
%   count is the number of obtained point pairs
%   =======================================================================================
%   Copyright (C) 2018  Xiaoyuan Guo
%   Email: xiaoyuan.guo@emory.edu
%   =======================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
good_conn_pts_p=[];
good_conn_pts_q=[];
good_qual=[];
count=0;
bpt = @(pt) b(list_ind(pt),:);
K=length(adj_qual_mat(:,1));
global QUALTHRESH;
global QUAL;
global ANGLE;
thre=0.2;
%Consider only two points available,it will construct a loop
if K==2
	if adj_qual_mat(1,3)>adj_qual_mat(2,3)
        [adj_qual_mat(1,3),adj_qual_mat(2,3)]=Swap_pq(adj_qual_mat(1,3),adj_qual_mat(2,3));
    if adj_qual_mat(1,3)<QUALTHRESH&&adj_qual_mat(1,5)<QUALTHRESH
        return;
    elseif adj_qual_mat(1,3)>=QUALTHRESH||adj_qual_mat(1,5)>=QUALTHRESH
    	count=1;
        if adj_qual_mat(1,5)-adj_qual_mat(1,3)>1.0
        	good_conn_pts_p(count)=adj_qual_mat(1,1);
            good_conn_pts_q(count)=adj_qual_mat(1,4);
            good_qual(count)=adj_qual_mat(1,5);
        else
            good_conn_pts_p(count)=adj_qual_mat(1,1);
            good_conn_pts_q(count)=adj_qual_mat(1,2);
            good_qual(count)=adj_qual_mat(1,3);
        end
       
        return;
    end
    end    
elseif K==4
    count=0;
    for j=1:K
        if adj_qual_mat(j,3)>=QUALTHRESH 
            count=count+1;
            good_conn_pts_p(count)=adj_qual_mat(j,1);
            good_conn_pts_q(count)=adj_qual_mat(j,2);
            good_qual(count)=adj_qual_mat(j,3);
        end
    end
    for j=1:K
        if adj_qual_mat(j,5)>=QUAL 
            ind_x=adj_qual_mat(j,1);
            ind_y=adj_qual_mat(j,4);
            tmp_qual=0;
            for tmp_j=1:K
                if adj_qual_mat(tmp_j,1)==ind_y
                   tmp_qual=adj_qual_mat(tmp_j,5);
                end
            end
            if  tmp_qual<QUAL 
                continue;
            else
                count=count+1;
                good_conn_pts_p(count)=adj_qual_mat(j,1);
                good_conn_pts_q(count)=adj_qual_mat(j,4);
                good_qual(count)=adj_qual_mat(j,5) ;
            end
        end
    end
    if count        
        [good_conn_pts_p,good_conn_pts_q,good_qual]=Sort_Good_pts(good_conn_pts_p,good_conn_pts_q,good_qual,cann_pts);
    end
    return
   
end
% consider more points
for i=1:K
    if adj_qual_mat(i,3)>=QUALTHRESH||adj_qual_mat(i,5)>=QUALTHRESH
       count=count+1;
       if (adj_qual_mat(i,5)-adj_qual_mat(i,3)>thre)&& adj_qual_mat(i,3)<QUALTHRESH
               good_conn_pts_p(count)=adj_qual_mat(i,1);
               good_conn_pts_q(count)=adj_qual_mat(i,4);
               good_qual(count)=adj_qual_mat(i,5);
       elseif adj_qual_mat(i,3)>=QUALTHRESH
 
           [ret,~]=In_Connected_Pts(adj_qual_mat(i,1),adj_qual_mat(i,2),Connected_Pts);
           if ret
               if i>1
                   good_conn_pts_p(count)=adj_qual_mat(i-1,1);
                   good_conn_pts_q(count)=adj_qual_mat(i,4);
               elseif i==1
                   good_conn_pts_p(count)=adj_qual_mat(K,1);
                   good_conn_pts_q(count)=adj_qual_mat(i,4);
               end
           else   
                good_conn_pts_p(count)=adj_qual_mat(i,1);
                good_conn_pts_q(count)=adj_qual_mat(i,2);
           end
           good_qual(count)=adj_qual_mat(i,3);
           if adj_qual_mat(i,5)>=QUALTHRESH
               count=count+1;
               good_conn_pts_p(count)=adj_qual_mat(i,1);
               good_conn_pts_q(count)=adj_qual_mat(i,4);
               good_qual(count)=adj_qual_mat(i,5);
           end
       else
           count=count-1;
           continue;
       end
    end
end

%after get good points, cleaning technique should be considered
[good_conn_pts_p,good_conn_pts_q,good_qual]=Sort_Good_pts(good_conn_pts_p,good_conn_pts_q,good_qual,cann_pts);



