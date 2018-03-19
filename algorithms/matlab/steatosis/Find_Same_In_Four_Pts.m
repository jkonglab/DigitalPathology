function ret=Find_Same_In_Four_Pts(p,old_p,old_q,q)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find_Same_In_Four_Pts finds whether there are repeated points occured in
% the tuple
% Params:
%   p,old_p,old_q,q are four points
% Return:
%   ret is the indicator
%
%   =======================================================================================
%   Copyright (C) 2018  Xiaoyuan Guo
%   Email: xiaoyuan.guo@emory.edu
%   =======================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ret=false;
if p==old_p||p==old_q||p==q||old_p==old_q||old_p==q||old_q==q
    ret=true;
end