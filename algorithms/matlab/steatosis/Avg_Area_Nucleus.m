function avg_area= Avg_Area_Nucleus(NumberOfimages)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Avg_Area_Nucleus function computes the average single nucleus size 
% Params:
%   NumberOfimages is the number of images
% Return:
%   avg_area is the average area size
%   =======================================================================================
%   Copyright (C) 2018  Xiaoyuan Guo
%   Email: xiaoyuan.guo@emory.edu
%   =======================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%chose the number of images you want to give input
prefix_image='Nucleus_';    %change the desired input image name here only
fileformat='.tif';       %change the desired input image format here only
area_sum=0;
for num=1:NumberOfimages
	I= imread(strcat(prefix_image,num2str(num),fileformat));
    blue = I(:,:,3);
    bw=im2bw(blue,graythresh(blue));
    [B, ~] = bwboundaries(bw, 'noholes');
    b = B{1};
    area_sum=area_sum+area(b);
end
avg_area=area_sum/NumberOfimages;
