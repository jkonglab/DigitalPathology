function [area_delta,x_delta,y_delta,perimeter_delta,geom1,geom2]=Eval_Similarity_Curves(x,y,xe,ye)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Eval_Similarity_Curves evaluates the similarity of two curves, by
% evaluating their area, center coordinates and perimeters
% Params:
%   x,y are the point coordinates of a curve
%   xe,ye are the point coordinates of other curve
% Return:
%   area_delta is the difference of two areas
%   x_delta,y_delta are the coordinate difference of two centroids 
%   perimeter_delta is the perimeter difference of two curves
%   geom1,geom2 are the geometry structure information of two curves
%   =======================================================================================
%   Copyright (C) 2018  Xiaoyuan Guo
%   Email: xiaoyuan.guo@emory.edu
%   =======================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


[ geom1, ~, ~] = polygeom( x, y );
[ geom2, ~, ~] = polygeom( xe, ye );

area_delta=abs(geom1(1)-geom2(1));
x_delta=abs(geom1(2)-geom2(2));
y_delta=abs(geom1(3)-geom2(3));
perimeter_delta=abs(geom1(4)-geom2(4));
