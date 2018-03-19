clear all;
clc;

global path;
path='/Users/xiaoyuanguo/Downloads/BMI_DeepLearning/Project2/badStea/blob_1';
% path='/Users/xiaoyuanguo/Downloads/BMI_DeepLearning/Project2/199/199_3';
global s_goodSteat_write;
global s_goodSteat_image_write;
s_goodSteat='_goodSteat.jpg';
s_goodSteat_write=strcat(path,s_goodSteat);
s_goodSteat_image='_goodSteat_image.jpg';
s_goodSteat_image_write=strcat(path,s_goodSteat_image);
IM = imread(s_goodSteat_image_write);
%IM1 = imread('D:\Fusheng\Steatosis_project\Mousumi\Research\Steatosis_detection\91\91_badSteat_image.jpg');
gd_stea = imread(s_goodSteat_write);
[row1 col1] = size(gd_stea);

[B1, L1] = bwboundaries(gd_stea, 'noholes');
%figure,imshow(bad_stea,[]); hold on;

[r c] = size(B1);

for p = 1: r
   
  b1 = B1{p};
 [row col] = size(b1);
 
 if (row > 200)

%  Separate each blob and save in new image
%     % fit bounding box around the boundary pixels
    
%     for i = 1: row
%         for j = 1:col
%         i = b1(k,1);
%         j = b1(k,2);
%     
%         IM(i,j,1) = 0;
%         IM(i,j,2) = 255;
%         IM(i,j,3) = 0;
%         IM(i+1,j+1,1) = 0;
%         IM(i+1,j+1,2) = 255;
%         IM(i+1,j+1,3) = 0;
%     end    
%         
%          end
%         end
%     end
%     
    
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
    I_image = imcrop(IM, [min_x1, min_y1, width1, height1]);
    
    name1 = strcat(path,'_good_',num2str(p),'.jpg');
%  name1 = strcat('D:\Fusheng\Steatosis_project\Mousumi\Research\Steatosis_detection\91\goodStea\blob_',num2str(p),'.jpg');

    % write the image without whitespace
    imwrite(I_image,name1);
        
    
    
    
     end
 end
