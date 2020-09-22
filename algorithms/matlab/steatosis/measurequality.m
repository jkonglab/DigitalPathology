function qual = measurequality(b)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% measurequality is used to determines the quality of a potential
% connection based on the boundary
% Params:
%   b is the coordinate set of boundary points
% Return:
%   qual is the ellipse fitting quality
%   =======================================================================================
%   Copyright (C) 2018  Xiaoyuan Guo
%   Email: xiaoyuan.guo@emory.edu
%   =======================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

x = b(:,2);
y = b(:,1);
global avg_area;

% plot(x,y, 'LineWidth', 3)
% calculate ellipse fit overlap
% ellipse_t = fit_ellipse(x,y,gca);
% pause(1);
ellipse_t = fit_ellipse(x,y);

if isempty(ellipse_t) || ~isempty(ellipse_t.status)
    overlap = 0;
    area_delta=0;
    x_delta=0;
    y_delta=0;
    perimeter_delta=0;
    qual=0;
    return
else
    xe = ellipse_t.pts(1,:);
    ye = ellipse_t.pts(2,:);
    long_r=ellipse_t.long_axis;
    short_r=ellipse_t.short_axis;
    long_short=1.0*(long_r/short_r);
    [area_delta,x_delta,y_delta,perimeter_delta,geom1,geom2]=Eval_Similarity_Curves(x,y,xe,ye);
    if geom1(1)<0.35*avg_area||geom2(1)<0.35*avg_area
        qual=0;
        return
    end
    m = ceil(max([max(y), max(ye)]));
    n = ceil(max([max(x), max(xe)]));
    blob_bw = poly2mask(x,y,m,n);
    ellipse_bw = poly2mask(xe, ye, m,n);
    area_delta1=abs(avg_area-geom1(1));
    intrsct = blob_bw & ellipse_bw;
    unn = blob_bw | ellipse_bw;
    overlap = sum(intrsct(:))/sum(unn(:));

end

c = [mean(x), mean(y)];
v1 = c-[x(1),y(1)];
v2 = c-[x(end),y(end)];
angle = acos(sum(v1.*v2)/(norm(v1)*norm(v2)));
spread = 1 - (angle/(2*pi));
%  qual = (overlap + spread)/2;
p_delta=1.0*perimeter_delta/geom1(4);
qual=(16*overlap + 16*spread)/(1.5*x_delta+1.5*y_delta+p_delta+5.0*long_short);
end