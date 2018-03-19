function ret=Is_good_pts(p,q,curvature,list_ind,b,Gmag, Gdir)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Is_good_pts(p,q,curvature,list_ind,b,Gmag, Gdir) finds close
% nonadjacent point pairs with radius r_2
% Params:
%   p,q are the index of the evaluated point pairs 
%   curvature is the curvature value of candidate points
%   list_ind is the index number of candidate points
%   b is the clumped nuclei boundary point coordinates
%   Gmag is the image intensity
%   Gdir is the gradient direction
% Return:
%   ret indicates whether the point pair (p,q) is close nonadjacent or not
%
%   =======================================================================================
%   Copyright (C) 2018  Xiaoyuan Guo
%   Email: xiaoyuan.guo@emory.edu
%   =======================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    global Val_Nonclose;
    % give the high curvature points more potential
    bpt = @(pt) b(list_ind(pt),:);
    ret=false;
    a=bpt(p);
    b=bpt(q);
    xa=ceil(a(1));
    ya=ceil(a(2));
    xb=ceil(b(1));
    yb=ceil(b(2));
    ma=Gmag(xa,ya);
    da=Gdir(xa,ya);
    mb=Gmag(xb,yb);
    db=Gdir(xb,yb);
    u=[(a(1)-b(1)) (a(2)-b(2)) 0];
    va=[0 -1 0 ];
    diff = atan2d(norm(cross(u,va)),dot(u,va));      
    ab_distance=abs(xa-xb)+abs(ya-yb);
    sq_distance=(xa-xb)*(xa-xb)+(ya-yb)*(ya-yb);
    curv_a=curvature(p);
    curv_b=curvature(q);
    sum_curv=-(curv_a+curv_b);
    ang=abs(da-db);
    %val=(10*ang)/[0.3*(sqrt(sq_distance)+0.5*ab_distance)+100*(ma+mb)+100*sum_curv]
    %val=(100*ang)/((sqrt(sq_distance)+10*ab_distance)+100*sum_curv)
    val=(150*ang)/(1.5*sqrt(sq_distance)+0.5*sum_curv);
    if val>Val_Nonclose
        ret=true;
    end
      