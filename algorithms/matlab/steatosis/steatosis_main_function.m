function output = steatosis_main_function(input)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function aims to detect steatosis in the original image, classify
% them into good steatosis and bad steatosis. For those bad steatosis,
% apply the segmentation method to obtaining good segmentaion results  
%   =======================================================================================
%   Copyright (C) 2018  Xiaoyuan Guo
%   Email: xiaoyuan.guo@emory.edu
%   =======================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global path;
global s_goodSteat_image_write;

path='./199/199_1';
s='.png';
filename=strcat(path,s);
s_ALLSteat_image='_ALLSteat_image_me.png';
s_ALLSteat_image_write=strcat(path,s_ALLSteat_image);
s_badSteat='_badSteat.png';
s_badSteat_write=strcat(path,s_badSteat);
s_badSteat_color='_badSteat_color.png';
s_badSteat_color_write=strcat(path,s_badSteat_color);
s_badSteat_image='_badSteat_image.png';
s_badSteat_image_write=strcat(path,s_badSteat_image);
s_goodSteat_image='_goodSteat_image.png';
s_goodSteat_image_write=strcat(path,s_goodSteat_image);
s_goodSteat='_goodSteat.png';
global s_goodSteat_write;
s_goodSteat_write=strcat(path,s_goodSteat);

f1 = input;
%f1 = imread('./199/199_1.PNG');

[row col dim] = size(f1);
IM = f1;   % To mark the bad steatosis
IM1 = f1;  % To  mark the good steatosis
IM2 = f1; % To mark both good and bad steatosis

for i = 1:row
    for j = 1:col
        if(f1(i,j,1) == 0 && f1(i,j,2) == 0 && f1(i,j,3) == 0)
            f1(i,j,1) = 220;
            f1(i,j,2) = 220;
            f1(i,j,3) = 220;
        end           
    end
end

Iblur = imgaussfilt(f1, 5);
BW = im2bw(Iblur , 0.75);%best 0.80

% convert to grayscale
f2 = rgb2gray(f1);
%Remove small objects from binary image.
BW2 = bwareaopen(BW,150, 8);%best 200

% Use the circularity parameters
BW = BW2;
labeledImage = bwlabel(BW,8);
measurements = regionprops(labeledImage, 'Area', 'Perimeter');

allAreas = [measurements.Area];

ind = find(allAreas<50000);    %50000
BW1 = ismember(labeledImage,ind);

labeledImage = bwlabel(BW1,8);
measurements = regionprops(labeledImage, 'Area', 'Perimeter');
allAreas = [measurements.Area];
allPerims = [measurements.Perimeter];
circularities = allPerims .^ 2 ./ (4*pi*allAreas);

keepIdx = find(circularities < 3);    %3

BW2 = ismember(labeledImage,keepIdx);

%% New part to separate good and bad steatosis for applying segregation

% solidity determine bad steatosis and false positive -----------------
labelIm = bwlabel(BW2);
stats = regionprops(labelIm, 'Solidity');
allSolid = [stats.Solidity];
keepIdx = find(allSolid < 0.95);    %0.95,0.65
BW3 = ismember(labelIm,keepIdx);

gd_stea = BW2 - BW3;

gd_stea_edge = edge(gd_stea,'Canny');
gd_stea_edge = imdilate(gd_stea_edge,strel('disk',1));


[row col] = size(gd_stea_edge);

for i = 1:row
    for j = 1:col
        if(gd_stea_edge(i,j) == 1)
                    IM1(i,j,1) = 0;
                    IM1(i,j,2) = 255;
                    IM1(i,j,3) = 0;
                    IM1(i+1,j+1,1) = 0;
                    IM1(i+1,j+1,2) = 255;
                    IM1(i+1,j+1,3) = 0;         
            end
        end
end

bad_stea = BW3;
bad_stea_color = uint8(bad_stea);

for i = 1:row
    for j = 1:col
        if(bad_stea_color(i,j) == 1)
            bad_stea_color(i,j,1) = IM(i,j,1);
            bad_stea_color(i,j,2) = IM(i,j,2);
            bad_stea_color(i,j,3) = IM(i,j,3);
        end
    end
end


bad_stea=badStea_eachBlob_Xiaoyuan(bad_stea);
bad_stea_edge = edge(bad_stea,'Canny');
bad_stea_edge = imdilate(bad_stea_edge,strel('disk',1));

[row col] = size(bad_stea_edge);

for i = 1:row
    for j = 1:col
        if(bad_stea_edge(i,j) == 1)
                    IM(i,j,1) = 0;
                    IM(i,j,2) = 255;
                    IM(i,j,3) = 0;                           
            end
        end
end


%imwrite(bad_stea, s_badSteat_write);

%% Plot good and bad steatosis both in image

for i = 1:row
    for j = 1:col
        if(gd_stea_edge(i,j) == 1 || bad_stea_edge(i,j) == 1)
                    IM2(i,j,1) = 0;
                    IM2(i,j,2) = 255;
                    IM2(i,j,3) = 0;
                    IM2(i+1,j+1,1) = 0;
                    IM2(i+1,j+1,2) = 255;
                    IM2(i+1,j+1,3) = 0;         
            end
        end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%imwrite(IM2, s_ALLSteat_image_write);

output = getContour(transpose(gd_stea), 15);


