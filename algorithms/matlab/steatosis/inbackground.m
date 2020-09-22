function bool = inbackground(bw, x1, x2)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% inbackground function identifies whether the connecting line of the point
% pair (x1,x2) is intersected with the clumped nuclei boundary bw
% Params:
%   bw is the boundary points
%   x1,x2 are the point pair
% Return:
%   bool is the indicator
%
%   =======================================================================================
%   Copyright (C) 2018  Xiaoyuan Guo
%   Email: xiaoyuan.guo@emory.edu
%   =======================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% true if the line connecting x1 and x2 crosses the background of bw
% define discretizes line between x1 and x2
n = floor(max([abs(x1(1)-x2(1)), abs(x1(2)-x2(2))]));
begin_x=ceil(x1(1));
end_x=floor(x2(1));
begin_y=ceil(x1(2));
end_y=floor(x2(2));
if length(bw)==0
    bool=true;
    return 
end
    
if begin_x==end_x || begin_y==end_y
    xs=begin_x;
    ys=begin_y;
else
    xs = round(linspace(begin_x,end_x, n))';
    ys = floor(interp1([begin_x end_x], [begin_y end_y],xs, 'spline')); 
end

bool = false;
if length(xs)>1
    for i = 1:length(xs)-1
        disp(bw)
        disp(length(bw(:,1)))
        disp(xs(i))
        disp(ys(i))
        disp(length(bw(:,2)))
        if xs(i)>=length(bw(:,1))||ys(i)>=length(bw(:,2))
            return
        end
        if ~bw(xs(i),ys(i))
            bool = true;
            return
        end
    end
elseif length(xs)==1
    if xs(1)>=length(bw(:,1))||ys(1)>=length(bw(:,2))
        return
    end
    if ~bw(xs(1),ys(1))
        bool = true;
        return
    end  
else
    return
end

end