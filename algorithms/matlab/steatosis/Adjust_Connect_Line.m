function line=Adjust_Connect_Line(p,q,curve,Ny,Nx,b,list_ind,k,gradDX,gradDY)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Adjust_Connect_Line function adjusts the connecting lines based on the
% image gradient
% Params:
%   p,q are two points to be connected
%   curve stores the coordinates of pre-generated connecting line points
%   Ny,Nx are the widht, height of the original image
%   b is the boundary points 
%   list_ind is the index of high curvature points 
%   k is the curvature value of candidate points
%   gradDX,gradDY is the image gradient value of the original image along
%   X-axis and Y-axis
% Return:
%   line is the updated connected points
%   =======================================================================================
%   Copyright (C) 2018  Xiaoyuan Guo
%   Email: xiaoyuan.guo@emory.edu
%   =======================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

particles = b(list_ind,:);
masses = abs(k(list_ind));
bpt = @(pt) b(list_ind(pt),:);
line=[];
global gradDX1;
global gradDY1;

% inverse-square affinity
G = 1000;
F = @(m,r) (G.*m)./r.^2;
% gravitational field
L=length(curve);
if L==2
	plot([curve(1,2),curve(2,2)],[curve(1,1),curve(2,1)], 'c', 'LineWidth', 2); 
    return
end
[ret,line]=Find_Best_Connection_of2Pts2(p,q,Ny,Nx,b,list_ind);
if ret
    return
end
a=curve(1,1);
b=curve(1,2);
x=0;
y=0;
line=[line;a,b;];
ia=ceil(a);
ib=ceil(b);
if isnan(ia)||isnan(ib)||isnan(gradDX(ia,ib))||isnan(gradDY(ia,ib))
	s1=0;
	t1=0;
else
	s1=gradDX(ia,ib);
	t1=gradDY(ia,ib);
end
for i=2:L-1
    a=curve(i,1);
    b=curve(i,2);
    ia=ceil(a);
    ib=ceil(b);
    if isnan(ia)||isnan(ib)||isnan(gradDX(ia,ib))||isnan(gradDY(ia,ib))
        s=0;
        t=0;
    else
        s=gradDX(ia,ib);
        t=gradDY(ia,ib);
    end
    vx=a-ia;
    vy=b-ib;
    l=(vx*vx+vy*vy);
    delta_s=s-s1;
    delta_t=t-t1;
    if abs(delta_s)>0.1
        x=a;
    else     
        if delta_s<0
            x=a+10*delta_s+s;
        else 
            x=a-10*delta_s+s;
        end
    end
    
    if abs(delta_t)>0.1
        y=b;
    else
        if delta_t<0
            y=b+10*delta_t+t;
        else
            y=b-10*delta_t+t;
        end
    end

    line=[line;x,y;];
    plot([line(i-1,2),y],[line(i-1,1),x], 'c', 'LineWidth', 2);
    ix=ceil(x);
    iy=ceil(y);
    if isnan(ix)||isnan(iy)||isnan(gradDX(ix,iy))||isnan(gradDY(ix,iy))
        s1=0;
        t1=0;
    else
        s1=gradDX(ix,iy);
        t1=gradDY(ix,iy);
    end
  
end
a=curve(L,1);
b=curve(L,2);
line=[line;a,b;];

if x&&y
	plot([y,line(L,2)],[x,line(L,1)], 'c', 'LineWidth', 2);  
end  
if line(:,1)==2
	plot([line(1,2),line(2,2)],[line(1,1),line(2,1)], 'c', 'LineWidth', 2); 
end

