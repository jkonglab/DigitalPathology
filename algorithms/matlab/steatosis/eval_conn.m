function result=eval_conn(p,q,b,list_ind,curve)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% eval_conn evaluates the segmentation formed by the connecting curve and
% the point pair boundary curve
% Params:
%   p,q are the point pair
%   list_ind is the index number of candidate points
%   curve are the point coordinates of connecting curve
% Return:
%   result is the indicator
%   =======================================================================================
%   Copyright (C) 2018  Xiaoyuan Guo
%   Email: xiaoyuan.guo@emory.edu
%   =======================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

bpts = @(pt1, pt2) b(list_ind(pt1):list_ind(pt2),:);
global QUAL
global avg_area
boundary=[];
if length(list_ind)==2%only two points should evaluate the quality of both areaes  
	if (p==1&&q==length(list_ind))
    	boundary=[boundary; curve];
     	boundary=[boundary; b(list_ind(end):end,:); b(1:list_ind(1),:)];
    end
    value = measurequality(boundary);
    ar = polyarea(boundary(:, 1),boundary(:, 2));
    if value<QUAL ||ar<0.4*avg_area
        result=false;
        return
    else
        result=true;
    end
end
boundary=[];
boundary=[boundary; curve];
boundary=[boundary; bpts(p, q)];
ar = polyarea(boundary(:, 1),boundary(:, 2));
value = measurequality(boundary);
if value<QUAL ||ar<0.2*avg_area
    result=false;
else
    result=true;
end

