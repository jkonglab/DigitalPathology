function peaks = cell_seed_detection_main_function(input)

close all;
warning('off', 'all');
clc;

%load image
I=input;

%define OD matrix; each column is associated with one stain (i.e. Hematoxylin, Eosin, and red_marker)
%        Hemat      Eosin    Null
stains =[0.554688  0.380814  0;...   %Red
    0.781334  0.87215   0;...   %Green
    0.286075  0.307141  0];     %Blue
% stains =[0.554688  0.380814  0.13193;...   %Red
%          0.781334  0.87215   0.900097;...   %Green
%          0.286075  0.307141  0.415234];     %Blue
% stains =[0.554688  0.380814  0.191667;...   %Red
%          0.781334  0.87215   0.862937;...   %Green
%          0.286075  0.307141  0.46755];     %Blue

%calculate stain intensities using color deconvolution
[Deconvolved, colorImage] = ColorDeconvolution_FullNewVer(I, stains, [true true true]);
Hemat = Deconvolved(:,:,1);
Eosin = Deconvolved(:,:,2);
%HematColor = colorImage{1};
%EosinColor = colorImage{2};

%complement and smooth image
sigma=1;%5; %important!
G = fspecial('gaussian',round(3*sigma)*2+1,sigma); % Gaussian kernel
h = imcomplement(Hemat);
f = conv2(h, G, 'same');

%sigma=1;%important!
%G2 = fspecial('gaussian',round(3*sigma)*2+1,sigma); % Gaussian kernel
%f2 = conv2(h, G2, 'same');
%[fx, fy] = gradient(f2);

%canny edge
%[hx, hy] = gradient(double(h));
%hmag = sqrt(hx.*hx + hy.*hy);
%max_hmag = max(hmag(:));
%[edge_canny, thresh] = edge(double(h),'canny');
%edge_canny = logical(edge(double(h),'canny', [0.001, 0.3], 0.1)); %imshow(edge_canny,[]);


%morphological reconstruction
uint8f = uint8(f);

marker = imopen(uint8f, strel('disk',10));
recon = imreconstruct(marker,uint8f, 8);
dif = uint8f - recon;
%dif = uint8f;
%imtool(dif,[]);

% peaksBW = imregionalmax(dif);

%[fx,fy] = gradient(double(dif));
%firstOrder = sqrt(fx.^2 + fy.^2) < eps;
%secondOrder =  (Lambda1<0);
%peaksBW = firstOrder & secondOrder;

% figure;imshow(dif,[]); hold on;
% [r,c] = ind2sub(size(peaksBW), find(peaksBW));
% for i = 1:length(r)
%     plot(c(i), r(i), 'g*');
% end


%voting with sign of eigenvalues from Hessian matrix
vote = zeros(size(dif));
for sigma = 3:0.3:10;
    %for sigma = 3:0.3:15
    %for sigma = 2:0.3:10
    [fxx,fxy,fyy] = Hessian2D(double(dif), sigma);
    fxx = (sigma^2)*fxx;
    fxy = (sigma^2)*fxy;
    fyy = (sigma^2)*fyy;
    
    tmp = sqrt((fxx - fyy).^2 + 4*fxy.^2);
    Lambda1 = 0.5*(fxx + fyy + tmp);
    %Lambda2 = 0.5*(fxx + fyy - tmp);
    TF = Lambda1 < 0;
    vote(TF) = vote(TF) + 1;
end

%imshow(vote,[]); axis ij;
%surf(vote); axis ij; colormap jet;



%otusu thresholding
level = graythresh(uint8f);
otsuBW = im2bw(uint8f, level);
minOtsuA = 150;
otsuBW = bwareaopen(otsuBW, minOtsuA, 8);


%canny edge
grayI = imcomplement(rgb2gray(I));
edge_canny = logical(edge(double(grayI),'canny', [ ], 2));


%peak detection on voting map (merge by connection and distance)
minD = 15;%%10;%18;
minA = 10; %20;
alpha = 10;

v = sort(unique(vote(:)),'descend');

vnorm = (flipud(v) - v(end))/(v(1)-v(end)); %normalize [vmax, vmin] to [0, 1]
peaks = []; %peaks(x, y);

fprintf('Stage 1: find peaks with otusu, distance, connectivity constraints...\n');

