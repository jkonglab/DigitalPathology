function [new_p,new_q]=Swap_pq(p,q)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Swap_pq function changes the position of point p,q when p has larger
% index value than q
% Params:
%   p,q are the points 
% Return:
%   new_p, new_q is the changed point pair
%   =======================================================================================
%   Copyright (C) 2018  Xiaoyuan Guo
%   Email: xiaoyuan.guo@emory.edu
%   =======================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

new_p=p;
new_q=q;
if p>q
    new_p=q;
    new_q=p;
end