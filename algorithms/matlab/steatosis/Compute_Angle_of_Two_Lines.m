function diff=Compute_Angle_of_Two_Lines(p1,p2,q,b,list_ind)
bpt = @(pt) b(list_ind(pt),:);
pt1=bpt(p1)
pt2=bpt(p2)
pt3=bpt(q)
u=[(pt3(1)-pt1(1)) (pt3(2)-pt1(2)) 0]
v=[(pt3(1)-pt2(1)) (pt3(2)-pt2(2)) 0]

diff = atan2d(norm(cross(u,v)),dot(u,v));
% %diff = atan2d(norm(cross(u,v)),dot(u,v));
% %disp(diff)
% diff = (atan((pt3(2)-pt1(2))/(pt3(1)-pt1(1))) - atan((pt3(2)-pt2(2))/(pt3(1)-pt2(1))) )* 180/pi;


