clear all;
clc;
global path;
% path='/Users/xiaoyuanguo/Downloads/BMI_DeepLearning/Project2/badStea/blob_1';
% path='/Users/xiaoyuanguo/Downloads/BMI_DeepLearning/Project2/199/3_100um';
path='/Users/xiaoyuanguo/Downloads/BMI_DeepLearning/Project2/199/199_3';
s='.png';
filename=strcat(path,s);
sm='_marker.png';
marker_write=strcat(path,sm);
s_obr='_obr.png';
s_obr_write=strcat(path,s_obr);
s_hyst='_hyst.png';
s_hyst_write=strcat(path,s_hyst);
s_solidity='_solidity.png';
s_solidity_write=strcat(path,s_solidity);
s_ALLSteat_image='_ALLSteat_image.png';
s_ALLSteat_image_write=strcat(path,s_ALLSteat_image);
s_badSteat='_badSteat.png';
s_badSteat_write=strcat(path,s_badSteat);
s_badSteat_color='_badSteat_color.png';
s_badSteat_color_write=strcat(path,s_badSteat_color);
s_badSteat_image='_badSteat_image.png';
s_badSteat_image_write=strcat(path,s_badSteat_image);
global s_goodSteat_image_write;
s_goodSteat_image='_goodSteat_image.png';
s_goodSteat_image_write=strcat(path,s_goodSteat_image);
s_bin1='_bin1.png';
s_bin1_write=strcat(path,s_bin1);
s_bin2='_bin2.png';
s_bin2_write=strcat(path,s_bin2);
s_bin3='_bin3.png';
s_bin3_write=strcat(path,s_bin3);
s_bin4='_bin4.png';
s_bin4_write=strcat(path,s_bin4);
s_goodSteat='_goodSteat.png';
global s_goodSteat_write;
s_goodSteat_write=strcat(path,s_goodSteat);
% f1 = imread('D:\Fusheng\Steatosis_project\Mousumi\Research\Steatosis_detection\91\91.png');
f1 = imread(filename);


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

% convert to grayscale
f2 = rgb2gray(f1);
%figure,imshow(f2);

 
mask = adapthisteq(f2);
% figure,imshow(mask);

se = strel('disk',5);
marker = imerode(mask,se);
% figure,imshow(marker);
% imwrite(marker,'D:\Fusheng\Steatosis_project\Mousumi\Research\Steatosis_detection\91\91_marker.png');
imwrite(marker,marker_write);

obr = imreconstruct(marker,mask);
% figure,imshow(obr,[]);

% imwrite(obr,'D:\Fusheng\Steatosis_project\Mousumi\Research\Steatosis_detection\91\91_obr.png');
imwrite(obr,s_obr_write);

%high_t = 0.8;
%low_t = 0.5;
%areaThr = 20;
%SEPARATION = 'false';
%SMOOTH = 'false';
%bwMask = hysteresis(marker, high_t, low_t, areaThr, SEPARATION, SMOOTH);

% binarize using hysteresis thresholding
t_low = 0.64;
t_high = 0.80;
[r1, r2] = hysteresis3d(marker, t_low, t_high, 8);
% imwrite(r2, 'D:\Fusheng\Steatosis_project\Mousumi\Research\Steatosis_detection\91\91_hyst.png');
imwrite(r2, s_hyst_write);
bw1 = r2;

% post processing of the binary image
bw2 = bwareaopen(bw1,floor(nthroot(numel(bw1),3)/2));
% imwrite(bw2,'D:\Fusheng\Steatosis_project\Mousumi\Research\Steatosis_detection\91\91_bin1.png');
imwrite(bw2,s_bin1_write);

bw_open = imopen(bw2, strel('disk',10));
% imwrite(bw_open,'D:\Fusheng\Steatosis_project\Mousumi\Research\Steatosis_detection\91\91_bin2.png');
imwrite(bw_open,s_bin2_write);

bw3 = bwareaopen(bw_open, 1000);
% imwrite(bw3,'D:\Fusheng\Steatosis_project\Mousumi\Research\Steatosis_detection\91\91_bin3.png');
imwrite(bw3,s_bin3_write);

% Use the circularity parameters
BW = bw3;
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
figure,imshow(BW2)
% imwrite(BW2,'D:\Fusheng\Steatosis_project\Mousumi\Research\Steatosis_detection\91\91_bin4.png');
imwrite(BW2,s_bin4_write);

%% New part to separate good and bad steatosis for applying segregation

