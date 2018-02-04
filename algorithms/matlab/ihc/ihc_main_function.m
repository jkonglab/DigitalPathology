function Pos_Contour = ihc_main_function(input)

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


%define OD matrix; each column is associated with one stain (i.e. Hematoxylin, DAB, and red_marker)
%        Hemat  DAB  red_marker
stains =[0.650 0.368 0.103;...   %Red
    0.704 0.570 0.696;...   %Green
    0.286 0.731 0.711];     %Blue

T1 = 150;  %threshold for strong vs. medium pixel
T2 = 50;   %threshold for weak vs. medium pixel
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


imshow(I,[]); hold on;
for i = 1:length(Pos_Contour)
    b = Pos_Contour{i};
    plot(b(:,2), b(:,1), 'g', 'LineWidth', 2);
end
end
