function result = ihc_main_function(input, stain_setting, upper_threshold, lower_threshold, stain_red, stain_green, stain_blue)

close all; clc;
% 
%     %find images to be analyzed
%     inputFileName = dir('*.png');
%     inputFileName = {inputFileName.name};
%     k = strfind(inputFileName, '.');
%     imageNumber = cellfun(@(x,y) str2double(y(1:x(1)-1)), k, inputFileName);
%     [~, ind] = sort(imageNumber);
%     inputFileName = inputFileName(ind);
% 
%     %take the first one
%     i = 1;
%     I=imread(['./' inputFileName{i}]);

I=input;

stain_setting = str2num(stain_setting);

%define OD matrix; each column is associated with one stain (i.e. Hematoxylin, DAB, and red_marker)
%        Hemat  DAB  red_marker

if stain_setting == 1
    stains =[0.650 0.368 0.103;...   %Red
    0.704 0.570 0.696;...   %Green
    0.286 0.731 0.711];     %Blue
elseif stain_setting == 2
    stains =[0.65 0.70 0.29;...
    0.07 0.99 0.11;...
    0.27 0.57 0.78];
elseif stain_setting == 3
    stains =[0.6500286 0.704031 0.2860126;...
    0.26814753 0.57031375 0.77642715;...
    0.7110272 0.42318153 0.5615672];
elseif stain_setting == 0 && length(stain_red) == 3 && length(stain_green) == 3 && length(stain_blue) == 3 && isa(stain_red, 'double') && isa(stain_green, 'double') && isa(stain_blue, 'double')
    stains =[stain_red;stain_green;stain_blue];
else
    stains =[0.650 0.368 0.103;...   %Red
    0.704 0.570 0.696;...   %Green
    0.286 0.731 0.711];     %Blue
end

T1 = upper_threshold;
T2 = lower_threshold;


ARC_LIMIT = 15; %threshold for contour length for smoothing process

if T1<T2
    %fprintf('T1 has to be no smaller than T2');
    t = T1;
    T1 = T2;
    T2 = t;
    clear t
end

T1 = min(255, T1);
T2 = max(0,   T2);


%calculate stain intensities using color deconvolution
[Deconvolved, colorImage] = ColorDeconvolution_FullNewVer(I, stains, [true true true]);
DAB = imcomplement(Deconvolved(:,:,2));


Pos_Pix_Num = sum(DAB(:) >= T1);
Med_Pix_Num = sum((DAB(:) < T1) & (DAB(:) >= T2));
Low_Pix_Num = sum(DAB(:) < T2);

Pos_Pix_Num_Perc = Pos_Pix_Num*100./length(DAB(:));
Med_Pix_Num_Perc = Med_Pix_Num*100./length(DAB(:));
Low_Pix_Num_Perc = Low_Pix_Num*100./length(DAB(:));

Pos_Contour = getContour( DAB>=T1, ARC_LIMIT );
Med_Contour = getContour( ((DAB<T1) & (DAB>=T2)), ARC_LIMIT );
Low_Contour = getContour( DAB<T2, ARC_LIMIT );
Pos_Contour_T = {};
Med_Contour_T = {};
Low_Contour_T = {};


imshow(I,[]); hold on;
for i = 1:length(Pos_Contour)
    b = Pos_Contour{i};
    b_t = b;
    plot(b(:,2), b(:,1), 'g', 'LineWidth', 2);
    b_t(:,1) = b(:,2);
    b_t(:,2) = b(:,1);
    Pos_Contour_T{i,1} = b_t;
end

for i = 1:length(Med_Contour)
    b = Med_Contour{i};
    b_t = b;
    plot(b(:,2), b(:,1), 'g', 'LineWidth', 2);
    b_t(:,1) = b(:,2);
    b_t(:,2) = b(:,1);
    Med_Contour_T{i,1} = b_t;
end

for i = 1:length(Low_Contour)
    b = Low_Contour{i};
    b_t = b;
    plot(b(:,2), b(:,1), 'g', 'LineWidth', 2);
    b_t(:,1) = b(:,2);
    b_t(:,2) = b(:,1);
    Low_Contour_T{i,1} = b_t;
end

result = {Pos_Contour_T, Med_Contour_T, Low_Contour_T, Pos_Pix_Num, Med_Pix_Num, Low_Pix_Num, Pos_Pix_Num_Perc, Med_Pix_Num_Perc, Low_Pix_Num_Perc};
end
