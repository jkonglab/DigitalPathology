function [I,conn_lines,Connected_Pts,line_num]=Connect_pts(I,p,q,b,list_ind,conn_lines,Connected_Pts,line_num)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Connect_pts function connects a point pair 
% Params:
%   p,q are the point pair that needs to be connected 
%   b is the clumped nuclei boundary point coordinates
%   list_ind is the index number of candidate points
%   conn_lines records the connected lines
%   Connected_Pts records the connected point pairs information
%   line_num is the number of connected point pairs
%   Nx,Ny are the image width, height
%   gradDX,gradDY are the image gradient value along the x-axis and y-axis
%   k is the curvature value of clumped nuclei boundary points
%   curve is the connecting points coordinates 
%   close_nonadj_pts stores those close nonadjacent point pairs
%   count_nonadj is the number of those close nonadjacent point pairs
% Return:
%   conn_lines,Connected_Pts,line_num record the update information
%   =======================================================================================
%   Copyright (C) 2018  Xiaoyuan Guo
%   Email: xiaoyuan.guo@emory.edu
%   =======================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

bpt = @(pt) b(list_ind(pt),:);
curve=[];
if p==q
    return;
end
[ret,~]=In_Connected_Pts(p,q,Connected_Pts);
if ret
    return
end
[p,q]=Swap_pq(p,q);
ret_iter=Intercept_With_Other_Lines(p,q,conn_lines,line_num,b,list_ind);
if ret_iter
    return
end
%p and q are not adjacent
x1 = bpt(p);
x2 = bpt(q);  

delta_X=abs(x1(2)-x2(2));
delta_Y=abs(x1(1)-x2(1));


if  delta_Y>delta_X 

xs = linspace(x1(1),x2(1), 2*ceil(abs(x1(1)-x2(1))))';

ys = interp1([x1(1) x2(1)], [x1(2) x2(2)],xs); 

elseif delta_Y<=delta_X

ys = linspace(x1(2),x2(2), 2*ceil(abs(x1(2)-x2(2))))';

xs = interp1([x1(2) x2(2)], [x1(1) x2(1)],ys); 

else

    return

end

curve = [curve; [xs, ys]];
result=eval_conn(p,q,b,list_ind,curve);
if ~result
    return
end
fprintf('Connecting');
fprintf('%d to %d: ', p, q);
line_num=line_num+1; 
Connected_Pts(line_num,1)=p;
Connected_Pts(line_num,2)=q;
% add connection
fprintf("This is  %d  line \n",line_num);
conn_lines{1,line_num}=curve;
 
[m,~]=size(curve);

if m==2
    curve = resample(curve,6,2);
elseif m==1
    curve= [curve(1,1)-1,curve(1,2)-1;curve(1,1)-1,curve(1,2);curve(1,1),curve(1,2)-1;curve;curve(1,1)+1,curve(1,2);curve(1,1),curve(1,2)+1;curve(1,1)+1,curve(1,2)+1]
end
[m,~]=size(curve);

if m>0

for i=1:m
    x=curve(i,2);
    y=curve(i,1); 
    x1=ceil(x);
    y1=ceil(y);
    x2=floor(x);
    y2=floor(y);
    x3=floor(x)-1;
    y3=floor(y)-1;
    x4=ceil(x)+1;
    y4=ceil(y)+1; 
    I(y1,x1)=I(y1,x1)& 0;
    I(y2,x1)=I(y2,x1)& 0;
    I(y1,x2)=I(y1,x2)& 0;
    I(y2,x2)=I(y2,x2)& 0;        
end

else
    return
end 