function [Good_Curv,Good_Pt,good]=Find_Curv_Candidate_Points(k,b)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find_Curv_Candidate_Points(k,b) finds high curvature candidate points via
% voting
% Params:
%   k is the curvature value of clumped nuclei points 
%   b is the boundary point coordinates
% Return:
%   Good_Curv is the curvature value of obtained high curvature points
%   Good_Pt is the point coordinates of obtained high curvature points
%   good is the number of obtained high curvature points
%
%   =======================================================================================
%   Copyright (C) 2018  Xiaoyuan Guo
%   Email: xiaoyuan.guo@emory.edu
%   =======================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

L=length(k);
curv_TF = k < 0;
arclens = arrayfun(@(x1,x2,y1,y2) sqrt((x1-x2)^2+(y1-y2)^2), b(:,1), b([end 1:end-1],1),b(:,2), b([end 1:end-1],2));
bpt1 = @(pt) b(pt,1);
bpt2 = @(pt) b(pt,2);
bpts = @(pt1, pt2) b(list_ind(pt1):list_ind(pt2),:);    
val=0;
len=0;
count=0;
num=0;
curvs=[];
curv=0;
Threshold=0.55;%0.55
pts=[];
ds=[];
Good_Curv=[];
Good_Pt=[];
good=0;
last_pt=0;
for i=1:L
    if curv_TF(i)
        c=k(i);
        curv=curv+c;
        num=num+1;       
        pts(num)=i;
        curvs(num)=c;
        if i+1<=L&&curv_TF(i+1)
            d = sqrt((bpt1(i)-bpt1(i+1))^2+(bpt2(i)-bpt2(i+1))^2);
            ds(num)=d;
            len=len+d;
            val=abs(d*c)+val;
  
        end

    elseif i>1&&curv_TF(i-1)&&~curv_TF(i)
        count=count+1;
          if val>Threshold
%         if val>Threshold && (num>=10||len>=15)
           s=0;
           for j=1:num-1
               s=s+abs(ds(j)*curvs(j)*(j/(num-1)));
           end
           s_bar=s/(1.0*val);
           t=round(s_bar*num);
           good=good+1;
           Good_Curv(good)=curvs(t);
           Good_Pt(good)=pts(t);
           last_pt=pts(t);
        end
        val=0;
        num=0;
        curv=0;
        len=0;
    end
end
% for i=1:good
%      plot(b(Good_Pt(i),2),b(Good_Pt(i),1),'yo', 'MarkerSize', 10);
% end
