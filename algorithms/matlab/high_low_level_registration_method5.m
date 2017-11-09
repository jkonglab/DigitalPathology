function output = high_low_level_registration_method5(inputdir, outputdir, x_point, y_point, width, height)

%Inputs:
%inputdir: (string) Path to the folder where the input .ndpis are kept
%outputdir: (string) Path to the folder where the output .tifs will be
%saved
%x_point: (int) pixel x coordinate of the analysis patch's top left corner
%(measured from top left corner of image)
%y_point: (int) pixel y coordinate of the analysis patch's top left corner
%(measured from top left corner of image)
%width: (int) pixel width of the size of the patch
%height: (int) pixel width of the size of the path
%

%Output:
%output: 1 (true), Images will be saved to outputdir

code_dir = './Bspline/';
addpath(genpath(code_dir));

if exist('./openSlide_c.mexmaci64','file')~=3 && exist('./openSlide_c.mexa64','file')~=3
   mex -I/usr/local/include/openslide/ -L/usr/local/lib -lopenslide openSlide_c.cpp
end

lowResLevel = 8;
highResLevel = 0;

BSplineFile = sprintf('./openslide_Bspline_L%02d_transforms_Space32_color.mat', lowResLevel);
RigidFile = sprintf('./openSlide_Landmark_L%02d_transforms.mat', lowResLevel);
RigRegdir = sprintf('./openSlide_global_surf_Landmark_L%02d/', lowResLevel);
svsdir = inputdir;

if ~exist(outputdir, 'dir')
    mkdir(outputdir);
end

inputNDPIs = dir([svsdir '*.ndpi']);
inputNDPIs = {inputNDPIs.name}';

load(RigidFile, 'tmatrices');
load(BSplineFile, 'mytform', 'space', 'channel');

nIms = length(mytform);
refIdx = floor(nIms/2);

ScaleFactor = 2^(lowResLevel-highResLevel);

type = 2;
[colNUM, rowNUM] = openSlide_c([svsdir inputNDPIs{refIdx}], highResLevel, type);

%coordinate system of level 0 svs image, staring at (x=col=0, y=row=0)
x = 28000; width =  4*1024;  % (x,y) use level 0 coodinate system; 
y = 34000; height = 4*1024; % (width, height) use coordinate system associated with highResLevel

%generate reference image
type = 1;
reference = openSlide_c([svsdir inputNDPIs{refIdx}], int64(x), int64(y), int64(width), int64(height), highResLevel, type);
imshow(reference,[]);
imwrite(reference, sprintf('%sreg_slide_%02d.jpg',outputdir, refIdx), 'Mode', 'lossy', 'Quality', 25);

x_highResLevel = round(x/(2^highResLevel));
y_highResLevel = round(y/(2^highResLevel));

[x0,y0] = meshgrid( (x_highResLevel+1):(x_highResLevel+1+width-1), (y_highResLevel+1):(y_highResLevel+1+height-1) ); %matlab image coordinate system

outbound_TF = false(numel(x0),1);

