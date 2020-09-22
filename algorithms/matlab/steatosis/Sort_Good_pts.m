function [P,Q,QUAL]=Sort_Good_pts(good_conn_pts_p,good_conn_pts_q,good_qual,cann_pts)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Sort_Good_pts function sorts the point pairs according to the value of 
% quality in descending order
% Params:
%   good_conn_pts_p,good_conn_pts_q record the to be connected point pairs 
%   good_qual records the quality of point pairs
%   cann_pts is the candidate points
% Return:
%   P,Q are the updated point pairs
%   QUAL is the ellipse fitting quality
%   =======================================================================================
%   Copyright (C) 2018  Xiaoyuan Guo
%   Email: xiaoyuan.guo@emory.edu
%   =======================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
P=[];
Q=[];
QUAL=[];
max=0;
ind_p=0;
ind_q=0;
inx=0;
L=length(good_qual);
count=0;
for i=1:L
    p_next=Find_Next(good_conn_pts_p(i),cann_pts);
    p_before=Find_Before(good_conn_pts_p(i),cann_pts);
    if good_conn_pts_q(i)==p_next||good_conn_pts_q(i)==p_before
        count=count+1;
    end
end

for j=1:count
    for i=1:L
        p_next=Find_Next(good_conn_pts_p(i),cann_pts);
        p_before=Find_Before(good_conn_pts_p(i),cann_pts);
        if good_conn_pts_q(i)==p_next||good_conn_pts_q(i)==p_before
            if good_qual(i)>max
                max=good_qual(i);
                ind_p=good_conn_pts_p(i);
                ind_q=good_conn_pts_q(i);
                inx=i;
            end
        end 
    end
    P(j)=ind_p;
    Q(j)=ind_q;
    QUAL(j)=max;
    max=0;
    good_conn_pts_p(inx)=0;
    good_conn_pts_q(inx)=0;
    good_qual(inx)=0;
end
for j=count+1:L
    for i=1:L
        if good_qual(i)>max
            max=good_qual(i);
            ind_p=good_conn_pts_p(i);
            ind_q=good_conn_pts_q(i);
            inx=i;
         end
    end
    P(j)=ind_p;
    Q(j)=ind_q;
    QUAL(j)=max;
    max=0;
    good_conn_pts_p(inx)=0;
    good_conn_pts_q(inx)=0;
    good_qual(inx)=0;
end


