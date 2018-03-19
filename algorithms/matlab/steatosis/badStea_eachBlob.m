%function [] = cell_segmentation(bad_stea)
clear all;
clc;

global path;
% path='/Users/xiaoyuanguo/Downloads/BMI_DeepLearning/Project2/badStea/blob_1';
path='/Users/xiaoyuanguo/Downloads/BMI_DeepLearning/Project2/199/199_3';
s='.png';
filename=strcat(path,s);
% sm='_marker.png';
% marker_write=strcat(path,sm);
% s_obr='_obr.png';
% s_obr_write=strcat(path,s_obr);
% s_hyst='_hyst.png';
% s_hyst_write=strcat(path,s_hyst);
% s_solidity='_solidity.png';
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


IM = imread(s_badSteat_color_write);
IM1 = imread(s_badSteat_image_write);
bad_stea = imread(s_badSteat_write);

[B1, L1] = bwboundaries(bad_stea, 'noholes');
[r c] = size(B1);

%figure,imshow(bad_stea,[]); hold on;


for p = 1:r
   
 fit_quality1_prev = 0;
 fit_quality2_prev = 0; 
   
    
 b1 = B1{p};
 
 
 [row col] = size(b1);
 
 if (row > 200)

%  Separate each blob and save in new image
%     % fit bounding box around the boundary pixels
    min_y = min(b1(:,1));
    min_x = min(b1(:,2));
    max_y = max(b1(:,1));
    max_x = max(b1(:,2));
    
    min_x1 = min_x - 15;
    min_y1 = min_y - 15;
    max_x1 = max_x + 15;
    max_y1 = max_y + 15;
    width1 = max_x1 - min_x1;
    height1 = max_y1 - min_y1;
    I_color = imcrop(IM, [min_x1, min_y1, width1, height1]);
    I = im2bw(I_color);
    %[B, L] = bwboundaries(I, 'noholes');
    
    % when there are other niose part due to crop , remove the noisy parts
   CC = bwconncomp(I);
   numOfPixels = cellfun(@numel,CC.PixelIdxList);
   [unused,indexOfMax] = max(numOfPixels);
   biggest = zeros(size(I));
   biggest(CC.PixelIdxList{indexOfMax}) = 1;
   %figure,imshow(biggest);
   I = biggest;
   [B, L] = bwboundaries(I, 'noholes'); 
   
   
    I_image = imcrop(IM1, [min_x1, min_y1, width1, height1]);
    
%     % do not proceed with this blob if contains more pinkish area
%     I_gray = rgb2gray(I_color);  
%     
%     S = regionprops(I, 'Area');  % total no of pixels in the image region area
%    S1 = [S.Area];
%     
%     S2 = sum(sum(I_gray > 150));  
%     pixel_ratio = S2/S1;
%     
%  if (pixel_ratio > 0.995)

 % bla bla bla 
% end 
 
    
    f1 = figure(1); imshow(I_image,[]); hold on;
    name1 = strcat('D:\Fusheng\Steatosis_project\Mousumi\Research\Steatosis_detection\91\badStea\Step_Results\blob_',num2str(p),'_original.png');
        %saveas(f2, name1);
    
        % write the image without whitespace

        imwrite(I_image,name1);
        
    f2 = figure(2); imshow(I,[]); hold on;
    

sigma = 4; %reduce further from 4
t = ceil(3*sigma);
h = exp(-[-t:t].^2/(2*sigma^2)) / (sigma*sqrt(2*pi));
h = h'/sum(h);