for i = (refIdx-1):-1:1
    manual_registeredIm = uint8(zeros(size(reference)));
    
    bmatrix = mytform{i};
    mode = 3;
    lowLevelRigRegImage = imread([RigRegdir sprintf('reg_slide_%02d.tif', i+1)]);
    [~,low_Trow,low_Tcol]=bspline_transform_2d_double(double(bmatrix(:,:,1)),double(bmatrix(:,:,2)),lowLevelRigRegImage,double(space),double(space),double(mode));
    
    high_Trow = ScaleFactor*interp2(low_Trow, (x0-1)/ScaleFactor+1, (y0-1)/ScaleFactor+1, 'linear', 0);  %scaling in svs image coordiate system; interpolation in matlab image coordinate system
    high_Tcol = ScaleFactor*interp2(low_Tcol, (x0-1)/ScaleFactor+1, (y0-1)/ScaleFactor+1, 'linear', 0);
    
    %if just rigid
    %high_Tcol = 0; high_Trow = 0;
    
    %method 5
    x1 = x0 +  high_Tcol;
    y1 = y0 +  high_Trow;
    
    x_output = x1(:);
    y_output = y1(:);
    for j = (refIdx-1):-1:i
        tmatrix = affine2d();
        tmatrix.T = tmatrices{j}.T;
        invT = invert(tmatrix); invT = invT.T;
        
        R = tmatrix.T(1:2,1:2)';
        s = norm(R);
        R = R/s;
        shift = tmatrix.T(3,1:2);
        myinvT = [ [R/s [0;0]]; [-1/s*shift*R 1] ];
        
        if sum(abs(myinvT(:)-invT(:))) > 1e-4
            fprintf('\n\nNOTE:slide %02d: Numerical invT is not close to analyical invT. Error:%f\n\n', i, sum(abs(myinvT(:)-invT(:))) );
        end
        
        invT(3,1:2) = invT(3,1:2) * ScaleFactor;
        
        mapped = [x_output, y_output, ones(numel(x_output),1)] *invT;
        x_output = mapped(:,1);
        y_output = mapped(:,2);
        clear mapped
    end
    
    x0 = x1;
    y0 = y1;
    
    type = 2;
    [colNUM, rowNUM] = openSlide_c([svsdir inputNDPIs{i}], highResLevel, type);
    
    outbound_TF = outbound_TF | x_output < (1-0.5) | y_output < (1-0.5) |...   %check out of bound in matlab image coordinate system
        x_output > (colNUM+0.5) | y_output > (rowNUM+0.5);
    
    x_output = x_output - 1; %back to svs image coordinate system
    y_output = y_output - 1;
    
    
    maxX = ceil(max(x_output)); minX = floor(min(x_output));
    maxY = ceil(max(y_output)); minY = floor(min(y_output));
    
    minX_level0 = floor(minX*(2^highResLevel));
    minY_level0 = floor(minY*(2^highResLevel));
    
    type = 1;
    unregisterROI = openSlide_c([svsdir inputNDPIs{i}], int64(minX_level0), int64(minY_level0), int64(maxX-minX+1), int64(maxY-minY+1), highResLevel, type);
    [ux, uy] = meshgrid(minX:maxX, minY:maxY);
    
    interp_r = interp2(ux, uy, single(unregisterROI(:,:,1)), x_output(~outbound_TF), y_output(~outbound_TF), 'linear');
    interp_g = interp2(ux, uy, single(unregisterROI(:,:,2)), x_output(~outbound_TF), y_output(~outbound_TF), 'linear');
    interp_b = interp2(ux, uy, single(unregisterROI(:,:,3)), x_output(~outbound_TF), y_output(~outbound_TF), 'linear');
    
    r = manual_registeredIm(:,:,1); r(~outbound_TF) = interp_r;
    g = manual_registeredIm(:,:,2); g(~outbound_TF) = interp_g;
    b = manual_registeredIm(:,:,3); b(~outbound_TF) = interp_b;
    manual_registeredIm = cat(3, r,g,b);
    
    imshow(manual_registeredIm,[]);
    imwrite(manual_registeredIm, sprintf('%sreg_slide_%02d.tif',outputdir, i));
    %imwrite(manual_registeredIm, sprintf('%sreg_slide_%02d.jpg',outputdir, i),  'Mode', 'lossy', 'Quality', 25);
    
end

[x0,y0] = meshgrid( (x_highResLevel+1):(x_highResLevel+1+width-1), (y_highResLevel+1):(y_highResLevel+1+height-1) ); %matlab image coordinate system
outbound_TF = false(numel(x0),1);    

