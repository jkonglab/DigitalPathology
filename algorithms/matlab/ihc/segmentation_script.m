clear all; close all; clc;

if exist('../stainImages.mat', 'file') == 0;
    %find images to be analyzed
    inputFileName = dir('../../../../Seed_Grountruth_GBM40/*.tif');
    inputFileName = {inputFileName.name};
    k = strfind(inputFileName, '.');
    imageNumber = cellfun(@(x,y) str2double(y(1:x(1)-1)), k, inputFileName);
    [~, ind] = sort(imageNumber);
    inputFileName = inputFileName(ind);
    
    %take the first one
    i = 1;
    I=imread(['../../../../Seed_Grountruth_GBM40/' inputFileName{i}]);
    
    
    %define OD matrix; each column is associated with one stain (i.e. Hematoxylin, DAB, and red_marker)
    %        Hemat  DAB  red_marker
    stains =[0.650 0.368 0.103;...   %Red
        0.704 0.570 0.696;...   %Green
        0.286 0.731 0.711];     %Blue
    
    %calculate stain intensities using color deconvolution
    %Deconvolved = ColorDeconvolution(I, stains, [true true true]);
    [Deconvolved, colorImage] = ColorDeconvolution_FullNewVer(I, stains, [true true true]);
    
    % Hematoxylin = Deconvolved(:,:,1);
    DAB = Deconvolved(:,:,2);
    % RedMarker = Deconvolved(:,:,3);
    
    %     figure; imshow(I,[]);
    %     figure; imshow(Hematoxylin,[]);  %Hematoxylin intensity image for cells
    %     figure; imshow(DAB,[]);          %DAB intensity image for vessels
    %     figure; imshow(RedMarker,[]);    %red_marker intensity image for bile ducts
    %
    %     figure; imshow(colorImage{1},[]); %color image for Hematoxylin
    %     figure; imshow(colorImage{2},[]); %color image for DAB
    %     figure; imshow(colorImage{3},[]); %%color image for red_marker
    %
    %     imwrite(colorImage{1}, './temp/Hem.tiff');
    %     imwrite(colorImage{2}, './temp/DAB.tiff');
    %     imwrite(colorImage{3}, './temp/Red.tiff');
    
    %save as mat file
    save('../stainImages.mat', 'I', 'Hematoxylin', 'DAB', 'RedMarker', 'colorImage');