for i = 1:length(v)
    a = vote >= v(i);
    L = bwlabel(a, 4);
    c = regionprops(L, 'Area', 'Centroid');
    d = round(reshape([c.Centroid], 2,length(c))');
    d = max(1, d);
    d(:,1) = min(size(vote,2), d(:,1));
    d(:,2) = min(size(vote,1), d(:,2));
    otsuTF = otsuBW((d(:,1)-1)*size(vote,1)+d(:,2))';
    b = ismember(L, find( otsuTF & ([c.Area]>(minA+exp(alpha*vnorm(i)))) ) );
    %b = ismember(L, find([c.Area]> max(20, minA-2*v(i))) );
    
    L = bwlabel(b, 4);
    c = regionprops(L, 'Centroid');
    cand_length = length(c);
    fprintf('new %d center candidates at voting threshold: %d\n', cand_length, v(i));
    
    if ~isempty(peaks)  %merge by connection
        removeL = L((peaks(:,1)-1) * size(vote,1) + peaks(:,2));
        removeTF = ismember(1:max(L(:)), removeL);
        c(removeTF) = [];
        fprintf('reduce %d centers covered by connected component of upper level centers:\n', sum(removeTF));
    else
        removeTF = [];
    end
    
    
    c = reshape([c.Centroid], 2,length(c))';
    c = round(c);
    c = max(1, c);
    c(:,1) = min(size(vote,2), c(:,1));
    c(:,2) = min(size(vote,1), c(:,2));
    
    c = [peaks; c];
    dist_length = 0;
    
    
    
    %     while true %merge by distance metric
    %
    %         D = pdist(c,'euclidean');
    %         if all(D>minD)
    %             break;
    %         end
    %
    %         D = squareform(D);
    %         mergeTF = (D<=minD) ;
    %
    %         diagInd = ((1:size(D,1))-1)*size(D,1)+(1:size(D,1));
    %         mergeTF(diagInd) = false; %diagonal entries of D == 0, thus needs to be set to false mannually
    %
    %
    %         TF = false(1,size(D,2));
    %         for j = 1:size(D,1)-1
    %
    %             lineTF = [false(1, j) mergeTF(j, j+1:end)];
    %             if any(TF&lineTF)
    %                continue;
    %             end
    %
    %             TF = TF | lineTF;
    %         end
    %         c(TF',:) = [];
    %         fprintf('reduce %d centers by distance metric: minD=%d\n', sum(TF), minD);
    %         dist_length = dist_length + sum(TF);
    %
    %         %imshow(dif,[]); hold on;
    %         %scatter(c(:,1), c(:,2), 100, 'g+');
    %     end
    
    
    while true %merge by distance metric
        
        D = pdist(c,'euclidean');
        if all(D>minD)
            break;
        end
        
        D = squareform(D);
        
        diagInd = ((1:size(D,1))-1)*size(D,1)+(1:size(D,1));
        D(diagInd) = Inf;
        mergeTF = D<=minD;
        
        accuD = Inf(size(D,1)-1, 1);
        for j = 1:size(D,1)-1
            lineMergeTF = [false(1, j) mergeTF(j, j+1:end)];
            
            if sum(lineMergeTF) ~= 0
                accuD(j) = sum(D(j,lineMergeTF));
            end
        end
        
        [~, minInd] = min(accuD);
        
        minLineMergeTF = [false(1, minInd-1) true mergeTF(minInd, minInd+1:end)];
        cluster_c = round(mean(c(minLineMergeTF',:),1));
        temp = c(minLineMergeTF',:);
        c(minInd,:) = cluster_c;
        remainingMergeTF = [false(1, minInd)  mergeTF(minInd, minInd+1:end)];
        c(remainingMergeTF',:) = [];
        
        %fprintf('cluster %d adjacent points by distance metric: minD=%d\n', sum(minLineMergeTF), minD);
        dist_length = dist_length + sum(minLineMergeTF)-1;
        
        %imshow(vote,[]); hold on;
        %scatter(c(:,1), c(:,2), 100, 'r+');
        %scatter(temp(:,1),temp(:,2), 150, 'g*');
        
    end
    
    
    orig_length = size(peaks,1);
    peaks = c;
    fprintf(['After voting threshold %d: '...
        '%d(original)+%d(new candidate)-%d(connection)-%d(distance)=%d\n\n'],...
        v(i), orig_length, cand_length, sum(removeTF), dist_length, size(peaks,1));
    if (orig_length+cand_length-sum(removeTF)-dist_length)~=size(peaks,1)
        error('center number does not match: orig_length+cand_length-sum(removeTF)-dist_length=%d; size(peaks)=%d',...
            orig_length+cand_length-sum(removeTF)-dist_length, size(peaks,1) );
    end
    
    %imshow(I,[]);hold on;scatter(peaks(:,1), peaks(:,2), 100, 'g+');
    
end

%figure; imshow(I,[]);hold on;scatter(peaks(:,1), peaks(:,2), 100, 'g+');
peaks_stage1 = peaks;

fprintf('----------------------------------------------------------------\n\n');

fprintf('Stage 2: Merge peaks with distance and canny edge constraints...\n');
minD = 25;
canny_dist_length = 0;
while true %merge by distance metric and canny edge points
    
    D = pdist(peaks,'euclidean');
    edgeTF = pedge(peaks, edge_canny, D, minD);
    
    if all((D>minD) | edgeTF)
        break;
    end
    
    D = squareform(D);
    edgeTF = squareform(edgeTF);
    
    diagInd = ((1:size(D,1))-1)*size(D,1)+(1:size(D,1));
    D(diagInd) = Inf;
    mergeTF = D<=minD;
    
    edgeTF(diagInd) = false;
    
    accuD = Inf(size(D,1)-1, 1);
    for j = 1:size(D,1)-1
        lineMergeTF = [false(1, j) mergeTF(j, j+1:end)];
        lineEdgeTF =  [false(1, j)  edgeTF(j, j+1:end)];
        
        if sum(lineMergeTF & ~lineEdgeTF) ~= 0
            accuD(j) = sum(D(j, lineMergeTF & ~lineEdgeTF));
        end
    end
    
    %edgeTF = edgeTF | edgeTF';
    
    [~, minInd] = min(accuD);
    minLineMergeTF = [false(1, minInd-1) true (mergeTF(minInd, minInd+1:end) & ~edgeTF(minInd,minInd+1:end))];
    
    cluster_peak = round(mean(peaks(minLineMergeTF',:),1));
    temp = peaks(minLineMergeTF',:);
    peaks(minInd,:) = cluster_peak;
    remainingMergeTF = [false(1, minInd)  (mergeTF(minInd, minInd+1:end) & ~edgeTF(minInd,minInd+1:end))];
    peaks(remainingMergeTF',:) = [];
    
    %fprintf('cluster %d adjacent points by distance metric: minD=%d and canny edge\n', sum(minLineMergeTF), minD);
    canny_dist_length = canny_dist_length + sum(minLineMergeTF)-1;
    
    %imshow(edge_canny,[]); hold on;
    %scatter(peaks(:,1), peaks(:,2), 100, 'r+');
    %scatter(temp(:,1),temp(:,2), 150, 'g*');
    
end

fprintf('%d(original)-%d(distance)=%d(final)\n', size(peaks,1), canny_dist_length, size(peaks,1)-canny_dist_length);
    

stage1TF = true(size(peaks,1),1);
for i = 1:size(peaks,1)
    xTF = (peaks_stage1(:,1) == peaks(i,1));
    if sum(xTF) == 0
        stage1TF(i) = false;
        continue;
    end
    
    yTF = (peaks_stage1(xTF,2) == peaks(i,2));
    
    if sum(yTF) == 0.
        stage1TF(i) = false;
    end
    
end
% figure;imshow(I,[]);
% title('Original image', 'FontSize', 24);
% figure;imshow(I,[]);hold on;scatter(peaks(stage1TF,1), peaks(stage1TF,2), 100, 'c+');
% scatter(peaks(~stage1TF,1), peaks(~stage1TF,2), 200, 'co');    
% scatter(peaks(~stage1TF,1), peaks(~stage1TF,2), 100, 'c+');    
% title('Seed', 'FontSize', 24);


% r=I(:,:,1);g=I(:,:,2);b=I(:,:,3);
% r(edge_canny) = 0;g(edge_canny) = 100;b(edge_canny) = 0;
% II = cat(3,r,g,b);
% figure; imshow(II,[]); hold on;
% scatter(peaks(:,1), peaks(:,2), 100, 'c+');


% r=I(:,:,1);
% g=I(:,:,2);
% b=I(:,:,3);
% g(otsuBW)=150;
% figure; h=imshow(cat(3,r,g,b),[]);hold on;scatter(peaks(:,1), peaks(:,2), 100, 'g+');

% save(['E:\Research\Code\sparse shape prior\data\seed_detection_result\' outputFileName '.mat'], 'peaks');
% imwrite(I,['E:\Research\Code\sparse shape prior\data\seed_detection_result\' outputFileName],'tif');
% print('-dtiff','-r200',['E:\Research\Code\sparse shape prior\data\seed_detection_result\' outputFileName '.tif']); 
%saveas(gcf, ['/Users/kongj/Glioma/3DPseudoCells/temp_data/' outputFileName '.tif']);

%keyboard;


end