for i = (refIdx+1):1:nIms
    manual_registeredIm = uint8(zeros(size(reference)));
    
    bmatrix = mytform{i};
    
    mode = 3;
    lowLevelRigRegImage = imread([RigRegdir sprintf('reg_slide_%02d.tif', i-1)]);
    [~,low_Trow,low_Tcol]=bspline_transform_2d_double(double(bmatrix(:,:,1)),double(bmatrix(:,:,2)),lowLevelRigRegImage,double(space),double(space),double(mode));
    
    
    high_Trow = ScaleFactor*interp2(low_Trow, (x0-1)/ScaleFactor+1, (y0-1)/ScaleFactor+1, 'linear', 0);  %scaling in svs image coordiate system; interpolation in matlab image coordinate system
    high_Tcol = ScaleFactor*interp2(low_Tcol, (x0-1)/ScaleFactor+1, (y0-1)/ScaleFactor+1, 'linear', 0);
    
    %if just rigid
    %high_Tcol = 0; high_Trow = 0;
    
    x1 = x0 +  high_Tcol;
    y1 = y0 +  high_Trow;
    
    x_output = x1(:);
    y_output = y1(:);
    for j = refIdx:(i-1)
        invT = tmatrices{j}.T;
        invT(3,1:2) = invT(3,1:2) * ScaleFactor;
        
        mapped = [x_output, y_output, ones(numel(x1),1)] *invT;
        x_output = mapped(:,1);
        y_output = mapped(:,2);
        clear mapped
    end
    
    x0 = x1;
    y0 = y1;
    
    type = 2;
    [colNUM, rowNUM] = openSlide_c([svsdir inputNDPIs{i}], highResLevel, type);
    
    outbound_TF = outbound_TF | x_output < (1-0.5) | y_output < (1-0.5) |...   %check out of bound in matlab image coordinate system
        x_output > (colNUM+0.5) | y_output > (rowNUM+0.5);
    
    x_output = x_output - 1; %back to svs image coordinate system
    y_output = y_output - 1;
    
    maxX = ceil(max(x_output)); minX = floor(min(x_output));
    maxY = ceil(max(y_output)); minY = floor(min(y_output));
    
    minX_level0 = floor(minX*(2^highResLevel));
    minY_level0 = floor(minY*(2^highResLevel));
    
    type = 1;
    unregisterROI = openSlide_c([svsdir inputNDPIs{i}], int64(minX_level0), int64(minY_level0), int64(maxX-minX+1), int64(maxY-minY+1), highResLevel, type);
    [ux, uy] = meshgrid(minX:maxX, minY:maxY);
    
    interp_r = interp2(ux, uy, single(unregisterROI(:,:,1)), x_output(~outbound_TF), y_output(~outbound_TF), 'linear');
    interp_g = interp2(ux, uy, single(unregisterROI(:,:,2)), x_output(~outbound_TF), y_output(~outbound_TF), 'linear');
    interp_b = interp2(ux, uy, single(unregisterROI(:,:,3)), x_output(~outbound_TF), y_output(~outbound_TF), 'linear');
    
    r = manual_registeredIm(:,:,1); r(~outbound_TF) = interp_r;
    g = manual_registeredIm(:,:,2); g(~outbound_TF) = interp_g;
    b = manual_registeredIm(:,:,3); b(~outbound_TF) = interp_b;
    manual_registeredIm = cat(3, r,g,b);
    
    imshow(manual_registeredIm,[]);
    imwrite(manual_registeredIm, sprintf('%sreg_slide_%02d.tif',outputdir, i));
    %imwrite(manual_registeredIm, sprintf('%sreg_slide_%02d.jpg',outputdir, i),  'Mode', 'lossy', 'Quality', 25);
    
end

output = 1;

%add label to image
% jpgFiles = dir([outputdir '*.jpg']);
% jpgFiles = {jpgFiles.name}.';
% for i = 1:length(jpgFiles)
%    %convert reg_slide_01.jpg -gravity northeast -pointsize 60 -fill green -annotate +100+0 'Slide 01' reg_slide_01.jpg
%    cmd = sprintf('/usr/local/bin/convert %s%s -gravity northeast -pointsize 60 -fill green -annotate +100+0 ''Slide %02d'' %s%s', outputdir, jpgFiles{i}, i, outputdir, jpgFiles{i});
%    system(cmd);
% end

% cmd = sprintf('/usr/local/bin/convert -delay 80 -loop 0 -layers OptimizeFrame %s*.jpg %sgif.gif', outputdir, outputdir);
% system(cmd);
% 
% cmd = sprintf('/usr/local/bin/convert %sgif.gif -resize 512x512 \\> %ssmall.gif', outputdir, outputdir); 
% system(cmd);
% 
% cmd = sprintf('/usr/local/bin/montage %s*.jpg -tile 8x %smontage.png', outputdir, outputdir);
% system(cmd);