else
    
    %load mat file
    load('../stainImages.mat', 'I', 'Hematoxylin', 'DAB', 'RedMarker');
    
    %process fats in white and circular shape
    G = 225; areaThr = [150 2000]; areaMid = 800; eccThr = [0.8 0.9];
    bwFatMask = (I(:,:,1)>G & I(:,:,2)>G & I(:,:,3)>G);
    bwFatMask = imfill(bwFatMask, 'holes');
    bwFatMask = imopen(bwFatMask, strel('disk',5));
    [L] = bwlabel(bwFatMask, 4);
    stats = regionprops(L, 'Area','Eccentricity');
    areas = [stats.Area];
    ecces = [stats.Eccentricity];
    
    TF = false(length(areas),1);
    largeObjectTF = (areas >= areaMid);
    TF(~largeObjectTF) = (areas(~largeObjectTF)>areaThr(1) &  ecces(~largeObjectTF)<=eccThr(1) );
    TF( largeObjectTF) = (areas( largeObjectTF)<areaThr(2) &  ecces( largeObjectTF)<=eccThr(2) );
    ind = find(TF);
    
    bwFatMask = ismember(L, ind);
    
    %     red = I(:,:,1);
    %     red(bwFatMask==1)=0;
    %     green = I(:,:,2);
    %     green(bwFatMask==1)=0;
    %     blue = I(:,:,3);
    %     blue(bwFatMask==1)=0;
    %     imwrite(cat(3, red, green, blue), './tiles/0.0.1.fat.tif');
    
    
    %process DAB markers for vessels
    G1=80; G2=50; diskSize = 10; areaThr = [70 Inf]; SEPARATION = false; SMOOTH = false;
    bwVesselMask = segmentObject(DAB, G1, G2, diskSize, areaThr, SEPARATION, SMOOTH);
    
    %     red = I(:,:,1);
    %     red(dilateVesselMask==1)=0;
    %     green = I(:,:,2);
    %     green(dilateVesselMask==1)=0;
    %     blue = I(:,:,3);
    %     blue(dilateVesselMask==1)=0;
    %     imwrite(cat(3, red, green, blue), './tiles/0.0.1.dilatedVessel.tif');
    
    
    seVessel = strel('disk',11);
    dilateVesselMask = imclose(bwVesselMask, seVessel);
    dilateVesselMask = imfill(dilateVesselMask, 'holes');
    
    lumenAreaThr = [5000 100000];
    ind = find(areas>lumenAreaThr(1) & areas<lumenAreaThr(2));
    
    lumenPerThr = 0.30;
    seLumen = strel('disk',9);
    lumenTF = false(1,length(ind));
    for i = 1:length(ind)
        bw = (L == ind(i));
        dilateBW = imdilate(bw, seLumen);
        ringBW = (dilateBW & ~bw);
        vesselPercent = sum(bwVesselMask(ringBW))/sum(ringBW(:));
        if vesselPercent >lumenPerThr
            lumenTF(i) = true;
        end
        
    end
    lumenMask = ismember(L, ind(lumenTF));
    
    
    bwVesselLumenMask = (dilateVesselMask | imdilate(lumenMask, seLumen));
    
    red = I(:,:,1); green = I(:,:,2); blue = I(:,:,3);
    B = bwboundaries(bwVesselLumenMask,8,'noholes');
    for i = 1:length(B)
        b = B{i};
        
        if size(b,1) > 15
            smooth = [];
            smooth(:,1) = round(lowB(b(:,1)));
            smooth(:,2) = round(lowB(b(:,2)));
            
            if any(smooth(:)<0 | smooth(:)>size(I,1))
                smooth = b;
            end
        else
            smooth = b;
        end
        
        
        bInd = sub2ind( size(red), smooth(:,1)', smooth(:,2)');
        red(bInd)=0;
        greem(bInd)=255;
        blue(bInd) = 0;
        
    end
    
    imwrite(cat(3, red, green, blue), '../0.0.1.vessel.tif');
    
    
    
    %
    %     colorVesselMask = uint8(255*ones([size(bwVesselMask), 3]));
    %     tempChannel = uint8(255*ones(size(bwVesselMask)));
    %     tempChannel(bwVesselMask==1) = 0;
    %     colorVesselMask(:,:,1) = tempChannel;
    %     colorVesselMask(:,:,3) = tempChannel;
    %
    %     red = I(:,:,1);
    %     red(bwVesselMask==1)=0;
    %     green = I(:,:,2);
    %     green(bwVesselMask==1)=255;
    %     blue = I(:,:,3);
    %     blue(bwVesselMask==1)=0;
    %     imwrite(cat(3, red, green, blue), './temp/vessel_Smooth.tif');
    
    
    %process red markers for bile ducts
    G1=100; G2=50; diskSize = 10; areaThr = [15 Inf]; SEPARATION = false; SMOOTH = false;
    bwBileMask = segmentObject(RedMarker, G1, G2, diskSize, areaThr, SEPARATION, SMOOTH);
    %
    %     colorBileMask = uint8(255*ones([size(bwBileMask), 3]));
    %     tempChannel = uint8(255*ones(size(bwBileMask)));
    %     tempChannel(bwBileMask==1) = 0;
    %     colorBileMask(:,:,1) = tempChannel;
    %     colorBileMask(:,:,3) = tempChannel;
    %
    %     red = I(:,:,1);
    %     red(bwBileMask==1)=0;
    %     green = I(:,:,2);
    %     green(bwBileMask==1)=255;
    %     blue = I(:,:,3);
    %     blue(bwBileMask==1)=0;
    %     imwrite(cat(3, red, green, blue), './temp/bile_Smooth.tif');
    
    
    %process Hematoxylin markers for cells
    G1=80; G2=40; diskSize = 10; areaThr = [5 250]; SEPARATION = false; SMOOTH = false;
    bwCellMask = segmentObject(Hematoxylin, G1, G2, diskSize, areaThr, SEPARATION, SMOOTH);
    
    %remove any 'cells' masked by bwBilMask | bwVesselMask
    L = bwlabel(bwCellMask, 4);
    bwNonCellMask = (bwBileMask | bwVesselMask);
    nonCellL = unique(L(bwNonCellMask & bwCellMask));
    bwCellMask = bwCellMask & (~ismember(L, nonCellL));
    
    
    colorCellMask = uint8(255*ones([size(bwCellMask), 3]));
    tempChannel = uint8(255*ones(size(bwCellMask)));
    tempChannel(bwCellMask==1) = 0;
    colorCellMask(:,:,1) = tempChannel;
    colorCellMask(:,:,3) = tempChannel;
    
    
    %     imshow(I,[]);
    %     hold on;
    %     h=imshow(colorCellMask,[]);
    %     set(h,'AlphaData', 0.3);
    
    red = I(:,:,1);
    red(bwCellMask==1)=0;
    green = I(:,:,2);
    green(bwCellMask==1)=255;
    blue = I(:,:,3);
    blue(bwCellMask==1)=0;
    %   imwrite(cat(3, red, green, blue), './temp/cell_NoSmooth.tif');
end