function ret=In_RemoveList(remove_list,p)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% In_RemoveList finds whether point p in remove_list or not
% Params:
%   p is the index of a point 
%   remove_list is the point set that need to be removed
% Return:
%   ret is the indicator
%
%   =======================================================================================
%   Copyright (C) 2018  Xiaoyuan Guo
%   Email: xiaoyuan.guo@emory.edu
%   =======================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ret=false;
for i=1:length(remove_list)
    if remove_list(i)==p
        ret=true;
        return
    end
end