function ret=Intercept_With_Other_Lines(p,q,conn_lines,line_num,b,list_ind)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Intercept_With_Other_Lines function detects whether there are any
% intersected lines
% Params:
%   p,q are the index of the evaluated point pairs 
%   conn_lines records the connected lines
%   line_num is the number of connected point pairs
%   b is the clumped nuclei boundary point coordinates
%   list_ind is the index number of candidate points
% Return:
%   ret is the indicator
%
%   =======================================================================================
%   Copyright (C) 2018  Xiaoyuan Guo
%   Email: xiaoyuan.guo@emory.edu
%   =======================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%this function is to judge wether the coming line intercepts with other
%connected lines or not
bpt = @(pt) b(list_ind(pt),:);
bpts = @(pt1, pt2) b(list_ind(pt1):list_ind(pt2),:);
line1=[];
line2=[];
l1=0;
l2=0;
ret=false;
%generate Line1
x1 = bpt(p);
x2 = bpt(q);                                 
xs = linspace(x1(1),x2(1), round(abs(x1(1)-x2(1))))';
ys = interp1([x1(1) x2(1)], [x1(2) x2(2)],xs); 
line1 = [line1; [xs, ys]];
l1=length(line1(:,1));

if l1<2
    line1=[x1;x2];
    l1=2;
end
%Go through every connected line
for i=1:line_num   
    line2=conn_lines{1,i};
    l2=length(line2(:,1));
    if l2<2
        return
    end
    out = lineSegmentIntersect([line1(1,:),line1(l1,:)],[line2(1,:),line2(l2,:)]);
    if sum(out.intAdjacencyMatrix)      
        if (out.intMatrixX==line1(1,1)&&out.intMatrixY==line1(1,2))||(out.intMatrixX==line1(l1,1)&&out.intMatrixY==line1(l1,2))||...
            (out.intMatrixX==line2(1,1)&&out.intMatrixY==line2(1,2))||(out.intMatrixX==line2(l2,1)&&out.intMatrixY==line2(l2,2))            
            % this case is 2-6,2-7, here I should check their angle, if too
            % narrow, give up
            pt1=zeros(1,2);
            pt2=zeros(1,2);
            pt3=zeros(1,2);
            if line1(1,:)==line2(1,:)
                pt3=line1(1,:);
                pt1=line1(l1,:);
                pt2=line2(l2,:);
            elseif line1(l1,:)==line2(1,:)
                pt3=line1(l1,:);
                pt1=line1(1,:);
                pt2=line2(l2,:);
            elseif line1(1,:)==line2(l2,:)
                pt3=line1(1,:);
                pt1=line1(l1,:);
                pt2=line2(1,:);
            elseif line1(l1,:)==line2(l2,:)
                pt3=line1(l1,:);
                pt1=line1(1,:);
                pt2=line2(1,:);
            end
            u=[(pt3(1)-pt1(1)) (pt3(2)-pt1(2)) 0];
            v=[(pt3(1)-pt2(1)) (pt3(2)-pt2(2)) 0];
            diff = atan2d(norm(cross(u,v)),dot(u,v));
            
            if abs(diff)<62
                ret=true;
            else
                continue;
            end                       
        else
            ret=true;
        end
    else
        pt1=zeros(1,2);
        pt2=zeros(1,2);
        pt3=zeros(1,2);
        if abs(line1(1,1)-line2(1,1))<3.5527e-4&&abs(line1(1,2)-line2(1,2))<3.5527e-4
            pt3(1,1)=line1(1,1);
            pt3(1,2)=line1(1,2);
            pt1(1,1)=line1(l1,1);
            pt1(1,2)=line1(l1,2);
            pt2(1,1)=line2(l2,1);
            pt2(1,2)=line2(l2,2);
        elseif abs(line1(l1,1)-line2(1,1))<3.5527e-4&&abs(line1(l1,2)-line2(1,2))<3.5527e-4
            pt3=line1(l1,:);
            pt1=line1(1,:);
            pt2=line2(l2,:);
        elseif abs(line1(1,1)-line2(l2,1))<3.5527e-4&&abs(line1(1,2)-line2(l2,2))<3.5527e-4
            pt3=line1(1,:);
            pt1=line1(l1,:);
            pt2=line2(1,:);
        elseif abs(line1(l1,1)-line2(l2,1))<3.5527e-4&&abs(line1(l1,2)-line2(l2,2))<3.5527e-4
            pt3=line1(l1,:);
            pt1=line1(1,:);
            pt2=line2(1,:);
        else
            continue;
        end
            u=[(pt3(1)-pt1(1)) (pt3(2)-pt1(2)) 0];
            v=[(pt3(1)-pt2(1)) (pt3(2)-pt2(2)) 0];
            diff = atan2d(norm(cross(u,v)),dot(u,v));
            if abs(diff)<62
                ret=true;
            else
                continue;
            end
    end
end