% solidity determine bad steatosis and false positive -----------------
labelIm = bwlabel(BW2);
stats = regionprops(labelIm, 'Solidity');
allSolid = [stats.Solidity];
keepIdx = find(allSolid < 0.95);    %0.95
BW3 = ismember(labelIm,keepIdx);
figure,imshow(BW3)

% imwrite(BW3,'D:\Fusheng\Steatosis_project\Mousumi\Research\Steatosis_detection\91\91_solidity.png');
imwrite(BW3,s_solidity_write);

gd_stea = BW2 - BW3;
figure, imshow(gd_stea)
% imwrite(gd_stea,'D:\Fusheng\Steatosis_project\Mousumi\Research\Steatosis_detection\91\91_goodSteat.png');
imwrite(gd_stea,s_goodSteat_write);

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

% imwrite(IM1, 'D:\Fusheng\Steatosis_project\Mousumi\Research\Steatosis_detection\91\91_goodSteat_image.png');

imwrite(IM1, s_goodSteat_image_write);

%% From BW1 keep bad steatosis removing false positive

%BW4 = bwareaopen(BW3,floor(sqrt(numel(BW3))/2));
%imwrite(bw1,'/Users/mousumi/Documents/Fusheng/Jun_project/Mousumi/Stage4/im7/tissue2/Expt/1_bin_step1.png');


%% Keep this part off for time being , consider all blob without extent criteria as bad steat
%check Extent

labelIm = bwlabel(BW3);
stats = regionprops(labelIm, 'Extent');
allExt = [stats.Extent];
keepIdx = find(allExt >= 0.65);  %0.65  
BW5 = ismember(labelIm,keepIdx);

figure,imshow(BW5)
bad_stea = BW5;
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

%% 

bad_stea = BW5;
bad_stea_edge = edge(BW5,'Canny');
bad_stea_edge = imdilate(bad_stea_edge,strel('disk',1));


[row col] = size(bad_stea_edge);

for i = 1:row
    for j = 1:col
        if(bad_stea_edge(i,j) == 1)
                    IM(i,j,1) = 0;
                    IM(i,j,2) = 255;
                    IM(i,j,3) = 0;
                    %IM(i-1,j-1,1) = 0;
                    %IM(i-1,j-1,2) = 255;
                    %IM(i-1,j-1,3) = 0;
                    
         
            end
        end
end

% imwrite(IM, 'D:\Fusheng\Steatosis_project\Mousumi\Research\Steatosis_detection\91\91_badSteat_image.png');
% 
% imwrite(bad_stea_color, 'D:\Fusheng\Steatosis_project\Mousumi\Research\Steatosis_detection\91\91_badSteat_color.png');
% imwrite(bad_stea, 'D:\Fusheng\Steatosis_project\Mousumi\Research\Steatosis_detection\91\91_badSteat.png');

imwrite(IM, s_badSteat_image_write);

imwrite(bad_stea_color, s_badSteat_color_write);
imwrite(bad_stea, s_badSteat_write);


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

% imwrite(IM2, 'D:\Fusheng\Steatosis_project\Mousumi\Research\Steatosis_detection\91\91_ALLSteat_image.png');
imwrite(IM2, s_ALLSteat_image_write);
%% --------------------------------------------
% -----------------------------------------------------------------------------------------------------------------------------
% Plot boundary of the steatosis
%  BW3 = edge(BW2,'Canny');
%  BW3 = imdilate(BW3,strel('disk',1));
% 
%  imwrite(BW3,'D:\Fusheng\Steatosis_project\Mousumi\Research\Steatosis_detection\91\91_bin5.png');
% 
% 
% [row col] = size(BW3);
% 
% for i = 1:row
%     for j = 1:col
%         if(BW3(i,j) == 1)
%            % for k = i-1 : i
%                % for l = j-1:j
%                     %if(k > row || l > col)
%                        % continue;
%                     %end
%                     IM(i,j,1) = 0;
%                     IM(i,j,2) = 255;
%                     IM(i,j,3) = 0;
%                     IM(i-1,j-1,1) = 0;
%                     IM(i-1,j-1,2) = 255;
%                     IM(i-1,j-1,3) = 0;
%                     %end
%                 %end
%             end
%         end
% end
% 
% 
% imwrite(IM,'D:\Fusheng\Steatosis_project\Mousumi\Research\Steatosis_detection\91\91_stet.png');

% ---------------------------------------------------------------------------

%cell_segmentation(bad_stea);