h1 = conv(h, [1 0 -1]', 'valid');
h1 = h1 - sum(h1)/length(h1);
h2 = conv(h1, [1 0 -1]', 'valid');
h2 = h2 - sum(h2)/length(h2);

CURVATURE = -0.1;
ARC = 25;
thresh_angle = 125;

joined_index = [];
list_ind_temp = [];
list_ind = [];

for i = 1:length(B)
   b = B{i};

    b(:,1) = imfilter(b(:,1), h , 'circular', 'same', 'conv');
    b(:,2) = imfilter(b(:,2), h , 'circular', 'same', 'conv');
    plot(b(:,2), b(:,1), 'c','LineWidth', 2);
  

    %convolution with derivative of gaussian filter
    x11 = imfilter(B{i}(:,2), h1, 'circular', 'same', 'conv'); % conv2(B{i}(:,2), h1,'same') also works
    x22 = imfilter(B{i}(:,2), h2, 'circular', 'same', 'conv');
    y11 = imfilter(B{i}(:,1), h1, 'circular', 'same', 'conv');
    y22 = imfilter(B{i}(:,1), h2, 'circular', 'same', 'conv'); 
    k = (x11.*y22 - y11.*x22)./(eps+(x11.^2+y11.^2).^(3/2));
    
    %figure;plot(k);
    curv_TF = k<CURVATURE;
    
    %sort curvature strength and combine adjacent high curvature points
    if sum(curv_TF)>0
        [~, start_ind] = min(k);
        list_ind = find(curv_TF);
        remove_TF = false(length(list_ind), 1);
        
        M = sum(list_ind<=start_ind);
        if M>1
            current = M;
            for i = (M-1):-1:1
                d = arc_length(b, list_ind(current), list_ind(i));
                if d < ARC
                    remove_TF(i) = true;
                else
                    current = i;
                end
            end
        end
        
        if M<length(list_ind)
            current = M;
            for i = M+1:length(list_ind)
                d = arc_length(b, list_ind(current), list_ind(i));
                if d < ARC
                    remove_TF(i) = true;
                else
                    current = i;
                end
            end
        end
        
       list_ind(remove_TF) = [];
       
       %list_ind = list_ind(3:4);
       
       plot(b(list_ind,2), b(list_ind,1), '.', 'MarkerSize', 10, 'MarkerEdgeColor','r');
       
       name1 = strcat('D:\Fusheng\Steatosis_project\Mousumi\Research\Steatosis_detection\91\badStea\Step_Results\blob_',num2str(p),'_','_marker.png');
        %saveas(f2, name1);
    
        % write the image without whitespace
        f1=getframe; 
        imwrite(f1.cdata,name1);
       
       hold off;
       
       %---------------------------------------------------------------------
       % when we have more than two markers
       if length(list_ind) > 1
       c =[];
           
       c = combnk(1: length(list_ind), 2);
         
        [rr cc] = size(c);   
       % for each marker position in 'l'  
       for index = 1:rr
       
           first = c(index,1);
           second = c(index,2);
              
                % Take the two marker locations in new variable
               list_ind_temp = list_ind(first);
               list_ind_temp = [list_ind_temp ; list_ind(second)];
               

       f3 = figure(3); imshow(I,[]); hold on;
      % plot the line joining teh two markers
      handle1 = plot(b(list_ind_temp,2), b(list_ind_temp,1),'Color', 'r', 'LineWidth', 2);
       
       name1 = strcat('D:\Fusheng\Steatosis_project\Mousumi\Research\Steatosis_detection\91\badStea\Step_Results\blob_',num2str(p),'_',num2str(first),num2str(second),'_temp.png');
        %saveas(f2, name1);
    
        % write the image without whitespace
        f1=getframe; 
        imwrite(f1.cdata,name1);
        
        hold off;
        % ------------------------------------------------------------------------------
        % Measure the angle and then decide about the line to join or not

    % Find each blob separately and fit ellipse and then estimate total fitting estimates    
    I1 = imread(name1);
 
    [row1 col1 dim] = size(I1);

    
    I2 = im2bw(I1);   % binary image for blob1
    
     CC1 = bwconncomp(I2);
     
    numOfPixels = cellfun(@numel,CC1.PixelIdxList);
    [unused,indexOfMin] = min(numOfPixels);
   if (unused < 1000)
       I2(CC1.PixelIdxList{indexOfMin}) = 0;
   end
   %figure,imshow(biggest);
   
    
    % remove small objects, noise
    I2 = bwareaopen(I2,500);
    I3 = im2bw(I1);   % binary image for blob2 
    
    % remove small objects, noise
    I3 = bwareaopen(I3,500);
    [B2 L2] = bwboundaries(I2, 'noholes');
    
    % if there is any small noisy component, remove that
    


    
    % separate each blob in I2 and I3
    for m = 1:row1
        for n =1:col1
            if(L2(m,n) == 1)
                I2(m,n)=0;
            end
            if(L2(m,n) == 2)
                    I3(m,n) = 0;
            end
        end
    end
       
% Find centroid of the shape
%s = regionprops(I2,'centroid');
%centroids = cat(1, s.Centroid);

s1 = regionprops(I2,{...
    'Centroid',...
    'MajorAxisLength',...
    'MinorAxisLength',...
    'Orientation'});

s2 = regionprops(I3,{...
    'Centroid',...
    'MajorAxisLength',...
    'MinorAxisLength',...
    'Orientation'});

% If any of the ellipse is not present then loop to next iteration
 if (isempty(s1) || isempty(s2))
     continue;
 else


%figure, imshow(I1);
%hold on;

f4 = figure(4); imshow(I_image);
t = linspace(0,2*pi,50);

hold on

% Draw the first ellipse
  
for k1 = 1:length(s1)
    a1 = s1(k1).MajorAxisLength/2;
    b1 = s1(k1).MinorAxisLength/2;
    Xc1 = s1(k1).Centroid(1);
    Yc1 = s1(k1).Centroid(2);
    phi1 = deg2rad(-s1(k1).Orientation);
    x1 = Xc1 + a1*cos(t)*cos(phi1) - b1*sin(t)*sin(phi1);
    y1 = Yc1 + a1*cos(t)*sin(phi1) + b1*sin(t)*cos(phi1);
   handle2 =  plot(x1,y1,'r','Linewidth',2);
end

    % Calculate fit_quality for blob1
b1 = poly2mask(x1, y1, row1, col1);
b2 = I2;      %original image of blob1
reg_inter1 = b1 & b2;
area_inter1 = bwarea(reg_inter1);
%figure,imshow(reg_inter);

reg_union1 = b1 | b2;
area_union1 = bwarea(reg_union1);
%figure,imshow(reg_union);

fit_quality1 = area_inter1 / area_union1;


% Draw the second ellipse


    for k2 = 1:length(s2)
    a2 = s2(k2).MajorAxisLength/2;
    b2 = s2(k2).MinorAxisLength/2;
    Xc2 = s2(k2).Centroid(1);
    Yc2 = s2(k2).Centroid(2);
    phi2 = deg2rad(-s2(k2).Orientation);
    x2 = Xc2 + a2*cos(t)*cos(phi2) - b2*sin(t)*sin(phi2);
    y2 = Yc2 + a2*cos(t)*sin(phi2) + b2*sin(t)*cos(phi2);
    handle3 = plot(x2,y2,'b','Linewidth',2);
    end
    
    %Calculate fit_quality for blob2
b3 = poly2mask(x2, y2, row1, col1);
b2 = I3;  % original image of blob2
reg_inter2 = b3 & b2;
area_inter2 = bwarea(reg_inter2);
%figure,imshow(reg_inter);

reg_union2 = b3 | b2;
area_union2 = bwarea(reg_union2);
%figure,imshow(reg_union);

fit_quality2 = area_inter2 / area_union2;

  
   
hold off

% a = s(1).MajorAxisLength/2 ;
% b = s(1).MinorAxisLength/2;
% ellipse_area = pi * a * b;
% region_area = bwarea(I2);

name2 = strcat('D:\Fusheng\Steatosis_project\Mousumi\Research\Steatosis_detection\91\badStea\Step_Results\blobEllipseFitted_',num2str(p),'.png');
%saveas(f2, name1);

% write the image without whitespace
f=getframe; 
imwrite(f.cdata,name2);

if (fit_quality1 > fit_quality1_prev && fit_quality2 > fit_quality2_prev)


if(fit_quality1 < 0.7 || fit_quality2 < 0.7)

    delete(handle1);
    name1 = strcat(path,'_bad_',num2str(p),'.png');
%     name1 = strcat('D:\Fusheng\Steatosis_project\Mousumi\Research\Steatosis_detection\91\badStea\blob_',num2str(p),'.png');
    imwrite(I_image,name1);
    
else
    f5 = figure(5); imshow(I_image);
    hold on;
    handle1 = plot(b(list_ind_temp,2), b(list_ind_temp,1),'Color', 'g', 'LineWidth', 2);
    f=getframe; 
    name1 = strcat(path,'_bad_',num2str(p),'.png');
    % write the image without whitespace
    imwrite(f.cdata,name1);  
    hold off;
    
end

% ---------------------------------------------------------------------------------------
       
       
       %end

      % id2 = id2 +1;
      fit_quality1_prev  = fit_quality1;
      fit_quality2_prev  = fit_quality2;

  
      
else
    continue;
	
end
 end
      close all;
       end
       %end
       %end
       
       end

    end

    
end


    % if there is no marker or one marker then just write the image in disc
    if(length(list_ind) <= 1)
    name1 = strcat('D:\Fusheng\Steatosis_project\Mousumi\Research\Steatosis_detection\91\badStea\blob_',num2str(p),'.png');
    % write the image without whitespace
    imwrite(I_image,name1);
    end

 

 else
     continue;
 
 end
 
 
 close all;



end






% 
% for m = 1: row1
%     for n = 1:col1
%         if(I1(m,n,1) == 0 && I1(m,n,2) == 0 && I1(m,n,3) == 0 )
%             
%             
%             break; 
%         end
%         
%     end
%     
% end
% 
% x_min = n;
% y_min = m;
% I2 = imcrop(I1, [x_min, y_min, width1, height1]);
%             figure(4), imshow(I2);

%----------------------------------------------------------------------------

% find the region of marker
% b_temp = b(list_ind_temp(1): list_ind_temp(2),1);
% b_temp(:,2) = b(list_ind_temp(1): list_ind_temp(2),2);
%        
%         min_y = min(b_temp(:,1));
%         min_x = min(b_temp(:,2));
%         max_y = max(b_temp(:,1));
%         max_x = max(b_temp(:,2));
% 
%     min_x1 = min_x - 10;
%     min_y1 = min_y - 10;
%     max_x1 = max_x + 10;
%     max_y1 = max_y + 10;
%     width1 = max_x1 - min_x1;
%     height1 = max_y1 - min_y1;
% 
%     I_temp = imcrop(I, [min_x, min_y, width1, height1]);
%     figure(3), imshow(I_temp);


% ---------------------------------------------------------------------------

%print('D:\Fusheng\Steatosis_project\Mousumi\Research\Steatosis_detection\91\91_badSteat_marked','-djpeg');
%test = getimage(I);
%imwrite(test,'D:\Fusheng\Steatosis_project\Mousumi\Research\Steatosis_detection\91\91_badSteat_marked.png');
    
%end
