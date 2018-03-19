function [adj_qual_mat,new_adj_qual_mat,adj_nexts_mat]=adj_Qual(list_ind,b,QUALTHRESH,cann_pts,line_num)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% adj_Qual computes the ellipse fitting quality of adjacent point pairs
% Params:
%   p,q are two points
%   Connected_Pts is the connected point sets
%   num_Candi_sets is the num of sub-candidate sets
% Return:
%   ret is the indicator 
%   where is the corresponding sub-candidate set index
%   =======================================================================================
%   Copyright (C) 2018  Xiaoyuan Guo
%   Email: xiaoyuan.guo@emory.edu
%   =======================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global QUALTHRESH;
bpt = @(pt) b(list_ind(pt),:);
bpts = @(pt1, pt2) b(list_ind(pt1):list_ind(pt2),:);
n=length(cann_pts);
N=length(list_ind);
%adj_qual_mat(n,1):right next;adj_qual_mat(n,2):left next; 
%adj_qual_mat(n,3):right next's next;adj_qual_mat(n,4):left left next;
adj_qual_mat=zeros(n,4);
adj_nexts_mat=zeros(n,5);

split_pts=[];
if line_num~=0
    split_pts=Find_Split_pts(cann_pts,list_ind);
end
    
for i=1:n
    %index the candidate points one by one
    p=cann_pts(i);
    adj_nexts_mat(i,1)=p;
    %find the right next points in candidate points
    q_1=Find_Next(p,cann_pts);
    adj_nexts_mat(i,2)=q_1;
    
    curve=[];  
    if p==N&&q_1==1
        curve = [curve; b(list_ind(end):end,:); b(1:list_ind(1),:)];
    else     
        curve = [curve; bpts(p, q_1)];
    end
    adj_qual_mat(i,1) = measurequality(curve);
    %find the right next's right next points in candidate points
    q_3=Find_Next(q_1,cann_pts);
    adj_nexts_mat(i,4)=q_3;
 
    if q_1==N&&q_3==1
        curve = [curve; b(list_ind(end):end,:); b(1:list_ind(1),:)];
    else 
        curve = [curve; bpts( q_1,q_3)];
    end
    adj_qual_mat(i,3) = measurequality(curve);
    %find the left next points in candidate points
    q_2=Find_Before(p,cann_pts);
    adj_nexts_mat(i,3)=q_2;
   
    curve=[]; 
    if q_2==N&&p==1
       curve = [curve; b(list_ind(end):end,:); b(1:list_ind(1),:)];
    else     
       curve = [curve; bpts(q_2, p)];
    end
    adj_qual_mat(i,2) = measurequality(curve);
    %find the left next's left next points in candidate points
    q_4=Find_Before(q_2,cann_pts);
    adj_nexts_mat(i,5)=q_4;
   
     if q_4==N&&q_2==1
       curve = [curve; b(list_ind(end):end,:); b(1:list_ind(1),:)];
    else     
       curve = [curve; bpts(q_4, q_2)];
     end
    adj_qual_mat(i,4) = measurequality(curve);
end

new_adj_qual_mat=Find_High_Qual_Pts(adj_qual_mat,QUALTHRESH);
