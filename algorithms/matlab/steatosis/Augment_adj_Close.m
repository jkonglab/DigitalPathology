function  [I,close_adj_pts,count_adj,conn_lines,Connected_Pts,line_num]=Augment_adj_Close(I,close_adj_pts,count_adj,list_ind,k,b, Gdir,conn_lines,Connected_Pts,line_num,Nx,Ny,gradDX,gradDY,close_nonadj_pts,count_nonadj)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Augment_adj_Close function identifies whether those detected close
% adjacent points are really close by evaluating the walking energy
% Params:
%   close_adj_pts are those close adjacent point pairs
%   count_adj is the number of the detected close adjacent point pairs
%   list_ind is the index number of candidate points
%   k is the curvature value of clumped nuclei boundary points
%   b is the clumped nuclei boundary point coordinates
%   Gdir is the gradient direction
%   conn_lines records the connected lines information
%   Connected_Pts records the connected point pairs information
%   line_num is the number of connected lines
%   Nx,Ny are the image width, height 
%   gradDX,gradDY are the image gradient value along the x-axis and y-axis
%   close_nonadj_pts stores those close nonadjacent point pairs
%   count_nonadj is the number of those close nonadjacent point pairs
% Return:
%   ret indicates whether the point pair (p,q) is close nonadjacent or not
%
%   =======================================================================================
%   Copyright (C) 2018  Xiaoyuan Guo
%   Email: xiaoyuan.guo@emory.edu
%   =======================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% high curvature point pairs have less potential
% for case 8,9 that are very close but their directions are very different
Sum_adj=[];
count=0;
remove=[];
inx=0;
global QUALTHRESH;
bpt = @(pt) b(list_ind(pt),:);
bpts = @(pt1, pt2) b(list_ind(pt1):list_ind(pt2),:);
for i=1:count_adj
    p=close_adj_pts(i,1);
    q=close_adj_pts(i,2);
    m=bpt(p);
    n=bpt(q);
    xm=ceil(m(1));
    ym=ceil(m(2));
    xn=ceil(n(1));
    yn=ceil(n(2));
    dm=Gdir(xm,ym);
    dn=Gdir(xn,yn);
    theta=abs(dm-dn);
    count=count+1;
    B=b(list_ind(p):list_ind(q),:);
    K=k(list_ind(p):list_ind(q));
    sum=0;     
    for j=1:length(B)-1
    	sum=sum+abs(K(j))*sqrt((B(j,1)-B(j+1,1))*(B(j,1)-B(j+1,1))+(B(j,2)-B(j+1,2))*(B(j,2)-B(j+1,2)));
    end
    %when the length is long enough or the angle is small enough, remove
    %the point that has smaller curvature value 
    if sum>3|| (sum<2.0&&abs(theta)<90&&abs(theta)>10)       
       inx=inx+1;
       remove(inx)=i;
       curve=[];
       if (p==1&&q==length(list_ind))||(q==1&&p==length(list_ind))
           curve=[b(list_ind(end):end,:); b(1:list_ind(1),:)];
       else
           curve=[curve; bpts(p,q)];
       end
       
       qual = measurequality(curve);
       if qual>QUALTHRESH
%            disp("ok")
           [I,conn_lines,Connected_Pts,line_num]=Connect_pts(I,p,q,b,list_ind,conn_lines,Connected_Pts,line_num);
       end
       
    end
    Sum_adj(count)=sum;
end
 if inx
    for t=1:length(remove)
        indx=remove(t);
        p=close_adj_pts(indx,1);
        q=close_adj_pts(indx,2);
%         fprintf("Here I want to keep pts %d,%d,index is %d\n",p,q,indx)
        close_adj_pts(indx,1)=0;
        close_adj_pts(indx,2)=0;
    end
    if length(remove)
        for t=1:count_adj
            if ~close_adj_pts(t,1)&&(~close_adj_pts(t,2))
                for s=t:count_adj-1
                    if close_adj_pts(s,1)&&(close_adj_pts(s,2))
                        close_adj_pts(t,1)=close_adj_pts(s,1);
                        close_adj_pts(t,2)=close_adj_pts(s,2);
                        close_adj_pts(s,1)=0;
                        close_adj_pts(s,2)=0;
                        break;
                    end
                end
                close_adj_pts(s,1)=0;
                close_adj_pts(s,2)=0;
            end
        end
        count_adj=count_adj-length(remove);
    end            
end

if ~length(remove)
    return
end



