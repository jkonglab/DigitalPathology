function new_adj_qual_mat=Find_High_Qual_Pts(adj_qual_mat)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find_High_Qual_Pts function finds those point pairs that have high
% ellipse fitting quality
% Params:
%   adj_qual_mat is the quality matrix of adjacent point pairs
% Return:
%   new_adj_qual_mat is the updated quality matrix 
%   =======================================================================================
%   Copyright (C) 2018  Xiaoyuan Guo
%   Email: xiaoyuan.guo@emory.edu
%   =======================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global QUALTHRESH;
k=length(adj_qual_mat(:,1));
new_adj_qual_mat=zeros(k,4);
for i=1:k
    for j=1:4
        if adj_qual_mat(i,j)>=QUALTHRESH
           new_adj_qual_mat(i,j)=1;
        end
    end
end