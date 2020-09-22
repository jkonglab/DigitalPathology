function [ret,x1,y1]=Find_Best_Connection_of2Pts2(p,q,Ny,Nx,b,list_ind)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find_Best_Connection_of2Pts2 finds the best connection lines between a
% point pair to be connected according to the Hessian matrix 
% Params:
%   p,q p,q are the points
%   Ny,Nx are the width, height of the image
%   b is the boundary point coordinates
%   list_ind is the index number of candidate points
% Return:
%   ret is the indicator of whether it finds a best connection between the
%   two points or not
%   x1,y1 is the obtained connecting curve coordinates
%   =======================================================================================
%   Copyright (C) 2018  Xiaoyuan Guo
%   Email: xiaoyuan.guo@emory.edu
%   =======================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global gradDX1;
global gradDY1;

ret=true;
x1=[];
y1=[];
%given two points, start point and end point, using weighted gradient to
%find the best connection between two points which makes the value smallest
%similar with Dijkstra algorithm

bpt = @(pt) b(list_ind(pt),:);
pt_start=bpt(p);
pt_end=bpt(q);
x_start=pt_start(:,1);
y_start=pt_start(:,2);
x_end=pt_end(:,1);
y_end=pt_end(:,2);
%define the main direction u, to find good candidates that go to end point
u=[x_end-x_start y_end-y_start 0];

if abs(x_end-x_start)<=6&&abs(y_end-y_start)<=6
    plot([y_start,y_end],[x_start,x_end], 'c', 'LineWidth', 2);
    return
end
%compute image gradient and the gradient of image gradient
% [gradDX,gradDY] = gradient(D,0.2,0.2);
[gradDXX,gradDXY]=gradient(gradDX1,0.2,0.2);
[gradDYX,gradDYY]=gradient(gradDY1,0.2,0.2);
Good_Pts=[];
num=1;
Good_Pts(1,1)=x_start;
Good_Pts(1,2)=y_start;
% Make a logical image with the selected circular region set to 1, the rest
% to zero
[xgrid, ygrid] = meshgrid(1:Nx, 1:Ny);   
angle2 = atan2(y_end-y_start, x_end-x_start);
x_=round(x_start);
y_=round(y_start);
last_x=0;
last_y=0;
time=0;
while ( abs(x_-round(x_end))>1&& abs(y_-round(y_end))>1)&&~(last_x==x_ && last_y==y_)&&(time<80)
    time=time+1;
    X_temp=[];
    Y_temp=[];
    X_temp(1)=x_;
    Y_temp(1)=y_+1;
    X_temp(2)=x_;
    Y_temp(2)=y_-1;
    X_temp(3)=x_+1;
    Y_temp(3)=y_;
    X_temp(4)=x_-1;
    Y_temp(4)=y_;
    X_temp(5)=x_-1;
    Y_temp(5)=y_-1;
    X_temp(6)=x_-1;
    Y_temp(6)=y_+1;
    X_temp(7)=x_+1;
    Y_temp(7)=y_-1;
    X_temp(8)=x_+1;
    Y_temp(8)=y_+1;
    MAX_G1=0;
    MIN_G2=1000;
    MAX_I=0;
    count=0;
    temp_G2=[];
    temp_I=0;

    for i=1:8
        angle=atan2(Y_temp(i)-y_, X_temp(i)-x_)-angle2;
        if Y_temp(i)+1>Ny|| X_temp(i)+1>Nx
            continue
        end
        if angle<=pi/4&&angle>=-pi/4
        	Gradient2=gradDX1(Y_temp(i),X_temp(i))*gradDX1(Y_temp(i),X_temp(i))+gradDY1(Y_temp(i),X_temp(i))*gradDY1(Y_temp(i),X_temp(i)); 
            if Gradient2<MIN_G2&&Gradient2>0 ||(gradDXX(Y_temp(i),X_temp(i))&&gradDYY(Y_temp(i),X_temp(i)))
            	MIN_G2=Gradient2;
                count=count+1;
                temp_G2(count)=i;
                MAX_I=i;
            end
        end
    end
    if count>0
        for i=1:count
            Gradient1=gradDXX(Y_temp(temp_G2(i)),X_temp(temp_G2(i)))*gradDXX(Y_temp(temp_G2(i)),X_temp(temp_G2(i)))+gradDXY(Y_temp(temp_G2(i)),X_temp(temp_G2(i)))*gradDXY(Y_temp(temp_G2(i)),X_temp(temp_G2(i)))+gradDYX(Y_temp(temp_G2(i)),X_temp(temp_G2(i)))*gradDYX(Y_temp(temp_G2(i)),X_temp(temp_G2(i)))+gradDYY(Y_temp(temp_G2(i)),X_temp(temp_G2(i)))*gradDYY(Y_temp(temp_G2(i)),X_temp(temp_G2(i)));
            if (gradDXX(Y_temp(temp_G2(i)),X_temp(temp_G2(i)))&&gradDYY(Y_temp(temp_G2(i)),X_temp(temp_G2(i))))
                MAX_G1=Gradient1;
                MAX_I=temp_G2(i);
            end
        end
    else
        ret=false;
        return
    end

    if MAX_I==0
        ret=false;
        return
    else
        num=num+1;
        Good_Pts(num,1)=X_temp(MAX_I);
        Good_Pts(num,2)=Y_temp(MAX_I);
        last_x=x_;
        last_y=y_;
        x_=X_temp(MAX_I);
        y_=Y_temp(MAX_I);
    end
end

num=num+1;
Good_Pts(num,1)=x_end;
Good_Pts(num,2)=y_end;
p = polyfit(Good_Pts(:,1),Good_Pts(:,2),3);
x1 = Good_Pts(:,1);
y1 = polyval(p,x1);
l1=length(x1);
if x1(l1)~=x_end||y1(l1)~=y_end
	x1(l1+1)=x_end;
	y1(l1+1)=y_end;
end
plot(y1(:),x1(:), 'y', 'LineWidth', 2);

